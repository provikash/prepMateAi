import logging

from django.db import transaction
from django.http import HttpResponse
from django.shortcuts import get_object_or_404
from django.core.files.base import ContentFile
from rest_framework import permissions, status
from rest_framework.exceptions import ValidationError
from rest_framework.response import Response
from rest_framework.throttling import ScopedRateThrottle
from rest_framework.views import APIView

from ai.services.credits import CreditService
from resume.models import ResumeVersion
from resume.rendering import ResumeRenderService
from exports.services.pdf_validation import validate_optimized_pdf
from .models import OptimizationSession, OptimizationSuggestion
from .serializers import OptimizationSuggestionSerializer
from .services.finalize import ResumeOptimizationService
from .services.suggestions import SuggestionEngine, get_path, target_metadata

logger = logging.getLogger(__name__)


def owned_session(request, pk):
    return get_object_or_404(
        OptimizationSession.objects.select_related("source_resume", "job_description"),
        pk=pk, user=request.user, source_resume__user=request.user,
        job_description__user=request.user,
    )


def owned_suggestion(request, pk):
    return get_object_or_404(
        OptimizationSuggestion.objects.select_related("optimization_session", "optimization_session__source_resume"),
        pk=pk, optimization_session__user=request.user,
        optimization_session__source_resume__user=request.user,
        optimization_session__job_description__user=request.user,
    )


def apply_review_decision(suggestion, payload):
    raw_status = str(payload.get("status", "")).upper()
    expected = payload.get("decision_version", payload.get("version"))
    if expected is not None and expected != suggestion.decision_version:
        raise ValidationError({
            "code": "suggestion_conflict",
            "message": "This suggestion was changed on another device. Refresh and try again.",
            "decision_version": suggestion.decision_version,
        })
    if raw_status == OptimizationSuggestion.Status.ACCEPTED:
        suggestion.status = raw_status
        suggestion.final_value = suggestion.ai_suggestion
        suggestion.user_edited_value = None
    elif raw_status == OptimizationSuggestion.Status.REJECTED:
        suggestion.status = raw_status
        suggestion.final_value = None
        suggestion.user_edited_value = None
    elif raw_status == OptimizationSuggestion.Status.EDITED:
        value = payload.get("edited_value", payload.get("value"))
        if not isinstance(value, str) or not value.strip() or len(value) > 1500:
            raise ValidationError({"edited_value": "Enter 1 to 1500 characters."})
        suggestion.status = raw_status
        suggestion.user_edited_value = value.strip()
        suggestion.final_value = value.strip()
    elif raw_status == OptimizationSuggestion.Status.PENDING:
        if suggestion.status == OptimizationSuggestion.Status.APPLIED:
            raise ValidationError("Applied suggestions cannot be changed.")
        suggestion.status = raw_status
        suggestion.final_value = None
        suggestion.user_edited_value = None
    else:
        raise ValidationError({"status": "Use pending, accepted, edited, or rejected."})
    suggestion.decision_version += 1
    suggestion.save(update_fields=[
        "status", "final_value", "user_edited_value", "decision_version", "updated_at",
    ])
    logger.info(
        "suggestion_%s user_id=%s optimization_session_id=%s suggestion_id=%s",
        suggestion.status.lower(), suggestion.optimization_session.user_id,
        suggestion.optimization_session_id, suggestion.pk,
    )
    return suggestion


class SuggestionListView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request, pk):
        session = owned_session(request, pk)
        return Response(OptimizationSuggestionSerializer(session.suggestions.all(), many=True).data)

    @transaction.atomic
    def patch(self, request, pk):
        session = owned_session(request, pk)
        session = OptimizationSession.objects.select_for_update().get(pk=session.pk)
        if session.status != OptimizationSession.Status.READY_FOR_REVIEW:
            return Response({"code": "session_not_reviewable", "message": "Session is not open for review."}, status=409)
        updates = request.data.get("updates")
        if not isinstance(updates, list) or not updates:
            raise ValidationError({"updates": "Provide at least one suggestion update."})
        ids = [item.get("id") for item in updates if isinstance(item, dict)]
        suggestions = {
            str(item.pk): item for item in OptimizationSuggestion.objects.select_for_update().filter(
                optimization_session=session, pk__in=ids
            )
        }
        if len(suggestions) != len(updates) or len(set(ids)) != len(ids):
            raise ValidationError({"updates": "Every suggestion must be unique and belong to this session."})
        changed = [apply_review_decision(suggestions[str(item["id"])], item) for item in updates]
        return Response(OptimizationSuggestionSerializer(changed, many=True).data)


class SuggestionDecisionView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    @transaction.atomic
    def patch(self, request, pk, suggestion_pk):
        session = owned_session(request, pk)
        session = OptimizationSession.objects.select_for_update().get(pk=session.pk)
        if session.status != OptimizationSession.Status.READY_FOR_REVIEW:
            return Response({"code": "session_not_reviewable", "message": "Session is not open for review."}, status=409)
        suggestion = get_object_or_404(
            OptimizationSuggestion.objects.select_for_update(),
            pk=suggestion_pk, optimization_session=session,
        )
        apply_review_decision(suggestion, request.data)
        return Response(OptimizationSuggestionSerializer(suggestion).data)


class GenerateSuggestionsView(APIView):
    permission_classes = [permissions.IsAuthenticated]
    throttle_classes = [ScopedRateThrottle]
    throttle_scope = "optimizer_generate"

    def post(self, request, pk):
        session = owned_session(request, pk)
        logger.info("optimization_apply_started user_id=%s optimization_session_id=%s", request.user.pk, session.pk)
        if session.status != OptimizationSession.Status.READY_FOR_REVIEW:
            return Response({"error": "Match the resume before generating suggestions."}, status=409)
        if session.suggestions.exists():
            return Response(OptimizationSuggestionSerializer(session.suggestions.all(), many=True).data)
        engine = SuggestionEngine()
        if not engine.candidates(session):
            return Response([])
        usage, created = CreditService.reserve(
            user=request.user, operation="resume_optimization",
            idempotency_key=f"optimizer-generate:{session.pk}", reference_id=session.pk,
        )
        if not created:
            if usage.status == usage.Status.SUCCEEDED:
                return Response(OptimizationSuggestionSerializer(session.suggestions.all(), many=True).data)
            return Response({"error": "This AI request is already processing or failed."}, status=409)
        try:
            proposals, result = engine.generate(session)
            if not proposals:
                CreditService.release(usage, "no_valid_suggestions")
                return Response({"error": "AI returned no evidence-backed suggestions."}, status=422)
            with transaction.atomic():
                for proposal in proposals:
                    OptimizationSuggestion.objects.create(
                        optimization_session=session,
                        **proposal,
                        **target_metadata(session.pk, proposal["resume_path"]),
                    )
                CreditService.commit(usage, result)
            return Response(OptimizationSuggestionSerializer(session.suggestions.all(), many=True).data)
        except Exception as exc:
            CreditService.release(usage, type(exc).__name__)
            logger.exception("Suggestion generation failed for session %s", session.pk)
            return Response({"error": "Suggestion generation failed; reserved credits were released."}, status=503)


class SuggestionReviewView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    @transaction.atomic
    def post(self, request, pk, action):
        suggestion = owned_suggestion(request, pk)
        suggestion = OptimizationSuggestion.objects.select_for_update().get(pk=suggestion.pk)
        if suggestion.optimization_session.status != OptimizationSession.Status.READY_FOR_REVIEW:
            return Response({"error": "Session is not open for review."}, status=409)
        mapped = {"accept": "ACCEPTED", "reject": "REJECTED", "edit": "EDITED", "undo": "PENDING"}
        if action not in mapped:
            raise ValidationError("Unknown review action.")
        apply_review_decision(suggestion, {
            "status": mapped[action],
            "edited_value": request.data.get("value"),
            "decision_version": request.data.get("decision_version"),
        })
        return Response(OptimizationSuggestionSerializer(suggestion).data)


class RegenerateSuggestionView(APIView):
    permission_classes = [permissions.IsAuthenticated]
    throttle_classes = [ScopedRateThrottle]
    throttle_scope = "optimizer_regenerate"

    def post(self, request, pk):
        suggestion = owned_suggestion(request, pk)
        session = suggestion.optimization_session
        if session.status != OptimizationSession.Status.READY_FOR_REVIEW or suggestion.status != OptimizationSuggestion.Status.PENDING:
            return Response({"error": "Only pending suggestions can be regenerated."}, status=409)
        key = request.headers.get("Idempotency-Key", "").strip()
        if not 8 <= len(key) <= 100:
            raise ValidationError({"Idempotency-Key": "An 8–100 character idempotency key is required."})
        instruction = request.data.get("instruction", "")
        if not isinstance(instruction, str) or not 1 <= len(instruction.strip()) <= 300:
            raise ValidationError({"instruction": "Enter 1 to 300 characters."})
        evidence = [
            item for result in session.match_results_json.get("results", [])
            for item in result.get("evidence", [])
            if item.get("path") in suggestion.evidence_reference
        ]
        if not evidence:
            raise ValidationError("Original suggestion evidence is unavailable.")
        candidate = {
            "requirement": suggestion.keywords[0] if suggestion.keywords else "Resume alignment",
            "status": "MATCHED", "resume_path": suggestion.resume_path,
            "original_value": get_path(session.source_data_snapshot, suggestion.resume_path),
            "evidence_paths": [e["path"] for e in evidence],
            "evidence_texts": [e["text"] for e in evidence],
        }
        usage, created = CreditService.reserve(
            user=request.user, operation="suggestion_regeneration",
            idempotency_key=f"optimizer-regen:{key}", reference_id=suggestion.pk,
        )
        if not created:
            if usage.status == usage.Status.SUCCEEDED and usage.reference_id == suggestion.pk:
                suggestion.refresh_from_db()
                return Response(OptimizationSuggestionSerializer(suggestion).data)
            return Response({"error": "This AI request is already processing or failed."}, status=409)
        try:
            proposals, result = SuggestionEngine().generate(
                session, instruction=instruction.strip(), candidate_override=candidate,
            )
            if not proposals:
                CreditService.release(usage, "no_valid_suggestion")
                return Response({"error": "AI returned no evidence-backed revision."}, status=422)
            proposal = proposals[0]
            with transaction.atomic():
                suggestion = OptimizationSuggestion.objects.select_for_update().get(pk=suggestion.pk)
                history = list(suggestion.revision_history)
                history.append({"value": suggestion.ai_suggestion, "prompt_version": suggestion.prompt_version})
                suggestion.revision_history = history
                suggestion.ai_suggestion = proposal["ai_suggestion"]
                suggestion.reason = proposal["reason"]
                suggestion.keywords = proposal["keywords"]
                suggestion.evidence_reference = proposal["evidence_reference"]
                suggestion.save(update_fields=["revision_history", "ai_suggestion", "reason", "keywords", "evidence_reference", "updated_at"])
                CreditService.commit(usage, result)
            return Response(OptimizationSuggestionSerializer(suggestion).data)
        except Exception as exc:
            CreditService.release(usage, type(exc).__name__)
            logger.exception("Suggestion regeneration failed for %s", suggestion.pk)
            return Response({"error": "Regeneration failed; reserved credits were released."}, status=503)


class FinalizeOptimizationView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request, pk):
        session = owned_session(request, pk)
        name = request.data.get("name", "")
        if not isinstance(name, str) or len(name) > 255:
            raise ValidationError({"name": "Version name must be at most 255 characters."})
        key = str(request.data.get("idempotency_key") or request.headers.get("Idempotency-Key", "")).strip()
        if key and not 8 <= len(key) <= 100:
            raise ValidationError({"idempotency_key": "Use an 8 to 100 character key."})
        expected = request.data.get("expected_source_version")
        if expected is not None:
            try:
                expected = int(expected)
            except (TypeError, ValueError) as exc:
                raise ValidationError({"expected_source_version": "Enter an integer."}) from exc
        version = ResumeOptimizationService.finalize(
            session, name=name, idempotency_key=key, expected_source_version=expected,
        )
        logger.info(
            "optimization_apply_completed user_id=%s optimization_session_id=%s resume_version_id=%s",
            request.user.pk, session.pk, version.pk,
        )
        return Response({
            "optimization_session_id": str(session.pk),
            "resume_version_id": str(version.pk),
            "optimized_resume": {
                "id": str(version.source_resume_id),
                "version_id": str(version.pk),
                "version_number": version.template_version,
            },
            "pdf": {
                "status": version.pdf_status.lower(),
                "url": f"/api/v1/job-optimizer/versions/{version.pk}/pdf/" if version.pdf_file else None,
            },
            "status": "COMPLETED",
            "before_alignment_score": session.match_results_json.get("summary", {}).get("alignment_score"),
            "after_alignment_score": version.optimization_session.final_analysis_json.get("summary", {}).get("alignment_score"),
            "before_ats_score": version.optimization_session.final_analysis_json.get("before_ats", {}).get("ats_score"),
            "after_ats_score": version.optimization_session.final_analysis_json.get("after_ats", {}).get("ats_score"),
        })


class OptimizedVersionView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request, pk):
        version = get_object_or_404(ResumeVersion, pk=pk, user=request.user, source_resume__user=request.user)
        return Response({"id": str(version.pk), "title": version.title, "data": version.data,
                         "source_resume_id": str(version.source_resume_id),
                         "pdf_url": f"/api/v1/job-optimizer/versions/{version.pk}/pdf/"})


class OptimizedVersionPDFView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request, pk):
        version = get_object_or_404(ResumeVersion.objects.select_related("template"), pk=pk, user=request.user)
        if not version.template:
            return Response({"error": "The source resume has no template."}, status=409)
        if version.pdf_file:
            version.pdf_file.open("rb")
            pdf = version.pdf_file.read()
            version.pdf_file.close()
        else:
            try:
                logger.info("pdf_generation_started user_id=%s resume_version_id=%s", request.user.pk, version.pk)
                version.pdf_status = "GENERATING"
                version.pdf_error_code = ""
                version.save(update_fields=["pdf_status", "pdf_error_code", "updated_at"])
                from weasyprint import HTML
                html = ResumeRenderService.render_resume(version.data, version.template, resume_title=version.title)
                if any(token in html for token in ("{{", "}}", "undefined", ">null<")):
                    raise ValueError("Unresolved template output")
                pdf = HTML(string=html).write_pdf()
                applied_values = version.optimization_session.suggestions.filter(
                    status=OptimizationSuggestion.Status.APPLIED
                ).values_list("final_value", flat=True)
                validate_optimized_pdf(pdf, version=version, applied_values=applied_values)
                version.pdf_file.save(f"optimized_{version.pk}.pdf", ContentFile(pdf), save=True)
                from django.utils import timezone
                version.pdf_status = "READY"
                version.pdf_generated_at = timezone.now()
                version.save(update_fields=["pdf_status", "pdf_generated_at", "updated_at"])
                logger.info("pdf_generation_completed user_id=%s resume_version_id=%s", request.user.pk, version.pk)
            except Exception:
                logger.exception("Optimized PDF generation failed for version %s", version.pk)
                version.pdf_status = "FAILED"
                version.pdf_error_code = "pdf_generation_failed"
                version.save(update_fields=["pdf_status", "pdf_error_code", "updated_at"])
                logger.info("pdf_generation_failed user_id=%s resume_version_id=%s error_code=pdf_generation_failed", request.user.pk, version.pk)
                return Response({"error": "PDF generation is unavailable right now."}, status=503)
        response = HttpResponse(pdf, content_type="application/pdf")
        response["Content-Disposition"] = f'attachment; filename="optimized_{version.pk}.pdf"'
        return response


class OptimizationPDFStatusView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request, pk):
        session = owned_session(request, pk)
        version = getattr(session, "optimized_version", None)
        if version is None:
            return Response({"status": "not_requested", "url": None})
        return Response({
            "status": version.pdf_status.lower(),
            "url": f"/api/v1/job-optimizer/versions/{version.pk}/pdf/" if version.pdf_file else None,
            "error_code": version.pdf_error_code or None,
            "version_id": str(version.pk),
        })
