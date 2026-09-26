import logging
from .base import BaseOTPProvider, ProviderResult
from ..phone_service import mask_phone

logger = logging.getLogger(__name__)


class ConsoleOTPProvider(BaseOTPProvider):
    def send_otp(self, phone_number, otp, template_context=None):
        # Intentionally never log the OTP. Tests inspect the stored hash through fixtures.
        logger.info("otp_request_succeeded provider=console phone=%s", mask_phone(phone_number))
        return ProviderResult(message_id="console", status="accepted")
