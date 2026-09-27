from django.conf import settings
from django.db import models

from core.models import BaseModel


class AICreditAccount(BaseModel):
    user = models.OneToOneField(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name="ai_credit_account")
    balance = models.PositiveIntegerField(default=0)
    reserved_credits = models.PositiveIntegerField(default=0)
    lifetime_earned = models.PositiveIntegerField(default=0)
    lifetime_used = models.PositiveIntegerField(default=0)

    @property
    def available(self):
        return self.balance - self.reserved_credits


class AICreditTransaction(BaseModel):
    class Type(models.TextChoices):
        GRANT = "GRANT"
        PURCHASE = "PURCHASE"
        RESERVATION = "RESERVATION"
        RELEASE = "RELEASE"
        USAGE = "USAGE"
        REFUND = "REFUND"
        EXPIRATION = "EXPIRATION"
        ADJUSTMENT = "ADJUSTMENT"

    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE)
    performed_by = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.SET_NULL,
        related_name="performed_credit_adjustments",
        null=True,
        blank=True,
    )
    account = models.ForeignKey(AICreditAccount, on_delete=models.CASCADE, related_name="transactions")
    transaction_type = models.CharField(max_length=20, choices=Type.choices)
    amount = models.PositiveIntegerField()
    balance_before = models.PositiveIntegerField()
    balance_after = models.PositiveIntegerField()
    operation = models.CharField(max_length=60)
    reference_id = models.UUIDField(null=True, blank=True)
    reference_type = models.CharField(max_length=40, blank=True)
    idempotency_key = models.CharField(max_length=100, blank=True)
    description = models.CharField(max_length=255, blank=True)

    class Meta:
        ordering = ["-created_at"]


class AIUsage(BaseModel):
    class Status(models.TextChoices):
        PENDING = "PENDING"
        PROCESSING = "PROCESSING"
        SUCCEEDED = "SUCCEEDED"
        FAILED = "FAILED"
        CANCELLED = "CANCELLED"
        REFUNDED = "REFUNDED"

    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE)
    operation = models.CharField(max_length=60)
    provider = models.CharField(max_length=40, default="openrouter")
    model = models.CharField(max_length=100, blank=True)
    input_tokens = models.PositiveIntegerField(default=0)
    output_tokens = models.PositiveIntegerField(default=0)
    total_tokens = models.PositiveIntegerField(default=0)
    credits_reserved = models.PositiveIntegerField(default=0)
    credits_used = models.PositiveIntegerField(default=0)
    status = models.CharField(max_length=20, choices=Status.choices, default=Status.PENDING)
    request_id = models.CharField(max_length=100, blank=True)
    idempotency_key = models.CharField(max_length=100, null=True, blank=True)
    reference_id = models.UUIDField(null=True, blank=True)
    latency_ms = models.PositiveIntegerField(default=0)
    estimated_cost = models.DecimalField(max_digits=12, decimal_places=6, null=True, blank=True)
    error_code = models.CharField(max_length=60, blank=True)
    error_message = models.CharField(max_length=255, blank=True)
    completed_at = models.DateTimeField(null=True, blank=True)

    class Meta:
        constraints = [models.UniqueConstraint(fields=["user", "idempotency_key"], name="unique_user_ai_idempotency")]
