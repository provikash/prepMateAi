from django.conf import settings
from django.core.mail import send_mail
from django.views.decorators.debug import sensitive_variables
from rest_framework.exceptions import APIException


class EmailDeliveryError(APIException):
    status_code = 503
    default_detail = "Email delivery is temporarily unavailable. Please try again later."


class EmailService:
    @staticmethod
    @sensitive_variables("code", "message")
    def send_otp(user, code, purpose):
        subject = "PrepMateAI email verification" if purpose == "EMAIL_VERIFICATION" else "PrepMateAI password reset"
        message = f"Your code is {code}. It expires in {settings.OTP_EXPIRY_SECONDS // 60} minutes. If you did not request it, ignore this email."
        try:
            sent = send_mail(subject, message, settings.DEFAULT_FROM_EMAIL, [user.email], fail_silently=False)
            if sent != 1:
                raise EmailDeliveryError()
        except Exception:
            raise EmailDeliveryError() from None
