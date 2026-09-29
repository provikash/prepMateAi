import hashlib
import hmac
import json
from unittest.mock import patch

from django.contrib.auth import get_user_model
from django.test import override_settings
from rest_framework.test import APITestCase

from ai.models import AICreditTransaction
from .models import PaymentOrder, PremiumSubscription


SETTINGS = dict(
    RAZORPAY_KEY_ID="rzp_test_key",
    RAZORPAY_KEY_SECRET="test-secret",
    RAZORPAY_WEBHOOK_SECRET="webhook-secret",
    RAZORPAY_PRODUCTS={
        "credits_100": {"name": "100 AI Credits", "amount": 4900, "credits": 100, "premium_days": 0},
        "premium_monthly": {"name": "Premium Monthly", "amount": 9900, "credits": 500, "premium_days": 30},
    },
)


@override_settings(**SETTINGS)
class BillingTests(APITestCase):
    def setUp(self):
        self.user = get_user_model().objects.create_mobile_user("+919876543210")
        self.client.force_authenticate(self.user)

    @patch("billing.views.RazorpayClient")
    def test_server_creates_order_from_its_own_catalog_price(self, client):
        client.return_value.create_order.return_value = {"id": "order_test"}
        response = self.client.post("/api/v1/billing/orders/", {"product_code": "credits_100", "amount": 1}, format="json")
        self.assertEqual(response.status_code, 201)
        order = PaymentOrder.objects.get()
        self.assertEqual(order.amount, 4900)
        client.return_value.create_order.assert_called_once()

    @patch("billing.views.RazorpayClient")
    def test_verify_grants_credits_once(self, client):
        order = PaymentOrder.objects.create(user=self.user, product_code="credits_100", amount=4900, currency="INR", credits=100, receipt="pm_test", razorpay_order_id="order_test")
        payment = {"id": "pay_test", "order_id": "order_test", "status": "captured", "amount": 4900, "currency": "INR"}
        client.return_value.fetch_payment.return_value = payment
        signature = hmac.new(b"test-secret", b"order_test|pay_test", hashlib.sha256).hexdigest()
        payload = {"razorpay_order_id": "order_test", "razorpay_payment_id": "pay_test", "razorpay_signature": signature}
        first = self.client.post("/api/v1/billing/orders/verify/", payload, format="json")
        second = self.client.post("/api/v1/billing/orders/verify/", payload, format="json")
        self.assertEqual(first.status_code, 200)
        self.assertEqual(second.status_code, 200)
        self.user.ai_credit_account.refresh_from_db()
        self.assertEqual(self.user.ai_credit_account.balance, 100)
        self.assertEqual(AICreditTransaction.objects.filter(transaction_type="PURCHASE").count(), 1)

    @patch("billing.views.RazorpayClient")
    def test_premium_payment_activates_access(self, client):
        PaymentOrder.objects.create(user=self.user, product_code="premium_monthly", amount=9900, currency="INR", credits=500, premium_days=30, receipt="pm_premium", razorpay_order_id="order_premium")
        client.return_value.fetch_payment.return_value = {"id": "pay_premium", "order_id": "order_premium", "status": "captured", "amount": 9900, "currency": "INR"}
        signature = hmac.new(b"test-secret", b"order_premium|pay_premium", hashlib.sha256).hexdigest()
        response = self.client.post("/api/v1/billing/orders/verify/", {"razorpay_order_id": "order_premium", "razorpay_payment_id": "pay_premium", "razorpay_signature": signature}, format="json")
        self.assertEqual(response.status_code, 200)
        self.assertTrue(PremiumSubscription.objects.get(user=self.user).is_active)

    def test_invalid_webhook_signature_is_rejected(self):
        self.client.force_authenticate(None)
        response = self.client.post("/api/v1/billing/webhooks/razorpay/", data=b"{}", content_type="application/json", HTTP_X_RAZORPAY_SIGNATURE="invalid")
        self.assertEqual(response.status_code, 400)

    def test_captured_payment_webhook_fulfills_once(self):
        PaymentOrder.objects.create(user=self.user, product_code="credits_100", amount=4900, currency="INR", credits=100, receipt="pm_webhook", razorpay_order_id="order_webhook")
        payload = {"event": "payment.captured", "payload": {"payment": {"entity": {"id": "pay_webhook", "order_id": "order_webhook", "status": "captured", "amount": 4900, "currency": "INR"}}}}
        body = json.dumps(payload, separators=(",", ":")).encode()
        signature = hmac.new(b"webhook-secret", body, hashlib.sha256).hexdigest()
        self.client.force_authenticate(None)
        first = self.client.generic("POST", "/api/v1/billing/webhooks/razorpay/", body, content_type="application/json", HTTP_X_RAZORPAY_SIGNATURE=signature, HTTP_X_RAZORPAY_EVENT_ID="evt_webhook")
        second = self.client.generic("POST", "/api/v1/billing/webhooks/razorpay/", body, content_type="application/json", HTTP_X_RAZORPAY_SIGNATURE=signature, HTTP_X_RAZORPAY_EVENT_ID="evt_webhook")
        self.assertEqual(first.status_code, 200)
        self.assertEqual(second.json()["status"], "duplicate")
        self.user.ai_credit_account.refresh_from_db()
        self.assertEqual(self.user.ai_credit_account.balance, 100)
