import logging
import requests
from django.conf import settings
from django.views.decorators.debug import sensitive_variables

from core.monitoring import report_operational_failure
from .base import BaseOTPProvider, OTPProviderError, ProviderResult
from ..phone_service import mask_phone

logger = logging.getLogger(__name__)


class Fast2SMSProvider(BaseOTPProvider):
    endpoint = "https://www.fast2sms.com/dev/otp/send"

    @sensitive_variables("otp", "api_key")
    def send_otp(self, phone_number, otp, template_context=None):
        api_key = settings.FAST2SMS_API_KEY
        otp_id = settings.FAST2SMS_OTP_ID
        if not api_key or not otp_id:
            raise OTPProviderError("SMS provider is not configured.")
        payload = {
            "mobile": phone_number[-10:],
            "otp_id": otp_id,
            "otp": otp,
            "otp_length": settings.OTP_LENGTH,
            "otp_expiry": max(1, settings.OTP_EXPIRY_SECONDS // 60),
        }
        challenge_id = (template_context or {}).get("challenge_id")
        if challenge_id:
            # Fast2SMS returns udf1 in OTP webhooks, making delivery events
            # traceable without including a phone number or the OTP itself.
            payload["udf1"] = str(challenge_id)[:128]
        try:
            response = requests.post(
                self.endpoint,
                json=payload,
                headers={"Authorization": api_key, "Accept": "application/json"},
                timeout=(settings.FAST2SMS_CONNECT_TIMEOUT_SECONDS, settings.FAST2SMS_REQUEST_TIMEOUT_SECONDS),
            )
            data = response.json() if response.content else {}
        except (requests.RequestException, ValueError) as exc:
            logger.warning("provider_request_error provider=fast2sms phone=%s", mask_phone(phone_number))
            report_operational_failure(
                "provider_request_failed", provider="fast2sms", exception=exc,
                failure_type=type(exc).__name__,
            )
            raise OTPProviderError("SMS provider is temporarily unavailable.") from exc
        if response.status_code != 200 or not isinstance(data, dict) or data.get("return") is not True:
            logger.warning("otp_request_failed provider=fast2sms phone=%s status=%s", mask_phone(phone_number), response.status_code)
            report_operational_failure(
                "provider_response_failed", provider="fast2sms",
                status_code=response.status_code,
            )
            raise OTPProviderError("SMS provider rejected the request.")
        message_id = str(data.get("request_id") or data.get("message_id") or "")[:128]
        return ProviderResult(message_id=message_id, status="accepted")
