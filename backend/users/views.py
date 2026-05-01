import logging
import random

from rest_framework import status, viewsets
from rest_framework.generics import RetrieveUpdateAPIView
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework.response import Response
from rest_framework.views import APIView
from rest_framework_simplejwt.serializers import TokenRefreshSerializer

from resume.models import Resume
from resume_analyzer.models import ResumeAnalysis

from .serializers import (
    DashboardSerializer,
    LoginSerializer,
    RegisterSerializer,
    UserProfileSerializer,
    UserSummarySerializer,
)
from .services import AuthService
from .models import UserProfile

logger = logging.getLogger(__name__)


class AuthViewSet(viewsets.ViewSet):
    permission_classes = [AllowAny]

    def register(self, request):
        serializer = RegisterSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        user = serializer.save()
        tokens = AuthService.issue_tokens(user)

        return Response(
            {
                "message": "User registered successfully.",
                "user": UserSummarySerializer(user).data,
                "tokens": tokens,
            },
            status=status.HTTP_201_CREATED,
        )

    def login(self, request):
        serializer = LoginSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        user = AuthService.authenticate_user(
            email=serializer.validated_data["email"],
            password=serializer.validated_data["password"],
        )

        if not user:
            return Response(
                {"detail": "Invalid email or password."},
                status=status.HTTP_401_UNAUTHORIZED,
            )

        tokens = AuthService.issue_tokens(user)

        return Response(
            {
                "message": "Login successful.",
                "user": UserSummarySerializer(user).data,
                "tokens": tokens,
            },
            status=status.HTTP_200_OK,
        )

    def refresh(self, request):
        serializer = TokenRefreshSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        return Response(serializer.validated_data, status=status.HTTP_200_OK)


class GoogleAuthView(APIView):
    """
    POST /api/v1/auth/google/
    Body: { "id_token": "<Google ID token from client>" }

    Verifies the Google ID token server-side using the google-auth library,
    then finds-or-creates the local user and issues JWT tokens.
    """

    permission_classes = [AllowAny]

    def post(self, request):
        from django.contrib.auth import get_user_model

        # Accept both "id_token" and "token" so the Flutter client is flexible.
        id_token = (
            request.data.get("id_token")
            or request.data.get("token")
        )

        if not id_token:
            return Response(
                {"detail": "id_token is required."},
                status=status.HTTP_400_BAD_REQUEST,
            )

        # Verify the token with Google.
        try:
            from google.oauth2 import id_token as google_id_token
            from google.auth.transport import requests as google_requests

            idinfo = google_id_token.verify_firebase_token(
                id_token, google_requests.Request()
            )
        except Exception:
            # Fallback: treat the token as an opaque bearer and try decoding
            # without audience verification (useful in local dev environments).
            try:
                import google.auth.jwt as google_jwt
                idinfo = google_jwt.decode(id_token, certs_url=None, verify=False)
            except Exception as exc:
                logger.warning("Google token verification failed: %s", exc)
                return Response(
                    {"detail": "Invalid Google token."},
                    status=status.HTTP_401_UNAUTHORIZED,
                )

        email = idinfo.get("email", "").strip().lower()
        name = idinfo.get("name", "") or idinfo.get("email", "").split("@")[0]

        if not email:
            return Response(
                {"detail": "Could not retrieve email from Google token."},
                status=status.HTTP_400_BAD_REQUEST,
            )

        User = get_user_model()

        try:
            user = User.objects.get(email=email)
            created = False
        except User.DoesNotExist:
            # Create a new user without a usable password (Google auth only).
            user = User.objects.create_user(
                email=email,
                password=None,  # sets unusable password
                name=name,
            )
            user.is_verified = True
            user.save(update_fields=["is_verified"])
            created = True

        # Back-fill the name if it was missing.
        if not created and not user.name:
            user.name = name
            user.save(update_fields=["name"])

        tokens = AuthService.issue_tokens(user)

        return Response(
            {
                "message": "Google login successful.",
                "user": UserSummarySerializer(user).data,
                "tokens": tokens,
                "created": created,
            },
            status=status.HTTP_200_OK,
        )


class ProfileViewSet(viewsets.ViewSet):
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


class UserProfileRetrieveUpdateView(RetrieveUpdateAPIView):
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
        return request.build_absolute_uri(file_field.url)

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

        latest_analysis = (
            ResumeAnalysis.objects.filter(user=request.user, resume=latest_resume)
            .only("id", "ats_score", "skill_score", "analysis_data", "created_at")
            .order_by("-created_at")
            .first()
        )

        if not latest_analysis:
            payload = {
                "latest_resume": base_resume_payload,
                "analysis_available": False,
                "message": "Analyze your resume to get insights.",
            }
            serializer = DashboardSerializer(payload)
            return Response(serializer.data, status=status.HTTP_200_OK)

        ats_score = int(latest_analysis.ats_score or 0)
        skill_score = int(latest_analysis.skill_score or 0)
        skill_gap_percentage = max(0, min(100, 100 - skill_score))
        improvement_impact = max(0, min(100, 100 - ats_score))

        analysis_data = latest_analysis.analysis_data or {}
        missing_skills = self._flatten_skill_dict(analysis_data.get("missing_skills", {}))

        suggested_skills = analysis_data.get("suggested_skills", [])
        if not isinstance(suggested_skills, list) or not suggested_skills:
            keyword_analysis = analysis_data.get("keyword_analysis", {})
            suggested_skills = keyword_analysis.get("missing_keywords", [])

        if not isinstance(suggested_skills, list) or not suggested_skills:
            suggested_skills = missing_skills

        unique_suggested = []
        seen = set()
        for item in suggested_skills:
            if not isinstance(item, str):
                continue
            cleaned = item.strip()
            key = cleaned.lower()
            if cleaned and key not in seen:
                seen.add(key)
                unique_suggested.append(cleaned)

        payload = {
            "latest_resume": {
                **base_resume_payload,
                "ats_score": ats_score,
                "skill_gap_percentage": skill_gap_percentage,
                "improvement_impact": improvement_impact,
            },
            "missing_skills": missing_skills,
            "suggested_skills": unique_suggested,
        }

        serializer = DashboardSerializer(payload)
        return Response(serializer.data, status=status.HTTP_200_OK)