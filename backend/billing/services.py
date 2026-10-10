import hashlib
import hmac
from datetime import timedelta

import requests
from django.conf import settings
from django.db import transaction
from django.utils import timezone

from ai.models import AICreditAccount, AICreditTransaction
from .models import PaymentOrder, PremiumSubscription


class PaymentError(Exception):
    pass


class RazorpayClient:
    def __init__(self):
        if not settings.RAZORPAY_KEY_ID or not settings.RAZORPAY_KEY_SECRET:
            raise PaymentError("Razorpay is not configured.")
        self.auth = (settings.RAZORPAY_KEY_ID, settings.RAZORPAY_KEY_SECRET)

    def _request(self, method, path, **kwargs):
        try:
            response = requests.request(method, f"{settings.RAZORPAY_API_BASE_URL}{path}", auth=self.auth, timeout=(5, 20), **kwargs)
            response.raise_for_status()
            return response.json()
        except (requests.RequestException, ValueError) as exc:
            raise PaymentError("Razorpay is temporarily unavailable.") from exc

    def create_order(self, data):
        return self._request("POST", "/orders", json=data)

    def fetch_payment(self, payment_id):
        return self._request("GET", f"/payments/{payment_id}")


def verify_checkout_signature(order_id, payment_id, signature):
    expected = hmac.new(settings.RAZORPAY_KEY_SECRET.encode(), f"{order_id}|{payment_id}".encode(), hashlib.sha256).hexdigest()
    return hmac.compare_digest(expected, signature)


def verify_webhook_signature(body, signature):
    expected = hmac.new(settings.RAZORPAY_WEBHOOK_SECRET.encode(), body, hashlib.sha256).hexdigest()
    return bool(settings.RAZORPAY_WEBHOOK_SECRET) and hmac.compare_digest(expected, signature or "")


@transaction.atomic
def fulfill_order(order_id, payment):
    order = PaymentOrder.objects.select_for_update().select_related("user").get(razorpay_order_id=order_id)
    if order.status == PaymentOrder.Status.PAID:
        return order, False
    if payment.get("order_id") != order.razorpay_order_id or payment.get("status") != "captured":
        raise PaymentError("Payment has not been captured for this order.")
    if int(payment.get("amount", -1)) != order.amount or payment.get("currency") != order.currency:
        raise PaymentError("Payment amount or currency does not match the order.")

    account = AICreditAccount.objects.select_for_update().filter(user=order.user).first()
    if account is None:
        account = AICreditAccount.objects.create(user=order.user)
    before = account.balance
    account.balance += order.credits
    account.lifetime_earned += order.credits
    if account.balance > settings.AI_CREDIT_MAX_BALANCE:
        raise PaymentError("The resulting credit balance exceeds the configured limit.")
    account.save(update_fields=["balance", "lifetime_earned", "updated_at"])
    if order.credits:
        AICreditTransaction.objects.create(
            user=order.user, account=account, transaction_type=AICreditTransaction.Type.PURCHASE,
            amount=order.credits, balance_before=before, balance_after=account.balance,
            operation="razorpay_purchase", reference_type="razorpay_order",
            idempotency_key=order.razorpay_order_id, description=f"Purchased {order.credits} AI credits",
        )
    if order.premium_days:
        now = timezone.now()
        existing = PremiumSubscription.objects.select_for_update().filter(user=order.user).first()
        base = existing.expires_at if existing and existing.expires_at > now else now
        values = {"status": PremiumSubscription.Status.ACTIVE, "started_at": existing.started_at if existing else now, "expires_at": base + timedelta(days=order.premium_days), "source_order": order, "auto_renew": False}
        PremiumSubscription.objects.update_or_create(user=order.user, defaults=values)
    order.status = PaymentOrder.Status.PAID
    order.razorpay_payment_id = payment["id"]
    order.signature_verified = True
    order.paid_at = timezone.now()
    order.save(update_fields=["status", "razorpay_payment_id", "signature_verified", "paid_at", "updated_at"])
    return order, True
