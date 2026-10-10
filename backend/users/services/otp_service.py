import secrets
from datetime import timedelta
from django.conf import settings
from django.contrib.auth.hashers import check_password, make_password
from django.db import transaction
from django.utils import timezone
from django.views.decorators.debug import sensitive_variables
from users.models import EmailOTP, User
from .email_service import EmailService


class OTPService:
    @staticmethod
    @transaction.atomic
    @sensitive_variables("code")
    def issue(user, purpose):
        # Lock the parent even when no OTP exists, serializing concurrent resends.
        user = User.objects.select_for_update().get(pk=user.pk)
        if not user.is_active or user.deleted_at:
            return False
        if purpose == EmailOTP.Purpose.EMAIL_VERIFICATION and user.is_verified:
            return False
        now = timezone.now()
        previous = EmailOTP.objects.filter(user=user, purpose=purpose).order_by("-created_at", "-pk")
        latest = previous.first()
        if latest and (now - latest.created_at).total_seconds() < settings.OTP_RESEND_COOLDOWN_SECONDS:
            return False
        if previous.filter(created_at__gt=now - timedelta(seconds=settings.OTP_ISSUE_WINDOW_SECONDS)).count() >= settings.OTP_MAX_ISSUES:
            return False
        previous.filter(is_used=False).update(is_used=True)
        code = "".join(secrets.choice("0123456789") for _ in range(settings.OTP_LENGTH))
        EmailOTP.objects.create(user=user, purpose=purpose, code_hash=make_password(code), expires_at=now + timedelta(seconds=settings.OTP_EXPIRY_SECONDS))
        EmailService.send_otp(user, code, purpose)
        return True

    @staticmethod
    @sensitive_variables("code")
    def consume_locked(user, code, purpose):
        """Caller holds the user lock and commits failed attempts before raising errors."""
        otp = EmailOTP.objects.select_for_update().filter(user=user, purpose=purpose, is_used=False).first()
        if not otp or otp.expires_at <= timezone.now() or otp.attempt_count >= settings.OTP_MAX_ATTEMPTS:
            return False
        otp.attempt_count += 1
        valid = check_password(code, otp.code_hash)
        otp.is_used = valid or otp.attempt_count >= settings.OTP_MAX_ATTEMPTS
        otp.save(update_fields=["attempt_count", "is_used"])
        return valid
