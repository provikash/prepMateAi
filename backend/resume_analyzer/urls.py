from django.urls import path

from .views import (
    ResumeAnalyzeAPIView,
    ResumeAnalysisDetailAPIView,
    ResumeAnalysisHistoryAPIView,
    ResumeListAPIView,
    ResumeAnalysisReanalyzeAPIView,
)


urlpatterns = [
    path("resume-analyzer/analyze/", ResumeAnalyzeAPIView.as_view(), name="resume-analyze"),
    path("resume-analyzer/resumes/", ResumeListAPIView.as_view(), name="resume-analyzer-resumes"),
    path("resume-analyzer/history/", ResumeAnalysisHistoryAPIView.as_view(), name="resume-analysis-history"),
    path("resume-analyzer/<uuid:analysis_id>/", ResumeAnalysisDetailAPIView.as_view(), name="resume-analysis-detail"),
    path(
        "resume-analyzer/<uuid:analysis_id>/reanalyze/",
        ResumeAnalysisReanalyzeAPIView.as_view(),
        name="resume-analysis-reanalyze",
    ),
]
