from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework.response import Response
from rest_framework.views import APIView
from rest_framework.exceptions import ValidationError
from rest_framework_simplejwt.tokens import RefreshToken
from rest_framework_simplejwt.exceptions import TokenError
from users.api import AccountResponseMixin
from users.models import EmailOTP, OTPChallenge, User
from users.serializers import (
    AccountActionRequestSerializer,
    EmailSerializer,
    VerifyEmailSerializer,
    PasswordResetConfirmSerializer,
    ChangePasswordSerializer,
    PasswordConfirmationSerializer,
    LifecycleOTPSerializer,
    PhoneInputSerializer,
    PhoneChangeVerifySerializer,
    RefreshInputSerializer,
    UserSummarySerializer,
)
from users.services.account_service import AccountService
from users.services.mobile_otp_service import MobileOTPService, OTPFlowError
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

    def patch(self, request):
        if self.action != "me":
            return self.http_method_not_allowed(request)
        serializer = UserSummarySerializer(request.user, data=request.data, partial=True)
        serializer.is_valid(raise_exception=True)
        serializer.save()
        return Response({"success": True, "data": serializer.data})

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


class LifecycleAPIView(AccountResponseMixin, APIView):
    permission_classes = [IsAuthenticated]
    throttle_classes = [AuthIPThrottle]

    @staticmethod
    def request_metadata(request):
        from django.conf import settings

        forwarded = (
            request.META.get("HTTP_X_FORWARDED_FOR", "").split(",")[0].strip()
            if getattr(settings, "SECURE_PROXY_SSL_HEADER", None)
            else ""
        )
        return (
            forwarded or request.META.get("REMOTE_ADDR", ""),
            request.headers.get("X-Device-ID", "")[:256],
        )

    @staticmethod
    def challenge_response(challenge, *, status_code=201):
        return Response(
            {
                "success": True,
                "message": "A verification code has been sent.",
                "challenge_id": str(challenge.pk),
                "expires_in_seconds": max(
                    0, int((challenge.expires_at - challenge.created_at).total_seconds())
                ),
                "resend_available_in_seconds": max(
                    0,
                    int(
                        (
                            challenge.resend_available_at - challenge.created_at
                        ).total_seconds()
                    ),
                ),
            },
            status=status_code,
        )

    @staticmethod
    def error_response(exc):
        return Response(
            {"success": False, "code": exc.code, "message": exc.message},
            status=exc.status_code,
        )


class AccountActionChallengeView(LifecycleAPIView):
    action = "account_action_request"

    def post(self, request):
        serializer = AccountActionRequestSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        if not request.user.phone_number or not request.user.is_phone_verified:
            raise ValidationError({"phone_number": "A verified phone number is required."})
        ip, device_id = self.request_metadata(request)
        try:
            challenge = MobileOTPService.issue(
                request.user.phone_number,
                ip,
                device_id,
                purpose=OTPChallenge.Purpose.ACCOUNT_ACTION,
                requested_by=request.user,
                action=serializer.validated_data["action"],
            )
        except OTPFlowError as exc:
            return self.error_response(exc)
        return self.challenge_response(challenge)


class AccountDeactivateView(LifecycleAPIView):
    action = "account_deactivate"

    def post(self, request):
        serializer = LifecycleOTPSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        try:
            AccountService.deactivate(request.user, **serializer.validated_data)
        except OTPFlowError as exc:
            return self.error_response(exc)
        return Response(
            {
                "success": True,
                "message": "Account deactivated. Verify your phone again to reactivate it.",
                "authentication_revoked": True,
            }
        )


class AccountDeleteView(LifecycleAPIView):
    action = "account_delete"

    def delete(self, request):
        serializer = LifecycleOTPSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        try:
            AccountService.delete_permanently(
                request.user, **serializer.validated_data
            )
        except OTPFlowError as exc:
            return self.error_response(exc)
        return Response(status=204)


class PhoneChangeRequestView(LifecycleAPIView):
    action = "phone_change_request"

    def post(self, request):
        serializer = PhoneInputSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        phone_number = serializer.validated_data["phone_number"]
        if phone_number == request.user.phone_number:
            raise ValidationError({"phone_number": "Enter a different phone number."})
        if User.objects.exclude(pk=request.user.pk).filter(
            phone_number=phone_number
        ).exists():
            raise ValidationError({"phone_number": "This phone number cannot be used."})
        ip, device_id = self.request_metadata(request)
        try:
            challenge = MobileOTPService.issue(
                phone_number,
                ip,
                device_id,
                purpose=OTPChallenge.Purpose.CHANGE_PHONE,
                requested_by=request.user,
                action="change_phone",
            )
        except OTPFlowError as exc:
            return self.error_response(exc)
        return self.challenge_response(challenge)


class PhoneChangeVerifyView(LifecycleAPIView):
    action = "phone_change_verify"

    def post(self, request):
        serializer = PhoneChangeVerifySerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        try:
            AccountService.change_phone(request.user, **serializer.validated_data)
        except OTPFlowError as exc:
            return self.error_response(exc)
        return Response(
            {
                "success": True,
                "message": "Phone number changed. Please sign in again.",
                "authentication_revoked": True,
            }
        )


class LogoutAllView(LifecycleAPIView):
    action = "logout_all"

    def post(self, request):
        AccountService.revoke_all_sessions(request.user)
        return Response(
            {
                "success": True,
                "message": "Signed out on all devices.",
                "authentication_revoked": True,
            }
        )
