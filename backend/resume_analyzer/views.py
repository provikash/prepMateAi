from rest_framework import generics, status
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework.views import APIView

from resume.models import Resume
from .analysis_service import ResumeAnalyzerService
from .models import ResumeAnalysis
from .serializers import (
    AnalyzeResumeRequestSerializer,
    ReanalyzeRequestSerializer,
    ResumeAnalysisResponseSerializer,
    ResumeSerializer,
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


class ResumeAnalysisHistoryAPIView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        analyses = ResumeAnalysis.objects.filter(user=request.user).order_by("-created_at")
        payload = [ResumeAnalyzerService.build_analysis_payload(item) for item in analyses]
        response_serializer = ResumeAnalysisResponseSerializer(payload, many=True)
        return Response(response_serializer.data, status=status.HTTP_200_OK)


class ResumeListAPIView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        resumes = Resume.objects.filter(user=request.user).order_by("-updated_at")
        result = []
        for resume in resumes:
            pdf_url = None
            if resume.pdf_file:
                try:
                    pdf_url = request.build_absolute_uri(resume.pdf_file.url)
                except Exception:
                    pdf_url = None
            result.append({
                "id": resume.id,
                "title": resume.title,
                "pdf_url": pdf_url,
            })
        serializer = ResumeSerializer(result, many=True)
        return Response(serializer.data, status=status.HTTP_200_OK)


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
