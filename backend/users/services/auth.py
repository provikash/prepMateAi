from django.contrib.auth import authenticate
from rest_framework_simplejwt.tokens import RefreshToken


class AuthService:
    @staticmethod
    def authenticate_user(email, password):
        return authenticate(email=email.strip().lower(), password=password)

    @staticmethod
    def issue_tokens(user):
        refresh = RefreshToken.for_user(user)
        return {
            "refresh": str(refresh),
            "access": str(refresh.access_token),
        }
