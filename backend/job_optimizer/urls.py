from django.urls import path

from .views import (
    JobDescriptionDetailView,
    JobDescriptionListCreateView,
    OptimizationSessionAnalyzeView,
    OptimizationSessionDetailView,
    OptimizationSessionListCreateView,
    OptimizationSessionMatchView,
)
from .workflow_views import (
    ConfirmMissingSkillView, FinalizeOptimizationView, GenerateSuggestionsView, OptimizedVersionPDFView,
    OptimizedVersionView, RegenerateSuggestionView, SuggestionListView,
    SuggestionReviewView, SuggestionDecisionView, OptimizationPDFStatusView,
)

urlpatterns = [
    path("job-descriptions/", JobDescriptionListCreateView.as_view(), name="job-description-list-create"),
    path("job-descriptions/<uuid:pk>/", JobDescriptionDetailView.as_view(), name="job-description-detail"),
    path("sessions/", OptimizationSessionListCreateView.as_view(), name="optimization-session-list-create"),
    path("sessions/<uuid:pk>/", OptimizationSessionDetailView.as_view(), name="optimization-session-detail"),
    path("sessions/<uuid:pk>/analyze/", OptimizationSessionAnalyzeView.as_view(), name="optimization-session-analyze"),
    path("sessions/<uuid:pk>/match/", OptimizationSessionMatchView.as_view(), name="optimization-session-match"),
    path("sessions/<uuid:pk>/suggestions/", SuggestionListView.as_view()),
    path("sessions/<uuid:pk>/suggestions/confirm-missing-skill/", ConfirmMissingSkillView.as_view()),
    path("sessions/<uuid:pk>/suggestions/<uuid:suggestion_pk>/", SuggestionDecisionView.as_view()),
    path("sessions/<uuid:pk>/suggestions/generate/", GenerateSuggestionsView.as_view()),
    path("sessions/<uuid:pk>/finalize/", FinalizeOptimizationView.as_view()),
    path("sessions/<uuid:pk>/apply/", FinalizeOptimizationView.as_view()),
    path("sessions/<uuid:pk>/pdf/", OptimizationPDFStatusView.as_view()),
    path("suggestions/<uuid:pk>/regenerate/", RegenerateSuggestionView.as_view()),
    path("suggestions/<uuid:pk>/<str:action>/", SuggestionReviewView.as_view()),
    path("versions/<uuid:pk>/", OptimizedVersionView.as_view()),
    path("versions/<uuid:pk>/pdf/", OptimizedVersionPDFView.as_view()),
]
