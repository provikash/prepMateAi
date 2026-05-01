try:
	from celery.result import AsyncResult
except Exception:
	AsyncResult = None

from rest_framework import status, viewsets
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework.throttling import ScopedRateThrottle

from .serializers import (
	GenerateBulletsRequestSerializer,
	GenerateSummaryRequestSerializer,
	ImproveSectionRequestSerializer,
	SuggestSkillsRequestSerializer,
)
from .tasks import (
	generate_bullets_task,
	generate_summary_task,
	improve_section_task,
	suggest_skills_task,
)


class AIViewSet(viewsets.ViewSet):
	permission_classes = [IsAuthenticated]
	throttle_classes = [ScopedRateThrottle]

	ACTION_THROTTLE_SCOPE = {
		"generate_summary": "ai_generate_summary",
		"improve_section": "ai_improve_section",
		"suggest_skills": "ai_suggest_skills",
		"generate_bullets": "ai_generate_bullets",
		"task_status": "ai_task_status",
	}

	def get_throttles(self):
		self.throttle_scope = self.ACTION_THROTTLE_SCOPE.get(self.action, "ai_default")
		return super().get_throttles()

	def generate_summary(self, request):
		serializer = GenerateSummaryRequestSerializer(data=request.data)
		serializer.is_valid(raise_exception=True)

		async_result = generate_summary_task.delay(serializer.validated_data)
		return Response(
			{
				"task_id": async_result.id,
				"status": "queued",
				"message": "Summary generation task queued.",
			},
			status=status.HTTP_202_ACCEPTED,
		)

	def improve_section(self, request):
		serializer = ImproveSectionRequestSerializer(data=request.data)
		serializer.is_valid(raise_exception=True)

		async_result = improve_section_task.delay(
			text=serializer.validated_data["text"],
			section_name=serializer.validated_data["section_name"],
		)
		return Response(
			{
				"task_id": async_result.id,
				"status": "queued",
				"message": "Section improvement task queued.",
			},
			status=status.HTTP_202_ACCEPTED,
		)

	def suggest_skills(self, request):
		serializer = SuggestSkillsRequestSerializer(data=request.data)
		serializer.is_valid(raise_exception=True)

		async_result = suggest_skills_task.delay(
			role=serializer.validated_data["role"],
			existing_skills=serializer.validated_data.get("existing_skills", []),
		)
		return Response(
			{
				"task_id": async_result.id,
				"status": "queued",
				"message": "Skills suggestion task queued.",
			},
			status=status.HTTP_202_ACCEPTED,
		)

	def generate_bullets(self, request):
		serializer = GenerateBulletsRequestSerializer(data=request.data)
		serializer.is_valid(raise_exception=True)

		async_result = generate_bullets_task.delay(
			experience=serializer.validated_data["experience"]
		)
		return Response(
			{
				"task_id": async_result.id,
				"status": "queued",
				"message": "Bullet generation task queued.",
			},
			status=status.HTTP_202_ACCEPTED,
		)

	def task_status(self, request, task_id=None):
		if AsyncResult is None:
			return Response({"detail": "Celery is not available in this environment."}, status=status.HTTP_501_NOT_IMPLEMENTED)

		result = AsyncResult(task_id)
		state = result.state.lower()

		if result.failed():
			return Response(
				{
					"task_id": task_id,
					"status": state,
					"error": str(result.result),
				},
				status=status.HTTP_200_OK,
			)

		if result.ready():
			return Response(
				{
					"task_id": task_id,
					"status": state,
					"result": result.result,
				},
				status=status.HTTP_200_OK,
			)

		return Response(
			{
				"task_id": task_id,
				"status": state,
			},
			status=status.HTTP_200_OK,
		)
