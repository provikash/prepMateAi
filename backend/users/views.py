from core.media import media_url
import logging

from rest_framework import status, viewsets
from rest_framework.generics import RetrieveUpdateAPIView
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework.response import Response
from rest_framework.views import APIView
from .serializers import GuardedTokenRefreshSerializer, RefreshInputSerializer
from .api import AccountResponseMixin
from .throttles import AuthIPThrottle, AuthIdentityThrottle

from resume.models import Resume


from .serializers import (
    DashboardSerializer,
    UserProfileSerializer,
    UserSummarySerializer,
)
from .models import UserProfile

logger = logging.getLogger(__name__)


class AuthViewSet(AccountResponseMixin, viewsets.ViewSet):
    authentication_classes = []
    throttle_classes = [AuthIPThrottle, AuthIdentityThrottle]
    permission_classes = [AllowAny]

    def refresh(self, request):
        input_serializer = RefreshInputSerializer(data=request.data)
        input_serializer.is_valid(raise_exception=True)
        serializer = GuardedTokenRefreshSerializer(data=input_serializer.validated_data)
        serializer.is_valid(raise_exception=True)
        return Response(serializer.validated_data, status=status.HTTP_200_OK)


class ProfileViewSet(AccountResponseMixin, viewsets.ViewSet):
    permission_classes = [IsAuthenticated]

    def me(self, request):
        if request.method == "GET":
            return Response(UserSummarySerializer(request.user).data, status=status.HTTP_200_OK)

        serializer = UserSummarySerializer(
            request.user,
            data=request.data,
            partial=request.method == "PATCH",
        )
        serializer.is_valid(raise_exception=True)
        serializer.save()
        return Response(serializer.data, status=status.HTTP_200_OK)


class UserProfileRetrieveUpdateView(AccountResponseMixin, RetrieveUpdateAPIView):
    permission_classes = [IsAuthenticated]
    serializer_class = UserProfileSerializer

    def get_object(self):
        # Ensure profile always exists to avoid RelatedObjectDoesNotExist errors.
        # Use get_or_create so this view never crashes even if the profile was missing.
        profile, _created = UserProfile.objects.get_or_create(
            user=self.request.user,
            defaults={"full_name": getattr(self.request.user, "name", "") or ""},
        )
        return profile


class DashboardView(APIView):
    permission_classes = [IsAuthenticated]

    @staticmethod
    def _abs_file_url(request, file_field):
        if not file_field:
            return None
        return media_url(request, file_field)

    @staticmethod
    def _flatten_skill_dict(skill_dict):
        if not isinstance(skill_dict, dict):
            return []

        flattened = []
        for values in skill_dict.values():
            if isinstance(values, list):
                flattened.extend(item for item in values if isinstance(item, str) and item.strip())

        unique = []
        seen = set()
        for item in flattened:
            key = item.strip().lower()
            if key and key not in seen:
                seen.add(key)
                unique.append(item.strip())

        return unique

    def get(self, request):
        latest_resume = (
            Resume.objects.select_related("template")
            .filter(user=request.user)
            .only("id", "title", "thumbnail", "pdf_file", "template__preview_image", "created_at")
            .order_by("-created_at")
            .first()
        )

        if not latest_resume:
            payload = {
                "latest_resume": None,
                "message": "No resume found. Create your first resume.",
            }
            return Response(payload, status=status.HTTP_200_OK)

        thumbnail_url = self._abs_file_url(request, latest_resume.thumbnail)
        if thumbnail_url is None and latest_resume.template and latest_resume.template.preview_image:
            thumbnail_url = self._abs_file_url(request, latest_resume.template.preview_image)

        base_resume_payload = {
            "id": latest_resume.id,
            "title": latest_resume.title,
            "thumbnail_url": thumbnail_url,
            "pdf_url": self._abs_file_url(request, latest_resume.pdf_file),
        }

        payload = {
            "latest_resume": base_resume_payload,
            "analysis_available": False,
            "message": "Analyze your resume to get insights.",
        }

        serializer = DashboardSerializer(payload)
        return Response(serializer.data, status=status.HTTP_200_OK)

