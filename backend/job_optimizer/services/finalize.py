import re
from copy import deepcopy

from django.db import transaction
from django.utils import timezone
from rest_framework.exceptions import ValidationError

from resume.models import ResumeVersion
from resume.services import ResumeValidationService
from .matcher import RequirementMatcher
from .suggestions import get_path, set_path
from job_optimizer.models import OptimizationSession, OptimizationSuggestion


# ---------------------------------------------------------------------------
# Inlined ATS scoring utilities (previously in resume_analyzer package).
# These are pure-computation helpers with no DB or API dependencies.
# ---------------------------------------------------------------------------

_EMAIL_PATTERN = re.compile(r"^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$")
_PHONE_PATTERN = re.compile(r"^(\+?[0-9][0-9\-\s]{7,14}[0-9])$")
_URL_PATTERN = re.compile(r"^https?://")


def _validate_contact(personal_info: dict) -> list[str]:
    """Check personal-info fields for completeness (inlined from ContactValidator)."""
    issues = []

    email = str(personal_info.get("email", "")).strip()
    phone = str(personal_info.get("phone", "")).strip()
    linkedin = str(personal_info.get("linkedin_url") or personal_info.get("linkedin", "")).strip()
    github = str(personal_info.get("github_url") or personal_info.get("github", "")).strip()

    if not email:
        issues.append("Email is missing.")
    elif not _EMAIL_PATTERN.match(email):
        issues.append("Email format appears invalid.")

    if not phone:
        issues.append("Phone number is missing.")
    elif not _PHONE_PATTERN.match(phone):
        issues.append("Phone number format appears invalid.")

    if not linkedin:
        issues.append("LinkedIn profile is missing.")
    elif not _URL_PATTERN.match(linkedin):
        issues.append("LinkedIn URL should start with http:// or https://.")

    if not github:
        issues.append("GitHub profile is missing.")
    elif not _URL_PATTERN.match(github):
        issues.append("GitHub URL should start with http:// or https://.")

    return issues


_LONG_PARAGRAPH_WORD_LIMIT = 120


def _analyze_format(raw_text: str, structured_data: dict) -> list[str]:
    """Detect formatting issues (inlined from ResumeFormatAnalyzer)."""
    issues = []
    text = raw_text or ""

    bullet_prefixes = ("-", "*", "•")
    lines = [line.strip() for line in text.splitlines() if line.strip()]

    if lines and not any(line.startswith(bullet_prefixes) for line in lines):
        issues.append("No bullet points detected; use bullets for achievements and responsibilities.")

    paragraphs = [p.strip() for p in re.split(r"\n\s*\n", text) if p.strip()]
    long_paragraphs = [p for p in paragraphs if len(p.split()) > _LONG_PARAGRAPH_WORD_LIMIT]
    if long_paragraphs:
        issues.append("Long paragraphs detected; break them into concise bullets.")

    used_styles = set()
    for line in lines:
        if line.startswith("-"):
            used_styles.add("-")
        elif line.startswith("*"):
            used_styles.add("*")
        elif line.startswith("•"):
            used_styles.add("•")
    if len(used_styles) > 1:
        issues.append("Inconsistent bullet formatting detected; use a single bullet style.")

    experience = structured_data.get("experience") or []
    if isinstance(experience, list) and experience:
        weak_entries = 0
        for item in experience:
            responsibilities = item.get("responsibilities") if isinstance(item, dict) else []
            if not responsibilities:
                weak_entries += 1
        if weak_entries:
            issues.append("Some experience entries do not include responsibilities or impact bullets.")

    return issues


_ATS_WEIGHTS = {
    "keyword_match": 40,
    "section_completeness": 20,
    "formatting": 15,
    "content_quality": 15,
    "contact_info": 10,
}


def _ats_score_sections(missing_sections: list[str]) -> int:
    total = 4
    missing = len(missing_sections)
    return int(((total - min(total, missing)) / total) * 100)


def _ats_score_format(format_issues: list[str]) -> int:
    if not format_issues:
        return 100
    deduction = min(60, len(format_issues) * 20)
    return max(0, 100 - deduction)


def _ats_score_contact(contact_issues: list[str]) -> int:
    if not contact_issues:
        return 100
    deduction = min(80, len(contact_issues) * 20)
    return max(0, 100 - deduction)


def _ats_score_content_quality(structured_data: dict) -> int:
    score = 0

    summary = str((structured_data.get("personal_info") or {}).get("summary", "")).strip()
    if len(summary.split()) >= 30:
        score += 30
    elif summary:
        score += 15

    experience = structured_data.get("experience") or []
    with_bullets = 0
    for entry in experience:
        if isinstance(entry, dict) and entry.get("responsibilities"):
            with_bullets += 1
    if experience:
        ratio = with_bullets / len(experience)
        score += int(ratio * 40)

    projects = structured_data.get("projects") or []
    if projects:
        score += 15

    education = structured_data.get("education") or []
    if education:
        score += 15

    return max(0, min(100, score))


def _calculate_ats(
    keyword_match_percentage: int,
    missing_sections: list[str],
    format_issues: list[str],
    contact_issues: list[str],
    structured_data: dict,
) -> dict:
    """Compute ATS score and breakdown (inlined from ATSScoringEngine)."""
    section_score = _ats_score_sections(missing_sections)
    format_score = _ats_score_format(format_issues)
    contact_score = _ats_score_contact(contact_issues)
    content_quality_score = _ats_score_content_quality(structured_data)

    weighted = (
        keyword_match_percentage * _ATS_WEIGHTS["keyword_match"]
        + section_score * _ATS_WEIGHTS["section_completeness"]
        + format_score * _ATS_WEIGHTS["formatting"]
        + content_quality_score * _ATS_WEIGHTS["content_quality"]
        + contact_score * _ATS_WEIGHTS["contact_info"]
    ) / 100

    final_score = int(round(weighted))

    return {
        "ats_score": max(0, min(100, final_score)),
        "breakdown": {
            "keyword_match": keyword_match_percentage,
            "section_completeness": section_score,
            "formatting": format_score,
            "content_quality": content_quality_score,
            "contact_info": contact_score,
        },
    }


def _missing_sections(structured_data: dict) -> list[str]:
    """Detect which recommended resume sections are absent."""
    personal_info = structured_data.get("personal_info") or {}
    section_presence = {
        "skills": bool(structured_data.get("skills")),
        "experience": bool(structured_data.get("experience")),
        "projects": bool(structured_data.get("projects")),
        "summary": bool(str(personal_info.get("summary", "")).strip()),
    }
    return [section for section, present in section_presence.items() if not present]


def _resume_text_from_structured(structured_data: dict) -> str:
    """Build a plain-text representation of structured resume data."""
    lines = []

    personal_info = structured_data.get("personal_info") or {}
    lines.extend(str(value) for value in personal_info.values() if value)

    for skill in structured_data.get("skills") or []:
        lines.append(str(skill))

    for exp in structured_data.get("experience") or []:
        if isinstance(exp, dict):
            lines.append(str(exp.get("job_title", "")))
            lines.extend(str(item) for item in exp.get("responsibilities") or [])

    for project in structured_data.get("projects") or []:
        if isinstance(project, dict):
            lines.append(str(project.get("title", "")))
            lines.extend(str(item) for item in project.get("bullets") or [])

    return "\n".join(item for item in lines if str(item).strip())


# ---------------------------------------------------------------------------
# Optimization finalization service
# ---------------------------------------------------------------------------

class ResumeOptimizationService:
    @staticmethod
    def ats_analysis(resume_data, alignment_score):
        structured = ResumeValidationService.normalize_resume_data(resume_data)
        text = _resume_text_from_structured(structured)
        missing = _missing_sections(structured)
        return _calculate_ats(
            keyword_match_percentage=alignment_score,
            missing_sections=missing,
            format_issues=_analyze_format(raw_text=text, structured_data=structured),
            contact_issues=_validate_contact(structured.get("personal_info") or {}),
            structured_data=structured,
        )

    @staticmethod
    @transaction.atomic
    def finalize(session, name="", *, idempotency_key="", expected_source_version=None):
        session = OptimizationSession.objects.select_for_update().select_related(
            "source_resume", "job_description"
        ).get(pk=session.pk)
        if session.status == OptimizationSession.Status.COMPLETED:
            if idempotency_key and session.apply_idempotency_key and idempotency_key != session.apply_idempotency_key:
                raise ValidationError({
                    "code": "optimization_already_applied",
                    "message": "This optimization session has already been applied.",
                })
            return session.optimized_version
        if session.status != OptimizationSession.Status.READY_FOR_REVIEW:
            raise ValidationError("Session must be matched before finalization.")
        if session.source_resume.user_id != session.user_id or session.job_description.user_id != session.user_id:
            raise ValidationError("Session ownership is invalid.")
        if expected_source_version is not None and expected_source_version != session.source_resume_version:
            raise ValidationError({
                "code": "source_resume_changed",
                "message": "This resume was edited after the analysis. Run the optimizer again.",
            })
        source = session.source_data_snapshot
        if not isinstance(source, dict) or not source:
            raise ValidationError("This session has no saved source resume snapshot. Start a new analysis.")
        if session.source_resume.revision != session.source_resume_version or session.source_resume.data != source or (
            session.source_resume_updated_at
            and session.source_resume.updated_at != session.source_resume_updated_at
        ):
            session.suggestions.exclude(status=OptimizationSuggestion.Status.REJECTED).update(
                status=OptimizationSuggestion.Status.STALE
            )
            raise ValidationError({
                "code": "source_resume_changed",
                "message": "This resume was edited after the analysis. Run the optimizer again.",
            })
        session.status = OptimizationSession.Status.APPLYING
        session.apply_idempotency_key = idempotency_key
        session.save(update_fields=["status", "apply_idempotency_key", "updated_at"])
        optimized = deepcopy(source)
        changed_paths = set()
        approved = session.suggestions.filter(status__in=[
            OptimizationSuggestion.Status.ACCEPTED, OptimizationSuggestion.Status.EDITED,
        ])
        for suggestion in approved:
            if suggestion.resume_path in changed_paths:
                raise ValidationError("Conflicting suggestions target the same resume field.")
            changed_paths.add(suggestion.resume_path)
            if get_path(source, suggestion.resume_path) != suggestion.original_value:
                raise ValidationError("Suggestion no longer matches the source snapshot.")
            if not isinstance(suggestion.final_value, str) or not suggestion.final_value.strip():
                raise ValidationError("Approved suggestion has no final text.")
            set_path(optimized, suggestion.resume_path, suggestion.final_value)
        if not changed_paths:
            raise ValidationError("Accept or edit at least one suggestion before finalization.")
        requirements = session.analysis_json.get("requirements", [])
        final_match = RequirementMatcher().match(requirements, optimized)
        before_score = session.match_results_json.get("summary", {}).get("alignment_score", 0)
        final_match["before_ats"] = ResumeOptimizationService.ats_analysis(source, before_score)
        final_match["after_ats"] = ResumeOptimizationService.ats_analysis(
            optimized, final_match["summary"]["alignment_score"]
        )
        title = name.strip() if name else session.job_description.title or session.source_resume.title
        if not name and session.job_description.company:
            title = f"{title} - {session.job_description.company}"
        version = ResumeVersion.objects.create(
            user=session.user, source_resume=session.source_resume,
            optimization_session=session, title=title[:255], data=optimized,
            template=session.source_resume.template,
            template_version=session.source_resume.template_version,
        )
        now = timezone.now()
        approved.update(status=OptimizationSuggestion.Status.APPLIED, applied_at=now)
        session.final_analysis_json = final_match
        session.status = OptimizationSession.Status.COMPLETED
        session.completed_at = now
        session.save(update_fields=[
            "final_analysis_json", "status", "completed_at", "apply_idempotency_key", "updated_at",
        ])
        return version
