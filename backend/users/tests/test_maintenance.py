from datetime import timedelta

from django.core.management import call_command
from django.test import TestCase
from django.utils import timezone

from users.models import EmailOTP, OTPChallenge, User


class AuthenticationMaintenanceTests(TestCase):
    def test_cleanup_removes_only_records_older_than_retention(self):
        user = User.objects.create_user(
            email="maintenance@example.com", password="StrongPassword123!"
        )
        old = OTPChallenge.objects.create(
            phone_number="+919876543210",
            otp_hash="old",
            expires_at=timezone.now() - timedelta(days=10),
            resend_available_at=timezone.now(),
        )
        recent = OTPChallenge.objects.create(
            phone_number="+919876543211",
            otp_hash="recent",
            expires_at=timezone.now() - timedelta(days=1),
            resend_available_at=timezone.now(),
        )
        old_email = EmailOTP.objects.create(
            user=user,
            code_hash="old",
            purpose=EmailOTP.Purpose.EMAIL_VERIFICATION,
            expires_at=timezone.now() - timedelta(days=10),
        )

        call_command("cleanup_expired_otp", retention_days=7, apply=True)

        self.assertFalse(OTPChallenge.objects.filter(pk=old.pk).exists())
        self.assertTrue(OTPChallenge.objects.filter(pk=recent.pk).exists())
        self.assertFalse(EmailOTP.objects.filter(pk=old_email.pk).exists())
