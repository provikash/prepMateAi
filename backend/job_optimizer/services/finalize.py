from copy import deepcopy

from django.db import transaction
from django.utils import timezone
from rest_framework.exceptions import ValidationError

from resume.models import ResumeVersion
from resume.services import ResumeValidationService
from resume_analyzer.analysis_service import ResumeAnalyzerService
from resume_analyzer.ats_engine import ATSScoringEngine
from resume_analyzer.contact_validator import ContactValidator
from resume_analyzer.formatter import ResumeFormatAnalyzer
from .matcher import RequirementMatcher
from .suggestions import get_path, set_path
from job_optimizer.models import OptimizationSession, OptimizationSuggestion


class ResumeOptimizationService:
    @staticmethod
    def ats_analysis(resume_data, alignment_score):
        structured = ResumeValidationService.normalize_resume_data(resume_data)
        text = ResumeAnalyzerService._resume_text_from_structured(structured)
        missing = ResumeAnalyzerService._missing_sections(structured)
        return ATSScoringEngine.calculate(
            keyword_match_percentage=alignment_score,
            missing_sections=missing,
            format_issues=ResumeFormatAnalyzer.analyze(raw_text=text, structured_data=structured),
            contact_issues=ContactValidator.validate(structured.get("personal_info") or {}),
            structured_data=structured,
        )

    @staticmethod
    @transaction.atomic
    def finalize(session, name=""):
        session = OptimizationSession.objects.select_for_update().select_related(
            "source_resume", "job_description"
        ).get(pk=session.pk)
        if session.status == OptimizationSession.Status.COMPLETED:
            return session.optimized_version
        if session.status != OptimizationSession.Status.READY_FOR_REVIEW:
            raise ValidationError("Session must be matched before finalization.")
        if session.source_resume.user_id != session.user_id or session.job_description.user_id != session.user_id:
            raise ValidationError("Session ownership is invalid.")
        source = session.source_data_snapshot
        if not isinstance(source, dict) or not source:
            raise ValidationError("This session has no saved source resume snapshot. Start a new analysis.")
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
        session.final_analysis_json = final_match
        session.status = OptimizationSession.Status.COMPLETED
        session.completed_at = timezone.now()
        session.save(update_fields=["final_analysis_json", "status", "completed_at", "updated_at"])
        return version
