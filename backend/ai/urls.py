from django.urls import path

from .views import AIViewSet

urlpatterns = [
	path(
		"generate-summary/",
		AIViewSet.as_view({"post": "generate_summary"}),
		name="ai-generate-summary",
	),
	path(
		"improve-section/",
		AIViewSet.as_view({"post": "improve_section"}),
		name="ai-improve-section",
	),
	path(
		"suggest-skills/",
		AIViewSet.as_view({"post": "suggest_skills"}),
		name="ai-suggest-skills",
	),
	path(
		"generate-bullets/",
		AIViewSet.as_view({"post": "generate_bullets"}),
		name="ai-generate-bullets",
	),
	path(
		"tasks/<str:task_id>/",
		AIViewSet.as_view({"get": "task_status"}),
		name="ai-task-status",
	),
]
