import re
from datetime import timedelta
from unittest.mock import patch
from django.core import mail
from django.core.cache import cache
from django.db import IntegrityError, transaction
from django.test import TestCase, override_settings
from django.utils import timezone
from rest_framework.test import APIClient
from rest_framework_simplejwt.tokens import RefreshToken, AccessToken
from users.models import User, UserProfile, EmailOTP
from users.services.auth import AuthService
from users.services.otp_service import OTPService

PASSWORD = "Str0ng!Forest-Cloud942"
NEW_PASSWORD = "An0ther!River-Stone821"


class AccountTestSupport(TestCase):
    def setUp(self):
        cache.clear()
        self.client = APIClient()

    def user(self, **kwargs):
        return User.objects.create_user(email=kwargs.pop("email", "person@example.com"), password=PASSWORD, **kwargs)

    def post(self, path, data):
        return self.client.post("/api/v1/" + path + "/", data, format="json")

    def code(self):
        return re.search(r"code is (\d+)", mail.outbox[-1].body).group(1)

    def login(self, user=None):
        user = user or self.user(is_verified=True)
        tokens = AuthService.issue_tokens(user)
        self.client.credentials(HTTP_AUTHORIZATION="Bearer " + tokens["access"])
        return user, tokens


class AccountTests(AccountTestSupport):
    def test_manager_hash_normalization_profile_and_superuser(self):
        user = self.user(email=" PERSON@Example.COM ")
        self.assertEqual(user.email, "person@example.com")
        self.assertTrue(user.check_password(PASSWORD))
        self.assertNotEqual(user.password, PASSWORD)
        self.assertEqual(user.profile.user_id, user.pk)
        admin = User.objects.create_superuser("admin@example.com", PASSWORD)
        self.assertTrue(admin.is_staff and admin.is_superuser)
        for kwargs in ({"is_staff": False}, {"is_superuser": False}):
            with self.assertRaises(ValueError):
                User.objects.create_superuser("bad@example.com", PASSWORD, **kwargs)
        for email, password in (("", PASSWORD), ("x@example.com", None), ("x@example.com", "")):
            with self.assertRaises(ValueError):
                User.objects.create_user(email, password)

    def test_case_insensitive_database_constraint(self):
        self.user()
        with self.assertRaises(IntegrityError), transaction.atomic():
            User.objects.bulk_create([User(email="PERSON@example.com", username="other", name="Other")])

    def test_registration_target_and_legacy(self):
        for email, names in (("first@example.com", {"first_name": "First", "last_name": "User"}), ("second@example.com", {"name": "Second", "password_confirm": PASSWORD})):
            response = self.post("auth/register", {"email": email, "password": PASSWORD, **names})
            self.assertEqual(response.status_code, 201, response.data)
            self.assertNotIn("tokens", response.data)
            self.assertNotIn(self.code(), str(response.data))
            self.assertNotIn(PASSWORD, str(response.data))
            user = User.objects.get(email=email)
            self.assertFalse(user.is_verified)
            self.assertTrue(UserProfile.objects.filter(user=user).exists())
            self.assertNotEqual(user.email_otps.get().code_hash, self.code())

    def test_registration_validation(self):
        for data in ({}, {"email": "bad", "password": PASSWORD}, {"email": "a@example.com", "password": "123"}, {"email": "a@example.com", "password": PASSWORD, "is_staff": True}, {"email": "a@example.com", "password": PASSWORD, "password_confirm": "wrong"}):
            cache.clear()
            self.assertEqual(self.post("auth/register", data).status_code, 400)
        self.user()
        cache.clear()
        self.assertEqual(self.post("auth/register", {"email": "PERSON@example.com", "password": PASSWORD}).status_code, 400)

    @patch("users.services.email_service.send_mail", side_effect=RuntimeError("private-provider-secret"))
    def test_registration_email_failure_rolls_back(self, mocked):
        response = self.post("auth/register", {"email": "a@example.com", "password": PASSWORD})
        self.assertEqual(response.status_code, 503)
        self.assertFalse(User.objects.exists())
        self.assertNotIn("private-provider-secret", str(response.data))

    def test_verify_login_me_refresh_logout(self):
        user = self.user()
        self.assertEqual(self.post("auth/login", {"email": user.email, "password": PASSWORD}).status_code, 401)
        OTPService.issue(user, EmailOTP.Purpose.EMAIL_VERIFICATION)
        code = self.code()
        self.assertEqual(self.post("auth/verify-email", {"email": user.email, "otp": code}).status_code, 200)
        self.assertEqual(self.post("auth/verify-email", {"email": user.email, "otp": code}).status_code, 400)
        response = self.post("auth/login", {"email": user.email.upper(), "password": PASSWORD})
        self.assertEqual(response.status_code, 200, response.data)
        tokens = response.data["tokens"]
        self.client.credentials(HTTP_AUTHORIZATION="Bearer " + tokens["access"])
        self.assertEqual(self.client.get("/api/v1/auth/me/").data["data"]["id"], user.pk)
        refreshed = self.post("auth/token/refresh", {"refresh": tokens["refresh"]})
        self.assertEqual(refreshed.status_code, 200, refreshed.data)
        self.assertEqual(self.post("auth/refresh", {"refresh": tokens["refresh"]}).status_code, 401)
        self.assertEqual(self.post("auth/logout", {"refresh": refreshed.data["refresh"]}).status_code, 200)
        self.assertEqual(self.post("auth/refresh", {"refresh": refreshed.data["refresh"]}).status_code, 401)

    def test_invalid_expired_and_inactive_tokens(self):
        user, tokens = self.login()
        for token in ("bad", str(AccessToken.for_user(user))):
            self.assertEqual(self.post("auth/refresh", {"refresh": token}).status_code, 401)
        expired = RefreshToken.for_user(user)
        expired.set_exp(lifetime=timedelta(seconds=-1))
        self.assertEqual(self.post("auth/refresh", {"refresh": str(expired)}).status_code, 401)
        access = AccessToken.for_user(user)
        access.set_exp(lifetime=timedelta(seconds=-1))
        self.client.credentials(HTTP_AUTHORIZATION="Bearer " + str(access))
        self.assertEqual(self.client.get("/api/v1/auth/me/").status_code, 401)
        user.is_active = False
        user.save()
        self.client.credentials(HTTP_AUTHORIZATION="Bearer " + tokens["access"])
        self.assertEqual(self.client.get("/api/v1/auth/me/").status_code, 401)
        self.assertEqual(self.post("auth/refresh", {"refresh": tokens["refresh"]}).status_code, 401)
        self.assertEqual(self.post("auth/login", {"email": user.email, "password": PASSWORD}).status_code, 401)

    def test_otp_wrong_purpose_expiry_attempts(self):
        user = self.user()
        OTPService.issue(user, EmailOTP.Purpose.EMAIL_VERIFICATION)
        code = self.code()
        self.assertEqual(self.post("auth/password-reset/confirm", {"email": user.email, "otp": code, "new_password": NEW_PASSWORD}).status_code, 400)
        otp = user.email_otps.get()
        otp.expires_at = timezone.now() - timedelta(seconds=1)
        otp.save()
        self.assertEqual(self.post("auth/verify-email", {"email": user.email, "otp": code}).status_code, 400)
        otp.expires_at = timezone.now() + timedelta(minutes=5)
        otp.save()
        wrong = "000000" if code != "000000" else "111111"
        for _ in range(5):
            self.assertEqual(self.post("auth/verify-email", {"email": user.email, "otp": wrong}).status_code, 400)
        otp.refresh_from_db()
        self.assertEqual(otp.attempt_count, 5)
        self.assertTrue(otp.is_used)
        self.assertEqual(self.post("auth/verify-email", {"email": user.email, "otp": code}).status_code, 400)

    def test_resend_cooldown_and_previous_invalidated(self):
        user = self.user()
        OTPService.issue(user, EmailOTP.Purpose.EMAIL_VERIFICATION)
        first = user.email_otps.get()
        self.assertFalse(OTPService.issue(user, EmailOTP.Purpose.EMAIL_VERIFICATION))
        first.created_at -= timedelta(seconds=61)
        first.save()
        self.assertTrue(OTPService.issue(user, EmailOTP.Purpose.EMAIL_VERIFICATION))
        first.refresh_from_db()
        self.assertTrue(first.is_used)
        self.assertEqual(user.email_otps.filter(is_used=False).count(), 1)

    def test_reset_generic_and_password_revocation(self):
        user, tokens = self.login()
        known = self.post("auth/password-reset/request", {"email": user.email})
        code = self.code()
        unknown = self.post("auth/password-reset/request", {"email": "absent@example.com"})
        self.assertEqual(known.data, unknown.data)
        response = self.post("auth/password-reset/confirm", {"email": user.email, "otp": code, "new_password": NEW_PASSWORD})
        self.assertEqual(response.status_code, 200, response.data)
        user.refresh_from_db()
        self.assertTrue(user.check_password(NEW_PASSWORD))
        self.assertEqual(self.client.get("/api/v1/auth/me/").status_code, 401)
        self.assertEqual(self.post("auth/refresh", {"refresh": tokens["refresh"]}).status_code, 401)
        self.assertEqual(self.post("auth/password-reset/confirm", {"email": user.email, "otp": code, "new_password": PASSWORD}).status_code, 400)

    def test_password_change_confirmation_and_revocation(self):
        user, tokens = self.login()
        for current, new in (("wrong", NEW_PASSWORD), (PASSWORD, PASSWORD), (PASSWORD, "123")):
            self.assertEqual(self.post("auth/change-password", {"current_password": current, "new_password": new}).status_code, 400)
        self.assertEqual(self.post("auth/change-password", {"current_password": PASSWORD, "new_password": NEW_PASSWORD}).status_code, 200)
        self.assertEqual(self.client.get("/api/v1/auth/me/").status_code, 401)
        self.assertEqual(self.post("auth/refresh", {"refresh": tokens["refresh"]}).status_code, 401)

    def test_profile_ownership_aliases_and_validation(self):
        other = self.user(email="other@example.com", is_verified=True)
        user, _ = self.login()
        self.assertEqual(self.client.get("/api/v1/profile/").status_code, 200)
        response = self.client.patch("/api/v1/profile/", {"headline": "Developer", "linkedin_url": "https://linkedin.com/in/test", "portfolio_url": "https://example.com"}, format="json")
        self.assertEqual(response.status_code, 200, response.data)
        self.assertEqual(response.data["job_title"], "Developer")
        other.profile.refresh_from_db()
        self.assertEqual(other.profile.job_title, "")
        for data in ({"user": other.pk}, {"linkedin_url": "not-url"}, {"bio": "x" * 5001}, {"headline": "x", "job_title": "y"}):
            self.assertEqual(self.client.patch("/api/v1/profile/", data, format="json").status_code, 400)

    def test_anonymous_denied(self):
        for path in ("auth/me/", "profile/"):
            self.assertEqual(self.client.get("/api/v1/" + path).status_code, 401)
        for path in ("auth/change-password", "auth/deactivate", "auth/logout"):
            self.assertEqual(self.post(path, {}).status_code, 401)
        self.assertEqual(self.client.delete("/api/v1/auth/account/").status_code, 401)

    def test_logout_cannot_blacklist_other_user(self):
        user, _ = self.login()
        other = self.user(email="other@example.com", is_verified=True)
        tokens = AuthService.issue_tokens(other)
        self.assertEqual(self.post("auth/logout", {"refresh": tokens["refresh"]}).status_code, 400)
        self.assertEqual(self.post("auth/refresh", {"refresh": tokens["refresh"]}).status_code, 200)

    def test_deactivation(self):
        user, tokens = self.login()
        self.assertEqual(self.post("auth/deactivate", {"current_password": "wrong"}).status_code, 400)
        self.assertEqual(self.post("auth/deactivate", {"current_password": PASSWORD}).status_code, 200)
        user.refresh_from_db()
        self.assertFalse(user.is_active)
        self.assertIsNone(user.deleted_at)
        self.assertEqual(self.client.get("/api/v1/auth/me/").status_code, 401)
        self.assertEqual(self.post("auth/refresh", {"refresh": tokens["refresh"]}).status_code, 401)

    def test_soft_deletion_preserves_related_records(self):
        user, tokens = self.login()
        profile_id = user.profile.pk
        response = self.client.delete("/api/v1/auth/account/", {"current_password": PASSWORD}, format="json")
        self.assertEqual(response.status_code, 204)
        user.refresh_from_db()
        self.assertFalse(user.is_active)
        self.assertIsNotNone(user.deleted_at)
        self.assertTrue(UserProfile.objects.filter(pk=profile_id).exists())
        self.assertEqual(self.post("auth/refresh", {"refresh": tokens["refresh"]}).status_code, 401)

    @override_settings(AUTH_THROTTLE_RATES={"login": "2/min"})
    def test_login_rate_limit(self):
        for _ in range(2):
            self.assertEqual(self.post("auth/login", {"email": "absent@example.com", "password": "bad"}).status_code, 401)
        response = self.post("auth/login", {"email": "absent@example.com", "password": "bad"})
        self.assertEqual(response.status_code, 429)
        self.assertIn("Retry-After", response.headers)

    @patch("users.views.verify_google_id_token")
    def test_google_verified_and_inactive_policy(self, verify):
        verify.return_value = {"email": "google@example.com", "email_verified": False}
        self.assertEqual(self.post("auth/google", {"id_token": "mock"}).status_code, 400)
        verify.return_value["email_verified"] = True
        response = self.post("auth/google", {"id_token": "mock"})
        self.assertEqual(response.status_code, 200, response.data)
        user = User.objects.get(email="google@example.com")
        self.assertFalse(user.has_usable_password())
        user.is_active = False
        user.save()
        self.assertEqual(self.post("auth/google", {"id_token": "mock"}).status_code, 401)
