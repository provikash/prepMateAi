import logging

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
