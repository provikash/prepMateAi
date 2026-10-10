from unittest.mock import patch

from django.core.cache import cache
from django.test import override_settings
from rest_framework.test import APITestCase

from resume.models import Resume
from users.models import OTPChallenge, User


@override_settings(
    OTP_PROVIDER="console",
    OTP_MAX_ISSUES_PER_WINDOW=50,
    OTP_DAILY_LIMIT=100,
    OTP_IP_HOURLY_LIMIT=100,
    OTP_DEVICE_HOURLY_LIMIT=100,
    OTP_GLOBAL_HOURLY_LIMIT=1000,
    AUTH_THROTTLE_RATES={
        "otp_request": "100/min",
        "otp_verify": "100/min",
        "account_action_request": "100/min",
        "account_deactivate": "100/min",
        "account_delete": "100/min",
        "phone_change_request": "100/min",
        "phone_change_verify": "100/min",
        "logout_all": "100/min",
        "refresh": "100/min",
        "me": "100/min",
    },
)
class AccountLifecycleTests(APITestCase):
    phone = "9876543210"
    normalized_phone = "+919876543210"
    otp = "777777"

    def setUp(self):
        cache.clear()
        self.tokens = self._login(self.phone)
        self.user = User.objects.get(phone_number=self.normalized_phone)
        self.client.credentials(
            HTTP_AUTHORIZATION="Bearer " + self.tokens["access"]
        )

    def _request_otp(self, phone):
        with patch(
            "users.services.mobile_otp_service.secrets.choice", return_value="7"
        ):
            return self.client.post(
                "/api/v1/auth/otp/request/",
                {"phone_number": phone},
                format="json",
            )

    def _login(self, phone):
        self.client.credentials()
        challenge = self._request_otp(phone)
        self.assertEqual(challenge.status_code, 201, challenge.data)
        response = self.client.post(
            "/api/v1/auth/otp/verify/",
            {
                "phone_number": phone,
                "challenge_id": challenge.data["challenge_id"],
                "otp": self.otp,
            },
            format="json",
        )
        self.assertEqual(response.status_code, 200, response.data)
        return response.data

    def _request_account_action(self, action):
        with patch(
            "users.services.mobile_otp_service.secrets.choice", return_value="7"
        ):
            response = self.client.post(
                "/api/v1/auth/account/verification/request/",
                {"action": action},
                format="json",
            )
        self.assertEqual(response.status_code, 201, response.data)
        return response.data["challenge_id"]

    def test_logout_all_immediately_revokes_access_and_refresh_tokens(self):
        response = self.client.post("/api/v1/auth/logout-all/", {}, format="json")
        self.assertEqual(response.status_code, 200, response.data)
        self.assertTrue(response.data["authentication_revoked"])

        self.assertEqual(self.client.get("/api/v1/auth/me/").status_code, 401)
        self.client.credentials()
        refresh = self.client.post(
            "/api/v1/auth/token/refresh/",
            {"refresh": self.tokens["refresh"]},
            format="json",
        )
        self.assertEqual(refresh.status_code, 401, refresh.data)

    def test_change_phone_requires_new_phone_otp_and_revokes_sessions(self):
        new_phone = "8765432109"
        with patch(
            "users.services.mobile_otp_service.secrets.choice", return_value="7"
        ):
            requested = self.client.post(
                "/api/v1/auth/phone/change/request/",
                {"phone_number": new_phone},
                format="json",
            )
        self.assertEqual(requested.status_code, 201, requested.data)

        changed = self.client.post(
            "/api/v1/auth/phone/change/verify/",
            {
                "phone_number": new_phone,
                "challenge_id": requested.data["challenge_id"],
                "otp": self.otp,
            },
            format="json",
        )
        self.assertEqual(changed.status_code, 200, changed.data)
        self.user.refresh_from_db()
        self.assertEqual(self.user.phone_number, "+918765432109")
        self.assertEqual(self.client.get("/api/v1/auth/me/").status_code, 401)

    def test_change_phone_rejects_number_owned_by_another_account(self):
        User.objects.create_mobile_user("+918765432109")
        response = self.client.post(
            "/api/v1/auth/phone/change/request/",
            {"phone_number": "8765432109"},
            format="json",
        )
        self.assertEqual(response.status_code, 400, response.data)
        self.assertIn("phone_number", response.data)

    def test_deactivate_revokes_tokens_and_verified_login_reactivates(self):
        challenge_id = self._request_account_action("deactivate")
        response = self.client.post(
            "/api/v1/auth/account/deactivate/",
            {"challenge_id": challenge_id, "otp": self.otp},
            format="json",
        )
        self.assertEqual(response.status_code, 200, response.data)
        self.user.refresh_from_db()
        self.assertFalse(self.user.is_active)
        self.assertIsNotNone(self.user.deactivated_at)
        self.assertEqual(self.client.get("/api/v1/auth/me/").status_code, 401)

        tokens = self._login(self.phone)
        self.assertIn("access", tokens)
        self.user.refresh_from_db()
        self.assertTrue(self.user.is_active)
        self.assertIsNone(self.user.deactivated_at)

    def test_admin_disabled_account_is_not_reactivated_by_login(self):
        self.user.is_active = False
        self.user.deactivated_at = None
        self.user.save(update_fields=["is_active", "deactivated_at"])
        self.client.credentials()
        challenge = self._request_otp(self.phone)
        response = self.client.post(
            "/api/v1/auth/otp/verify/",
            {
                "phone_number": self.phone,
                "challenge_id": challenge.data["challenge_id"],
                "otp": self.otp,
            },
            format="json",
        )
        self.assertEqual(response.status_code, 403, response.data)
        self.assertEqual(response.data["code"], "account_disabled")

    def test_action_challenge_cannot_authorize_a_different_action(self):
        challenge_id = self._request_account_action("deactivate")
        response = self.client.delete(
            "/api/v1/auth/account/",
            {"challenge_id": challenge_id, "otp": self.otp},
            format="json",
        )
        self.assertEqual(response.status_code, 401, response.data)
        self.assertEqual(response.data["code"], "challenge_not_found")
        self.assertIsNone(OTPChallenge.objects.get(pk=challenge_id).consumed_at)

    def test_permanent_delete_removes_user_and_owned_database_data(self):
        Resume.objects.create(
            user=self.user,
            title="Delete me",
            data={"basics": {"name": "Private"}},
        )
        user_id = self.user.pk
        challenge_id = self._request_account_action("delete")
        response = self.client.delete(
            "/api/v1/auth/account/",
            {"challenge_id": challenge_id, "otp": self.otp},
            format="json",
        )
        self.assertEqual(response.status_code, 204, getattr(response, "data", None))
        self.assertFalse(User.objects.filter(pk=user_id).exists())
        self.assertFalse(Resume.objects.filter(user_id=user_id).exists())

