from rest_framework import status
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework.throttling import ScopedRateThrottle
from rest_framework.views import APIView

from .serializers import (
	GenerateBulletsRequestSerializer,
	GenerateSummaryRequestSerializer,
	ImproveSectionRequestSerializer,
	SuggestSkillsRequestSerializer,
)
from .tasks import (
	generate_bullets,
	generate_summary,
	improve_section,
	suggest_skills,
)


class GenerateSummaryView(APIView):
	permission_classes = [IsAuthenticated]
	throttle_classes = [ScopedRateThrottle]
	throttle_scope = "ai_generate_summary"

	def post(self, request):
		serializer = GenerateSummaryRequestSerializer(data=request.data)
		serializer.is_valid(raise_exception=True)

		result = generate_summary(serializer.validated_data)
		return Response(result, status=status.HTTP_200_OK)


class ImproveSectionView(APIView):
	permission_classes = [IsAuthenticated]
	throttle_classes = [ScopedRateThrottle]
	throttle_scope = "ai_improve_section"

	def post(self, request):
		serializer = ImproveSectionRequestSerializer(data=request.data)
		serializer.is_valid(raise_exception=True)

		result = improve_section(
			text=serializer.validated_data["text"],
			section_name=serializer.validated_data["section_name"],
		)
		return Response(result, status=status.HTTP_200_OK)


class SuggestSkillsView(APIView):
	permission_classes = [IsAuthenticated]
	throttle_classes = [ScopedRateThrottle]
	throttle_scope = "ai_suggest_skills"

	def post(self, request):
		serializer = SuggestSkillsRequestSerializer(data=request.data)
		serializer.is_valid(raise_exception=True)

		result = suggest_skills(
			role=serializer.validated_data["role"],
			existing_skills=serializer.validated_data.get("existing_skills", []),
		)
		return Response(result, status=status.HTTP_200_OK)


class GenerateBulletsView(APIView):
	permission_classes = [IsAuthenticated]
	throttle_classes = [ScopedRateThrottle]
	throttle_scope = "ai_generate_bullets"

	def post(self, request):
		serializer = GenerateBulletsRequestSerializer(data=request.data)
		serializer.is_valid(raise_exception=True)

		result = generate_bullets(experience=serializer.validated_data["experience"])
		return Response(result, status=status.HTTP_200_OK)
