"""Additive v1 optimizer contract; legacy job-optimizer routes remain supported."""

from django.urls import path

from .views import OptimizationSessionDetailView, ResumeOptimizationCreateView
from .workflow_views import (
    FinalizeOptimizationView,
    OptimizationPDFStatusView,
    SuggestionDecisionView,
    SuggestionListView,
)

urlpatterns = [
    path("", ResumeOptimizationCreateView.as_view(), name="resume-optimization-list-create"),
    path("<uuid:pk>/", OptimizationSessionDetailView.as_view(), name="resume-optimization-detail"),
    path("<uuid:pk>/suggestions/", SuggestionListView.as_view(), name="resume-optimization-suggestions"),
    path(
        "<uuid:pk>/suggestions/<uuid:suggestion_pk>/",
        SuggestionDecisionView.as_view(),
        name="resume-optimization-suggestion-detail",
    ),
    path("<uuid:pk>/apply/", FinalizeOptimizationView.as_view(), name="resume-optimization-apply"),
    path("<uuid:pk>/pdf/", OptimizationPDFStatusView.as_view(), name="resume-optimization-pdf"),
]
