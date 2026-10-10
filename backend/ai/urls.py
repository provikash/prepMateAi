from django.urls import path
from .credit_views import AICreditsView, AICreditTransactionsView, AIOperationsView

from .views import (
	GenerateBulletsView,
	GenerateSummaryView,
	ImproveSectionView,
	SuggestSkillsView,
)

urlpatterns = [
	path("credits/", AICreditsView.as_view(), name="ai-credits"),
	path("credits/transactions/", AICreditTransactionsView.as_view(), name="ai-credit-transactions"),
	path("operations/", AIOperationsView.as_view(), name="ai-operations"),
	path(
		"generate-summary/",
		GenerateSummaryView.as_view(),
		name="ai-generate-summary",
	),
	path(
		"improve-section/",
		ImproveSectionView.as_view(),
		name="ai-improve-section",
	),
	path(
		"suggest-skills/",
		SuggestSkillsView.as_view(),
		name="ai-suggest-skills",
	),
	path(
		"generate-bullets/",
		GenerateBulletsView.as_view(),
		name="ai-generate-bullets",
	),
]
