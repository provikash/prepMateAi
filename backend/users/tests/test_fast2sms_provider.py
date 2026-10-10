from unittest.mock import Mock, patch

import requests
from django.test import SimpleTestCase, override_settings

from users.services.providers import OTPProviderError
from users.services.providers.fast2sms import Fast2SMSProvider


@override_settings(
    FAST2SMS_API_KEY="test-api-key",
    FAST2SMS_OTP_ID="test-otp-id",
    OTP_LENGTH=6,
    OTP_EXPIRY_SECONDS=600,
    FAST2SMS_CONNECT_TIMEOUT_SECONDS=5,
    FAST2SMS_REQUEST_TIMEOUT_SECONDS=10,
)
class Fast2SMSProviderTests(SimpleTestCase):
    @patch("users.services.providers.fast2sms.requests.post")
    def test_send_otp_uses_smart_otp_api(self, post):
        response = Mock(status_code=200, content=b"{}")
        response.json.return_value = {
            "return": True,
            "request_id": "fast2sms-request-id",
        }
        post.return_value = response

        result = Fast2SMSProvider().send_otp(
            "+919876543210",
            "123456",
            {"challenge_id": "challenge-123"},
        )

        post.assert_called_once_with(
            "https://www.fast2sms.com/dev/otp/send",
            json={
                "mobile": "9876543210",
                "otp_id": "test-otp-id",
                "otp": "123456",
                "otp_length": 6,
                "otp_expiry": 10,
                "udf1": "challenge-123",
            },
            headers={"Authorization": "test-api-key", "Accept": "application/json"},
            timeout=(5, 10),
        )
        self.assertEqual(result.message_id, "fast2sms-request-id")
        self.assertEqual(result.status, "accepted")

    @patch("users.services.providers.fast2sms.requests.post")
    def test_provider_rejection_is_not_treated_as_success(self, post):
        response = Mock(status_code=200, content=b"{}")
        response.json.return_value = {"return": False, "message": "Rejected"}
        post.return_value = response

        with self.assertRaises(OTPProviderError):
            Fast2SMSProvider().send_otp("+919876543210", "123456")

    @patch("users.services.providers.fast2sms.requests.post")
    def test_ambiguous_response_is_not_treated_as_success(self, post):
        response = Mock(status_code=200, content=b"{}")
        response.json.return_value = {"message": "Unknown response"}
        post.return_value = response

        with self.assertRaises(OTPProviderError):
            Fast2SMSProvider().send_otp("+919876543210", "123456")

    @patch("users.services.providers.fast2sms.requests.post")
    def test_network_error_is_redacted(self, post):
        post.side_effect = requests.Timeout("sensitive provider detail")

        with self.assertRaisesRegex(OTPProviderError, "temporarily unavailable"):
            Fast2SMSProvider().send_otp("+919876543210", "123456")

    @override_settings(FAST2SMS_API_KEY="")
    def test_missing_configuration_fails_before_network_call(self):
        with self.assertRaisesRegex(OTPProviderError, "not configured"):
            Fast2SMSProvider().send_otp("+919876543210", "123456")
