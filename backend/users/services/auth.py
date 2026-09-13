from django.contrib.auth import authenticate
from rest_framework_simplejwt.tokens import RefreshToken
from rest_framework.exceptions import AuthenticationFailed
from django.db import transaction
from users.models import User


class AuthService:
    @staticmethod
    def authenticate_user(email, password):
        return authenticate(email=email.strip().lower(), password=password)

    @staticmethod
    @transaction.atomic
    def issue_tokens(user):
        original_password = user.password
        user = User.objects.select_for_update().get(pk=user.pk)
        if user.password != original_password:
            raise AuthenticationFailed("Credentials changed. Please log in again.")
        if not user.is_active or not user.is_verified or user.deleted_at:
            raise AuthenticationFailed("Account is not eligible for authentication.")
        refresh = RefreshToken.for_user(user)
        return {
            "refresh": str(refresh),
            "access": str(refresh.access_token),
        }
