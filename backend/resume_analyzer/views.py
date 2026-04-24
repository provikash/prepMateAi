from rest_framework import generics, status
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework.views import APIView

from .analysis_service import ResumeAnalyzerService
from .models import ResumeAnalysis
from .serializers import (
    AnalyzeResumeRequestSerializer,
    ReanalyzeRequestSerializer,
    ResumeAnalysisHistorySerializer,
    ResumeAnalysisResponseSerializer,
)


class ResumeAnalyzeAPIView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request):
        serializer = AnalyzeResumeRequestSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        payload = ResumeAnalyzerService.analyze(
            user=request.user,
            job_role=serializer.validated_data["job_role"],
            resume_id=serializer.validated_data.get("resume_id"),
            uploaded_file=serializer.validated_data.get("uploaded_file"),
        )

        response_serializer = ResumeAnalysisResponseSerializer(payload)
        return Response(response_serializer.data, status=status.HTTP_201_CREATED)


class ResumeAnalysisHistoryAPIView(generics.ListAPIView):
    permission_classes = [IsAuthenticated]
    serializer_class = ResumeAnalysisHistorySerializer

    def get_queryset(self):
        return ResumeAnalysis.objects.filter(user=self.request.user).order_by("-created_at")


class ResumeAnalysisDetailAPIView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request, analysis_id):
        analysis = ResumeAnalyzerService.get_analysis_or_404(user=request.user, analysis_id=analysis_id)
        payload = ResumeAnalyzerService.build_analysis_payload(analysis)
        response_serializer = ResumeAnalysisResponseSerializer(payload)
        return Response(response_serializer.data, status=status.HTTP_200_OK)


class ResumeAnalysisReanalyzeAPIView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request, analysis_id):
        serializer = ReanalyzeRequestSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        payload = ResumeAnalyzerService.reanalyze(
            user=request.user,
            analysis_id=analysis_id,
            job_role=serializer.validated_data.get("job_role"),
        )
        response_serializer = ResumeAnalysisResponseSerializer(payload)
        return Response(response_serializer.data, status=status.HTTP_201_CREATED)
