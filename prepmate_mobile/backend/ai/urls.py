from django.urls import path

from .views import (
	GenerateBulletsView,
	GenerateSummaryView,
	ImproveSectionView,
	SuggestSkillsView,
)

urlpatterns = [
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
