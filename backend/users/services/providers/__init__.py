from .base import OTPProviderError, ProviderResult
from .console import ConsoleOTPProvider
from .fast2sms import Fast2SMSProvider


def get_otp_provider():
    from django.conf import settings

    if settings.OTP_PROVIDER == "fast2sms":
        return Fast2SMSProvider()
    return ConsoleOTPProvider()


__all__ = ["OTPProviderError", "ProviderResult", "get_otp_provider"]
