from rest_framework.exceptions import NotFound, ValidationError

from resume.models import Resume
from resume.services import ResumeValidationService

from .ai_engine import AIImprovementEngine
from .ats_engine import ATSScoringEngine
from .contact_validator import ContactValidator
from .formatter import ResumeFormatAnalyzer
from .keyword_engine import KeywordAnalysisEngine
from .models import ResumeAnalysis
from .parser import ResumeParser
from .skill_gap_engine import SkillGapEngine


class ResumeAnalyzerService:
    REQUIRED_SECTIONS = ["skills", "experience", "projects", "summary"]

    @staticmethod
    def _missing_sections(structured_data: dict) -> list[str]:
        personal_info = structured_data.get("personal_info") or {}

        section_presence = {
            "skills": bool(structured_data.get("skills")),
            "experience": bool(structured_data.get("experience")),
            "projects": bool(structured_data.get("projects")),
            "summary": bool(str(personal_info.get("summary", "")).strip()),
        }

        return [section for section, present in section_presence.items() if not present]

    @staticmethod
    def _resume_text_from_structured(structured_data: dict) -> str:
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

    @staticmethod
    def build_analysis_payload(instance: ResumeAnalysis) -> dict:
        data = instance.analysis_data or {}
        return {
            "analysis_id": str(instance.id),
            "ats_score": instance.ats_score,
            "skill_score": instance.skill_score,
            "missing_sections": data.get("missing_sections", []),
            "missing_skills": data.get("missing_skills", {}),
            "matched_skills": data.get("matched_skills", {}),
            "keyword_analysis": data.get("keyword_analysis", {}),
            "format_issues": data.get("format_issues", []),
            "contact_issues": data.get("contact_issues", []),
            "suggestions": data.get("suggestions", []),
            "ats_breakdown": data.get("ats_breakdown", {}),
            "job_role": instance.job_role,
            "resume_id": str(instance.resume_id) if instance.resume_id else None,
            "created_at": instance.created_at,
        }

    @staticmethod
    def analyze(*, user, job_role: str, resume_id=None, uploaded_file=None) -> dict:
        job_role_cleaned = (job_role or "").strip()
        if not job_role_cleaned:
            raise ValidationError({"job_role": "job_role is required."})

        resume_obj = None
        raw_text = ""

        if resume_id:
            try:
                resume_obj = Resume.objects.select_related("template").get(id=resume_id, user=user)
            except Resume.DoesNotExist as exc:
                raise NotFound("Resume not found for this user.") from exc

            structured_data = ResumeValidationService.normalize_resume_data(resume_obj.data)
            ResumeValidationService.validate_resume_data(structured_data)
            raw_text = ResumeAnalyzerService._resume_text_from_structured(structured_data)
        elif uploaded_file:
            structured_data, raw_text = ResumeParser.parse_uploaded_pdf(uploaded_file, job_role_cleaned)
            structured_data = ResumeValidationService.normalize_resume_data(structured_data)
        else:
            raise ValidationError("Provide either resume_id or uploaded_file.")

        missing_sections = ResumeAnalyzerService._missing_sections(structured_data)
        skill_result = SkillGapEngine.evaluate(structured_data, job_role_cleaned)

        keyword_analysis = KeywordAnalysisEngine.analyze(
            structured_data=structured_data,
            raw_text=raw_text,
            job_role=job_role_cleaned,
            role_skills=skill_result.get("role_skills", {}),
        )

        format_issues = ResumeFormatAnalyzer.analyze(raw_text=raw_text, structured_data=structured_data)
        contact_issues = ContactValidator.validate(structured_data.get("personal_info") or {})

        ats_result = ATSScoringEngine.calculate(
            keyword_match_percentage=keyword_analysis.get("match_percentage", 0),
            missing_sections=missing_sections,
            format_issues=format_issues,
            contact_issues=contact_issues,
            structured_data=structured_data,
        )

        base_analysis_data = {
            "missing_sections": missing_sections,
            "missing_skills": skill_result.get("missing_skills", {}),
            "matched_skills": skill_result.get("matched_skills", {}),
            "format_issues": format_issues,
            "contact_issues": contact_issues,
            "keyword_analysis": keyword_analysis,
            "suggestions": [],
            "ats_breakdown": ats_result.get("breakdown", {}),
            "parsed_resume": structured_data,
        }

        suggestions = AIImprovementEngine.generate_suggestions(
            structured_data=structured_data,
            analysis_data=base_analysis_data,
            job_role=job_role_cleaned,
        )
        base_analysis_data["suggestions"] = suggestions

        analysis_instance = ResumeAnalysis.objects.create(
            user=user,
            resume=resume_obj,
            uploaded_file=uploaded_file if uploaded_file else None,
            job_role=job_role_cleaned,
            ats_score=ats_result["ats_score"],
            skill_score=skill_result["skill_score"],
            analysis_data=base_analysis_data,
        )

        return ResumeAnalyzerService.build_analysis_payload(analysis_instance)

    @staticmethod
    def get_analysis_or_404(*, user, analysis_id):
        try:
            return ResumeAnalysis.objects.select_related("resume", "user").get(id=analysis_id, user=user)
        except ResumeAnalysis.DoesNotExist as exc:
            raise NotFound("Analysis record not found.") from exc

    @staticmethod
    def reanalyze(*, user, analysis_id, job_role: str | None = None) -> dict:
        existing = ResumeAnalyzerService.get_analysis_or_404(user=user, analysis_id=analysis_id)
        next_job_role = (job_role or existing.job_role).strip()

        if existing.resume_id:
            return ResumeAnalyzerService.analyze(
                user=user,
                job_role=next_job_role,
                resume_id=existing.resume_id,
                uploaded_file=None,
            )

        if existing.uploaded_file:
            existing.uploaded_file.open("rb")
            try:
                return ResumeAnalyzerService.analyze(
                    user=user,
                    job_role=next_job_role,
                    resume_id=None,
                    uploaded_file=existing.uploaded_file,
                )
            finally:
                existing.uploaded_file.close()

        raise ValidationError("Unable to reanalyze: no source resume or uploaded file found.")
