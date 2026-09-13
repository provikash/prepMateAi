from concurrent.futures import ThreadPoolExecutor
from datetime import timedelta
from unittest import skipUnless
from unittest.mock import patch
from django.core.cache import cache
from django.db import connection, close_old_connections
from django.test import TransactionTestCase, override_settings
from django.utils import timezone
from rest_framework.test import APIClient
from users.models import User, EmailOTP
from users.services.otp_service import OTPService
from users.services.account_service import AccountService
from users.services.google_auth import GoogleTokenVerifier, GoogleTokenVerificationError
from .test_accounts import AccountTestSupport, PASSWORD, NEW_PASSWORD


class MoreSecurityTests(AccountTestSupport):
    def test_otp_issue_quota_across_ips(self):
        user = self.user()
        for _ in range(3):
            self.assertTrue(OTPService.issue(user, EmailOTP.Purpose.EMAIL_VERIFICATION))
            user.email_otps.update(created_at=timezone.now() - timedelta(seconds=61))
        self.assertFalse(OTPService.issue(user, EmailOTP.Purpose.EMAIL_VERIFICATION))

    def test_all_public_auth_routes_throttled(self):
        routes = {"auth/register": "register", "auth/verify-email": "verify", "auth/verify-email/resend": "resend", "auth/password-reset/request": "reset_request", "auth/password-reset/confirm": "reset_confirm", "auth/refresh": "refresh", "auth/google": "login"}
        for path, scope in routes.items():
            cache.clear()
            with override_settings(AUTH_THROTTLE_RATES={scope: "1/min"}):
                self.post(path, {"email": "absent@example.com"})
                self.assertEqual(self.post(path, {"email": "absent@example.com"}).status_code, 429, path)

    def test_reset_invalid_weak_and_inactive(self):
        user = self.user()
        OTPService.issue(user, EmailOTP.Purpose.PASSWORD_RESET)
        code = self.code()
        self.assertEqual(self.post("auth/password-reset/confirm", {"email": user.email, "otp": code, "new_password": "123"}).status_code, 400)
        self.assertFalse(user.email_otps.get().is_used)
        user.is_active = False
        user.save()
        self.assertEqual(self.post("auth/password-reset/confirm", {"email": user.email, "otp": code, "new_password": NEW_PASSWORD}).status_code, 400)

    @patch("users.services.email_service.send_mail", side_effect=RuntimeError("secret"))
    def test_resend_delivery_failure_generic(self, mocked):
        user = self.user()
        known = self.post("auth/password-reset/request", {"email": user.email})
        unknown = self.post("auth/password-reset/request", {"email": "absent@example.com"})
        self.assertEqual(known.data, unknown.data)
        self.assertFalse(EmailOTP.objects.exists())

    def test_invalid_json_shape_and_readonly_fields(self):
        self.assertEqual(self.post("auth/register", [{"email": "a@example.com"}]).status_code, 400)
        user, _ = self.login()
        self.assertEqual(self.client.patch("/api/v1/profile", {"is_verified": False}, format="json").status_code, 400)

    @patch("users.services.google_oauth.verify_google_id_token", side_effect=ValueError("invalid"))
    def test_legacy_google_helper_never_decodes_unsigned_token(self, mocked):
        with self.assertRaises(ValueError):
            GoogleTokenVerifier(client_id="test").verify_token("unsigned.fake.token")


@skipUnless(connection.vendor == "postgresql", "Row-lock concurrency requires PostgreSQL")
class OTPConcurrencyTests(TransactionTestCase):
    def setUp(self):
        cache.clear()
        self.user = User.objects.create_user("concurrent@example.com", PASSWORD)

    @patch("users.services.email_service.EmailService.send_otp")
    def test_concurrent_issue_creates_one_otp(self, send):
        def issue():
            close_old_connections()
            try:
                return OTPService.issue(User.objects.get(pk=self.user.pk), EmailOTP.Purpose.EMAIL_VERIFICATION)
            finally:
                close_old_connections()
        with ThreadPoolExecutor(max_workers=2) as pool:
            results = list(pool.map(lambda _: issue(), range(2)))
        self.assertEqual(sorted(results), [False, True])
        self.assertEqual(EmailOTP.objects.filter(is_used=False).count(), 1)

    @patch("users.services.email_service.EmailService.send_otp")
    def test_concurrent_verification_consumes_once(self, send):
        OTPService.issue(self.user, EmailOTP.Purpose.EMAIL_VERIFICATION)
        code = send.call_args.args[1]
        def verify():
            from rest_framework.exceptions import ValidationError
            close_old_connections()
            try:
                AccountService.verify(self.user.email, code, EmailOTP.Purpose.EMAIL_VERIFICATION)
                return True
            except ValidationError:
                return False
            finally:
                close_old_connections()
        with ThreadPoolExecutor(max_workers=2) as pool:
            results = list(pool.map(lambda _: verify(), range(2)))
        self.assertEqual(sorted(results), [False, True])
