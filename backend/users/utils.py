import logging
import random

from django.conf import settings
from django.core.mail import send_mail

logger = logging.getLogger(__name__)


def generate_otp() -> str:
    return str(random.randint(100000, 999999))


def send_otp_email(email: str, otp: str) -> int:
    subject = "Your OTP Verification Code"
    message = (
        "Hello,\n\n"
        f"Your OTP verification code is: {otp}\n"
        "This OTP is valid for 5 minutes.\n\n"
        "Thanks,\n"
        "PrepMateAi"
    )
    from_email = settings.DEFAULT_FROM_EMAIL or settings.EMAIL_HOST_USER

    # Raise SMTP/auth errors to caller so API can return a clear failure.
    return send_mail(subject, message, from_email, [email], fail_silently=False)


def resend_otp(email: str, purpose: str = "register") -> str:
    """Generate and send a new OTP. Persistence must be handled by the caller."""
    otp_code = generate_otp()
    send_otp_email(email, otp_code)
    logger.info("OTP email sent for purpose=%s to %s", purpose, email)
    return otp_code