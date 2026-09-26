import logging
from django.db import transaction

from rest_framework import generics, permissions, status
from rest_framework.response import Response
from rest_framework.views import APIView
from django.shortcuts import get_object_or_404

from .models import JobDescription, OptimizationSession
from .serializers import (
    JobDescriptionSerializer,
    OptimizationSessionCreateSerializer,
    OptimizationSessionSerializer,
)
from .services.jd_analyzer import JDAnalyzer
from .services.matcher import RequirementMatcher
from ai.services.entitlements import EntitlementService

logger = logging.getLogger(__name__)


class JobDescriptionListCreateView(generics.ListCreateAPIView):
    permission_classes = [permissions.IsAuthenticated]
    serializer_class = JobDescriptionSerializer

    def get_queryset(self):
        return JobDescription.objects.filter(user=self.request.user)

    def perform_create(self, serializer):
        serializer.save(user=self.request.user)


class JobDescriptionDetailView(generics.RetrieveAPIView):
    permission_classes = [permissions.IsAuthenticated]
    serializer_class = JobDescriptionSerializer

    def get_queryset(self):
        return JobDescription.objects.filter(user=self.request.user)


class OptimizationSessionListCreateView(generics.ListCreateAPIView):
    permission_classes = [permissions.IsAuthenticated]

    def get_serializer_class(self):
        if self.request.method == "POST":
            return OptimizationSessionCreateSerializer
        return OptimizationSessionSerializer

    def get_queryset(self):
        return (
            OptimizationSession.objects.filter(user=self.request.user)
            .select_related("job_description", "source_resume")
            .prefetch_related("suggestions")
        )

    def create(self, request, *args, **kwargs):
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        session = serializer.save()
        output_serializer = OptimizationSessionSerializer(session, context={"request": request})
        return Response(output_serializer.data, status=status.HTTP_201_CREATED)


class ResumeOptimizationCreateView(APIView):
    """Compatibility facade for the public `/resume-optimizations/` contract."""

    permission_classes = [permissions.IsAuthenticated]

    @transaction.atomic
    def post(self, request):
        key = str(request.data.get("idempotency_key", "")).strip()
        if not 8 <= len(key) <= 100:
            return Response({"idempotency_key": "Use an 8 to 100 character key."}, status=400)
        existing = OptimizationSession.objects.filter(user=request.user, request_id=key).first()
        if existing:
            return self._response(existing, request, status.HTTP_200_OK)
        raw = request.data.copy()
        if isinstance(raw.get("job_description"), str):
            raw["job_description"] = {
                "description": raw["job_description"],
                "title": raw.get("job_title", ""),
                "company": raw.get("company_name", ""),
            }
        serializer = OptimizationSessionCreateSerializer(data=raw, context={"request": request})
        serializer.is_valid(raise_exception=True)
        session = serializer.save()
        session.request_id = key
        session.save(update_fields=["request_id", "updated_at"])
        return self._response(session, request, status.HTTP_201_CREATED)

    @staticmethod
    def _response(session, request, response_status):
        credit = EntitlementService.get_user_entitlements(request.user)["ai_credits"]
        return Response({
            "id": str(session.pk),
            "status": session.status.lower(),
            "credit": {
                "reserved": credit["reserved"],
                "remaining": credit["available"],
            },
        }, status=response_status)


class OptimizationSessionDetailView(generics.RetrieveAPIView):
    permission_classes = [permissions.IsAuthenticated]
    serializer_class = OptimizationSessionSerializer

    def get_queryset(self):
        return (
            OptimizationSession.objects.filter(user=self.request.user)
            .select_related("job_description", "source_resume")
            .prefetch_related("suggestions")
        )


class OptimizationSessionAnalyzeView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request, pk, *args, **kwargs):
        session = get_object_or_404(OptimizationSession, id=pk, user=request.user)

        if session.status not in (
            OptimizationSession.Status.DRAFT,
            OptimizationSession.Status.ANALYZED,
            OptimizationSession.Status.READY_FOR_REVIEW,
            OptimizationSession.Status.FAILED,
        ):
            return Response({"error": "Session cannot be analyzed in its current state."}, status=status.HTTP_409_CONFLICT)

        session.status = OptimizationSession.Status.ANALYZING
        session.save(update_fields=["status", "updated_at"])

        try:
            analyzer = JDAnalyzer()
            analysis = analyzer.analyze(
                job_description=session.job_description.description,
                job_title=session.job_description.title,
                company=session.job_description.company,
            )
            session.analysis_json = analysis
            session.status = OptimizationSession.Status.ANALYZED
            session.save(update_fields=["analysis_json", "status", "updated_at"])

            serializer = OptimizationSessionSerializer(session, context={"request": request})
            return Response(serializer.data, status=status.HTTP_200_OK)
        except Exception:
            logger.exception("Job description analysis failed for session %s", session.id)
            session.status = OptimizationSession.Status.FAILED
            session.save(update_fields=["status", "updated_at"])
            return Response(
                {"error": "Job description analysis failed."},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR,
            )


class OptimizationSessionMatchView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request, pk, *args, **kwargs):
        session = get_object_or_404(
            OptimizationSession.objects.select_related("source_resume", "job_description"),
            id=pk,
            user=request.user,
        )

        if session.status not in (
            OptimizationSession.Status.ANALYZED,
            OptimizationSession.Status.READY_FOR_REVIEW,
        ) or not session.analysis_json:
            return Response({"error": "Analyze the job description before matching."}, status=status.HTTP_409_CONFLICT)

        session.status = OptimizationSession.Status.MATCHING
        session.save(update_fields=["status", "updated_at"])

        try:
            requirements = session.analysis_json.get("requirements", [])
            resume_data = session.source_data_snapshot or session.source_resume.data or {}

            matcher = RequirementMatcher()
            match_results = matcher.match(requirements, resume_data)

            session.match_results_json = match_results
            session.status = OptimizationSession.Status.READY_FOR_REVIEW
            session.save(update_fields=["match_results_json", "status", "updated_at"])

            serializer = OptimizationSessionSerializer(session, context={"request": request})
            return Response(serializer.data, status=status.HTTP_200_OK)
        except Exception:
            logger.exception("Evidence matching failed for session %s", session.id)
            session.status = OptimizationSession.Status.FAILED
            session.save(update_fields=["status", "updated_at"])
            return Response(
                {"error": "Evidence matching failed."},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR,
            )
