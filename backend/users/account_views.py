from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework.response import Response
from rest_framework.views import APIView
from rest_framework.exceptions import ValidationError
from rest_framework_simplejwt.tokens import RefreshToken
from rest_framework_simplejwt.exceptions import TokenError
from users.api import AccountResponseMixin
from users.models import EmailOTP, User
from users.serializers import (EmailSerializer, VerifyEmailSerializer, PasswordResetConfirmSerializer, ChangePasswordSerializer, PasswordConfirmationSerializer, RefreshInputSerializer, UserSummarySerializer)
from users.services.account_service import AccountService
from users.services.otp_service import OTPService
from users.services.email_service import EmailDeliveryError
from users.throttles import AuthIPThrottle, AuthIdentityThrottle


class AuthenticationSchemaView(APIView):
    permission_classes = [AllowAny]
    authentication_classes = []

    def get(self, request):
        import json
        from pathlib import Path
        return Response(json.loads(Path(__file__).with_name("authentication_openapi.json").read_text()))


class AccountActionView(AccountResponseMixin, APIView):
    permission_classes = [AllowAny]
    authentication_classes = []
    throttle_classes = [AuthIPThrottle, AuthIdentityThrottle]
    auth_scope = "verify"
    action = "verify"

    def post(self, request):
        actions = {
            "verify": VerifyEmailSerializer, "resend": EmailSerializer,
            "reset_request": EmailSerializer, "reset_confirm": PasswordResetConfirmSerializer,
        }
        serializer = actions[self.action](data=request.data)
        serializer.is_valid(raise_exception=True)
        data = serializer.validated_data
        purpose = EmailOTP.Purpose.PASSWORD_RESET if self.action.startswith("reset") else EmailOTP.Purpose.EMAIL_VERIFICATION
        if self.action in {"resend", "reset_request"}:
            user = User.objects.filter(email__iexact=data["email"], is_active=True, deleted_at__isnull=True).first()
            if user:
                try:
                    OTPService.issue(user, purpose)
                except EmailDeliveryError:
                    # Preserve the same response for unknown accounts and provider failures.
                    pass
            return Response({"success": True, "message": "If the account is eligible, a verification code has been sent."})
        AccountService.verify(data["email"], data["otp"], purpose, data.get("new_password"))
        return Response({"success": True, "message": "Email verified." if self.action == "verify" else "Password changed. Please log in again."})


class AuthenticatedAccountView(AccountResponseMixin, APIView):
    permission_classes = [IsAuthenticated]
    throttle_classes = [AuthIPThrottle]
    action = "me"

    def get(self, request):
        if self.action != "me":
            return self.http_method_not_allowed(request)
        return Response({"success": True, "data": UserSummarySerializer(request.user).data})

    def post(self, request):
        if self.action == "logout":
            serializer = RefreshInputSerializer(data=request.data)
            serializer.is_valid(raise_exception=True)
            try:
                token = RefreshToken(serializer.validated_data["refresh"])
                if str(token["user_id"]) != str(request.user.pk):
                    raise ValidationError({"refresh": "Invalid refresh token."})
                token.blacklist()
            except (TokenError, KeyError):
                raise ValidationError({"refresh": "Invalid refresh token."}) from None
            return Response({"success": True, "message": "Logged out."})
        if self.action not in {"change_password", "deactivate"}:
            return self.http_method_not_allowed(request)
        serializer_class = ChangePasswordSerializer if self.action == "change_password" else PasswordConfirmationSerializer
        serializer = serializer_class(data=request.data)
        serializer.is_valid(raise_exception=True)
        AccountService.change(request.user, **serializer.validated_data, deactivate=self.action == "deactivate")
        return Response({"success": True, "message": "Account updated. Authentication credentials revoked."})

    def delete(self, request):
        if self.action != "account":
            return self.http_method_not_allowed(request)
        serializer = PasswordConfirmationSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        AccountService.change(request.user, **serializer.validated_data, delete=True)
        return Response(status=204)
