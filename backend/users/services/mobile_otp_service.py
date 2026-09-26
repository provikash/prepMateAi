import hashlib
import logging
import secrets
from datetime import timedelta

from django.conf import settings
from django.contrib.auth.hashers import check_password, make_password
from django.core.cache import cache
from django.db import IntegrityError, transaction
from django.utils import timezone
from django.views.decorators.debug import sensitive_variables

from users.models import OTPChallenge, User
from .phone_service import mask_phone
from .providers import OTPProviderError, ProviderResult, get_otp_provider

logger = logging.getLogger(__name__)


class OTPFlowError(Exception):
    def __init__(self, code, message, status_code=400):
        self.code, self.message, self.status_code = code, message, status_code
        super().__init__(message)


def _digest(value):
    return hashlib.sha256((value or "").encode()).hexdigest() if value else ""


def _bump(key, limit, timeout):
    cache.add(key, 0, timeout=timeout)
    try:
        count = cache.incr(key)
    except ValueError:
        cache.set(key, 1, timeout=timeout)
        count = 1
    if count > limit:
        raise OTPFlowError("otp_rate_limited", "Too many OTP requests. Please try again later.", 429)


class MobileOTPService:
    @staticmethod
    @sensitive_variables("code")
    def issue(phone_number, request_ip="", device_id="", previous_challenge=None):
        now = timezone.now()
        is_test_account = bool(settings.ENABLE_TEST_OTP_LOGIN and phone_number in settings.TEST_OTP_PHONE_NUMBERS)
        if not is_test_account:
            phone_hash = _digest(phone_number)
            _bump(f"otp:phone:{phone_hash}", settings.OTP_MAX_ISSUES_PER_WINDOW, settings.OTP_ISSUE_WINDOW_SECONDS)
            _bump(f"otp:daily:{phone_hash}", settings.OTP_DAILY_LIMIT, 86400)
            if request_ip:
                _bump(f"otp:ip:{_digest(request_ip)}", settings.OTP_IP_HOURLY_LIMIT, 3600)
            if device_id:
                _bump(f"otp:device:{_digest(device_id)}", settings.OTP_DEVICE_HOURLY_LIMIT, 3600)
            _bump("otp:global", settings.OTP_GLOBAL_HOURLY_LIMIT, 3600)

        if previous_challenge:
            previous = OTPChallenge.objects.filter(pk=previous_challenge, phone_number=phone_number).first()
            if not previous:
                raise OTPFlowError("challenge_not_found", "OTP challenge was not found.")
            if not is_test_account:
                seconds = int((previous.resend_available_at - now).total_seconds())
                if seconds > 0:
                    raise OTPFlowError("resend_not_available", f"You can request another OTP in {seconds} seconds.", 429)

        code = "".join(secrets.choice("0123456789") for _ in range(settings.OTP_LENGTH))
        if is_test_account:
            code = settings.TEST_OTP_CODE

        try:
            with transaction.atomic():
                OTPChallenge.objects.select_for_update().filter(
                    phone_number=phone_number,
                    purpose=OTPChallenge.Purpose.AUTHENTICATION,
                    consumed_at__isnull=True,
                    invalidated_at__isnull=True,
                ).update(invalidated_at=now)
                challenge = OTPChallenge.objects.create(
                    phone_number=phone_number,
                    otp_hash=make_password(code),
                    expires_at=now + timedelta(seconds=settings.OTP_EXPIRY_SECONDS),
                    resend_available_at=now + timedelta(seconds=settings.OTP_RESEND_COOLDOWN_SECONDS),
                    maximum_attempts=settings.OTP_MAX_ATTEMPTS,
                    request_ip_hash=_digest(request_ip),
                    device_id_hash=_digest(device_id),
                    provider_status="pending",
                )
                if settings.ENABLE_TEST_OTP_LOGIN and phone_number in settings.TEST_OTP_PHONE_NUMBERS:
                    result = ProviderResult(message_id="test", status="accepted")
                else:
                    result = get_otp_provider().send_otp(phone_number, code, {"challenge_id": str(challenge.pk)})
                challenge.provider_message_id = result.message_id
                challenge.provider_status = result.status
                challenge.save(update_fields=["provider_message_id", "provider_status"])
        except OTPProviderError as exc:
            logger.warning("otp_request_failed phone=%s", mask_phone(phone_number))
            raise OTPFlowError("provider_unavailable", "We could not send an OTP right now. Please try again.", 503) from exc
        except IntegrityError as exc:
            raise OTPFlowError("otp_rate_limited", "An OTP request is already in progress.", 429) from exc
        logger.info("otp_request_succeeded phone=%s challenge=%s", mask_phone(phone_number), challenge.pk)
        return challenge

    @staticmethod
    @sensitive_variables("otp")
    def verify(challenge_id, phone_number, otp):
        result = None
        with transaction.atomic():
            challenge = OTPChallenge.objects.select_for_update().filter(pk=challenge_id).first()
            now = timezone.now()
            if not challenge or challenge.phone_number != phone_number:
                result = OTPFlowError("challenge_not_found", "OTP challenge was not found.", 401)
            elif challenge.consumed_at:
                result = OTPFlowError("challenge_consumed", "This OTP has already been used.", 401)
            elif challenge.invalidated_at:
                result = OTPFlowError("challenge_not_found", "This OTP challenge is no longer active.", 401)
            elif challenge.expires_at <= now:
                challenge.invalidated_at = now
                challenge.save(update_fields=["invalidated_at"])
                result = OTPFlowError("otp_expired", "This OTP has expired.", 401)
            elif challenge.attempts >= challenge.maximum_attempts:
                result = OTPFlowError("otp_attempts_exceeded", "Too many incorrect attempts. Request a new OTP.", 401)
            else:
                challenge.attempts += 1
                if not check_password(otp, challenge.otp_hash):
                    fields = ["attempts"]
                    code = "otp_invalid"
                    message = "The OTP is incorrect."
                    if challenge.attempts >= challenge.maximum_attempts:
                        challenge.invalidated_at = now
                        fields.append("invalidated_at")
                        code = "otp_attempts_exceeded"
                        message = "Too many incorrect attempts. Request a new OTP."
                    challenge.save(update_fields=fields)
                    result = OTPFlowError(code, message, 401)
                else:
                    challenge.consumed_at = now
                    challenge.save(update_fields=["attempts", "consumed_at"])
                    user = User.objects.select_for_update().filter(phone_number=phone_number).first()
                    is_new = user is None
                    if is_new:
                        user = User.objects.create_mobile_user(phone_number)
                    if not user.is_active or user.deleted_at:
                        raise OTPFlowError("account_disabled", "This account is disabled.", 403)
                    user.is_phone_verified = True
                    user.phone_verified_at = now
                    user.save(update_fields=["is_phone_verified", "phone_verified_at", "updated_at"])
                    OTPChallenge.objects.filter(phone_number=phone_number, purpose=OTPChallenge.Purpose.AUTHENTICATION, consumed_at__isnull=True, invalidated_at__isnull=True).update(invalidated_at=now)
        if result:
            logger.info("otp_verification_failed phone=%s code=%s", mask_phone(phone_number), result.code)
            raise result
        from .auth import AuthService
        logger.info("otp_verification_succeeded phone=%s", mask_phone(phone_number))
        return user, is_new, AuthService.issue_tokens(user)
