from django.conf import settings
from django.db import models

from core.models import BaseModel


class PaymentOrder(BaseModel):
    class Status(models.TextChoices):
        CREATED = "CREATED"
        PAID = "PAID"
        FAILED = "FAILED"
        REFUNDED = "REFUNDED"

    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name="payment_orders")
    product_code = models.CharField(max_length=40)
    amount = models.PositiveIntegerField(help_text="Amount in currency subunits (paise for INR).")
    currency = models.CharField(max_length=3, default="INR")
    credits = models.PositiveIntegerField(default=0)
    premium_days = models.PositiveIntegerField(default=0)
    status = models.CharField(max_length=12, choices=Status.choices, default=Status.CREATED, db_index=True)
    receipt = models.CharField(max_length=40, unique=True)
    razorpay_order_id = models.CharField(max_length=64, unique=True, null=True, blank=True)
    razorpay_payment_id = models.CharField(max_length=64, unique=True, null=True, blank=True)
    signature_verified = models.BooleanField(default=False)
    paid_at = models.DateTimeField(null=True, blank=True)


class PremiumSubscription(BaseModel):
    class Status(models.TextChoices):
        ACTIVE = "ACTIVE"
        EXPIRED = "EXPIRED"
        CANCELLED = "CANCELLED"

    user = models.OneToOneField(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name="premium_subscription")
    status = models.CharField(max_length=12, choices=Status.choices, default=Status.ACTIVE)
    started_at = models.DateTimeField()
    expires_at = models.DateTimeField(db_index=True)
    source_order = models.ForeignKey(PaymentOrder, on_delete=models.PROTECT, related_name="activated_subscriptions")
    auto_renew = models.BooleanField(default=False)

    @property
    def is_active(self):
        from django.utils import timezone
        return self.status == self.Status.ACTIVE and self.expires_at > timezone.now()


class WebhookEvent(BaseModel):
    event_id = models.CharField(max_length=100, unique=True)
    event_type = models.CharField(max_length=80)
    payload_sha256 = models.CharField(max_length=64)
    processed = models.BooleanField(default=False)
    error = models.CharField(max_length=255, blank=True)
