from datetime import timedelta
from unittest.mock import patch

from django.core.cache import cache
from django.db import IntegrityError, transaction
from django.test import TestCase, override_settings
from django.utils import timezone
from rest_framework.test import APIClient

from users.checks import authentication_policy_checks
from users.models import OTPChallenge, User
from users.services.phone_service import InvalidPhoneNumber, normalize_indian_phone
from users.services.providers import OTPProviderError


@override_settings(
    OTP_PROVIDER="console",
    OTP_MAX_ISSUES_PER_WINDOW=50,
    OTP_DAILY_LIMIT=100,
    OTP_IP_HOURLY_LIMIT=100,
    OTP_DEVICE_HOURLY_LIMIT=100,
    OTP_GLOBAL_HOURLY_LIMIT=1000,
    AUTH_THROTTLE_RATES={"otp_request": "100/min", "otp_resend": "100/min", "otp_verify": "100/min", "refresh": "100/min", "logout": "100/min", "me": "100/min"},
)
class MobileAuthenticationTests(TestCase):
    phone = "9876543210"
    otp = "777777"

    def setUp(self):
        cache.clear()
        self.client = APIClient()

    def request_otp(self, phone=None):
        with patch("users.services.mobile_otp_service.secrets.choice", return_value="7"):
            return self.client.post("/api/v1/auth/otp/request/", {"phone_number": phone or self.phone}, format="json")

    def verify(self, challenge_id, phone=None, otp=None):
        return self.client.post("/api/v1/auth/otp/verify/", {"challenge_id": challenge_id, "phone_number": phone or self.phone, "otp": otp or self.otp}, format="json")

    def test_indian_phone_normalization(self):
        for value in ("9876543210", "+919876543210", "919876543210", "09876543210", "98765 43210", "98765-43210"):
            self.assertEqual(normalize_indian_phone(value), "+919876543210")
        for value in ("", "+14155552671", "5123456789", "0112345678", "987654321", "98765432100", "98765x4321"):
            with self.assertRaises(InvalidPhoneNumber):
                normalize_indian_phone(value)

    def test_request_creates_hashed_challenge_without_leaking_otp(self):
        response = self.request_otp()
        self.assertEqual(response.status_code, 201, response.data)
        challenge = OTPChallenge.objects.get(pk=response.data["challenge_id"])
        self.assertNotEqual(challenge.otp_hash, self.otp)
        self.assertNotIn(self.otp, str(response.data))
        self.assertEqual(challenge.phone_number, "+919876543210")

    def test_new_and_existing_login_are_one_flow_and_otp_is_single_use(self):
        first = self.request_otp().data["challenge_id"]
        response = self.verify(first)
        self.assertEqual(response.status_code, 200, response.data)
        self.assertTrue(response.data["is_new_user"])
        self.assertIn("access", response.data)
        user = User.objects.get(phone_number="+919876543210")
        self.assertFalse(user.has_usable_password())
        self.assertTrue(user.is_phone_verified)
        self.assertEqual(self.verify(first).data["code"], "challenge_consumed")
        second = self.request_otp().data["challenge_id"]
        response = self.verify(second)
        self.assertFalse(response.data["is_new_user"])
        self.assertEqual(User.objects.filter(phone_number=user.phone_number).count(), 1)

    def test_invalid_expired_and_max_attempts(self):
        challenge_id = self.request_otp().data["challenge_id"]
        response = self.verify(challenge_id, otp="111111")
        self.assertEqual((response.status_code, response.data["code"]), (401, "otp_invalid"))
        for _ in range(4):
            response = self.verify(challenge_id, otp="111111")
        self.assertEqual(response.data["code"], "otp_attempts_exceeded")
        challenge_id = self.request_otp("8765432109").data["challenge_id"]
        OTPChallenge.objects.filter(pk=challenge_id).update(expires_at=timezone.now() - timedelta(seconds=1))
        response = self.verify(challenge_id, phone="8765432109")
        self.assertEqual(response.data["code"], "otp_expired")

    def test_resend_cooldown_and_invalidation(self):
        first = self.request_otp().data["challenge_id"]
        response = self.client.post("/api/v1/auth/otp/resend/", {"phone_number": self.phone, "challenge_id": first}, format="json")
        self.assertEqual((response.status_code, response.data["code"]), (429, "resend_not_available"))
        OTPChallenge.objects.filter(pk=first).update(resend_available_at=timezone.now() - timedelta(seconds=1))
        with patch("users.services.mobile_otp_service.secrets.choice", return_value="7"):
            response = self.client.post("/api/v1/auth/otp/resend/", {"phone_number": self.phone, "challenge_id": first}, format="json")
        self.assertEqual(response.status_code, 200, response.data)
        self.assertNotEqual(response.data["challenge_id"], first)
        self.assertIsNotNone(OTPChallenge.objects.get(pk=first).invalidated_at)

    def test_provider_failure_rolls_back_and_is_redacted(self):
        with patch("users.services.mobile_otp_service.get_otp_provider") as factory:
            factory.return_value.send_otp.side_effect = OTPProviderError("secret-provider-detail")
            response = self.request_otp()
        self.assertEqual((response.status_code, response.data["code"]), (503, "provider_unavailable"))
        self.assertNotIn("secret-provider-detail", str(response.data))
        self.assertFalse(OTPChallenge.objects.exists())

    def test_disabled_account_optional_email_refresh_logout_and_old_routes(self):
        user = User.objects.create_mobile_user("+919876543210", email=None, is_active=False)
        challenge_id = self.request_otp().data["challenge_id"]
        self.assertEqual(self.verify(challenge_id).data["code"], "account_disabled")
        user.is_active = True
        user.save(update_fields=["is_active"])
        challenge_id = self.request_otp().data["challenge_id"]
        login = self.verify(challenge_id)
        refresh = login.data["refresh"]
        rotated = self.client.post("/api/v1/auth/token/refresh/", {"refresh": refresh}, format="json")
        self.assertEqual(rotated.status_code, 200, rotated.data)
        self.client.credentials(HTTP_AUTHORIZATION="Bearer " + login.data["access"])
        logout = self.client.post("/api/v1/auth/logout/", {"refresh": rotated.data["refresh"]}, format="json")
        self.assertEqual(logout.status_code, 200, logout.data)
        for path in ("login", "register", "google", "password-reset/request"):
            self.assertEqual(self.client.post(f"/api/v1/auth/{path}/", {}, format="json").status_code, 404)

    def test_database_phone_uniqueness_and_phone_not_patchable(self):
        User.objects.create_mobile_user("+919876543210")
        with self.assertRaises(IntegrityError), transaction.atomic():
            User.objects.create_mobile_user("+919876543210")
        challenge_id = self.request_otp("8765432109").data["challenge_id"]
        login = self.verify(challenge_id, phone="8765432109")
        self.client.credentials(HTTP_AUTHORIZATION="Bearer " + login.data["access"])
        response = self.client.patch("/api/v1/auth/me/", {"phone_number": "+919999999999"}, format="json")
        self.assertEqual(response.status_code, 400)

    @override_settings(ENABLE_TEST_OTP_LOGIN=True, DJANGO_ENV="production", DEBUG=False)
    def test_test_otp_configuration_is_rejected_in_production(self):
        self.assertTrue(any(error.id == "users.E003" for error in authentication_policy_checks(None)))

    @override_settings(
        ENABLE_TEST_OTP_LOGIN=True,
        DJANGO_ENV="test",
        DEBUG=True,
        TEST_OTP_PHONE_NUMBERS={"+919999999999"},
        TEST_OTP_CODE="864209",
    )
    def test_allowlisted_test_otp_only_works_in_debug_test_environment(self):
        response = self.client.post("/api/v1/auth/otp/request/", {"phone_number": "9999999999"}, format="json")
        self.assertEqual(response.status_code, 201, response.data)
        challenge = OTPChallenge.objects.get(pk=response.data["challenge_id"])
        self.assertEqual(challenge.provider_message_id, "test")
        login = self.verify(challenge.pk, phone="9999999999", otp="864209")
        self.assertEqual(login.status_code, 200, login.data)
