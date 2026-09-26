from rest_framework.permissions import AllowAny
from rest_framework.response import Response
from rest_framework.views import APIView

from .api import AccountResponseMixin
from .serializers import OTPResendSerializer, OTPVerifySerializer, PhoneInputSerializer, UserSummarySerializer
from .services.mobile_otp_service import MobileOTPService, OTPFlowError
from .throttles import AuthIPThrottle, AuthIdentityThrottle


class MobileOTPView(AccountResponseMixin, APIView):
    permission_classes = [AllowAny]
    authentication_classes = []
    throttle_classes = [AuthIPThrottle, AuthIdentityThrottle]
    action = "otp_request"

    def _metadata(self, request):
        from django.conf import settings
        forwarded = request.META.get("HTTP_X_FORWARDED_FOR", "").split(",")[0].strip() if getattr(settings, "SECURE_PROXY_SSL_HEADER", None) else ""
        return forwarded or request.META.get("REMOTE_ADDR", ""), request.headers.get("X-Device-ID", "")[:256]

    def post(self, request):
        serializer_class = OTPResendSerializer if self.action == "otp_resend" else PhoneInputSerializer
        serializer = serializer_class(data=request.data)
        serializer.is_valid(raise_exception=True)
        data = serializer.validated_data
        ip, device_id = self._metadata(request)
        try:
            challenge = MobileOTPService.issue(data["phone_number"], ip, device_id, data.get("challenge_id"))
        except OTPFlowError as exc:
            return Response({"success": False, "code": exc.code, "message": exc.message}, status=exc.status_code)
        return Response({
            "success": True,
            "message": "If the number is eligible, an OTP has been sent.",
            "challenge_id": str(challenge.pk),
            "expires_in_seconds": max(0, int((challenge.expires_at - challenge.created_at).total_seconds())),
            "resend_available_in_seconds": max(0, int((challenge.resend_available_at - challenge.created_at).total_seconds())),
        }, status=201 if self.action == "otp_request" else 200)


class MobileOTPVerifyView(AccountResponseMixin, APIView):
    permission_classes = [AllowAny]
    authentication_classes = []
    throttle_classes = [AuthIPThrottle, AuthIdentityThrottle]
    action = "otp_verify"

    def post(self, request):
        serializer = OTPVerifySerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        try:
            user, is_new, tokens = MobileOTPService.verify(**serializer.validated_data)
        except OTPFlowError as exc:
            return Response({"success": False, "code": exc.code, "message": exc.message}, status=exc.status_code)
        return Response({"success": True, "is_new_user": is_new, **tokens, "user": UserSummarySerializer(user).data})
