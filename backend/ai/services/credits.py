"""Transactional, backend-owned AI credit ledger."""

import logging
from django.conf import settings
from django.db import transaction
from django.utils import timezone
from rest_framework.exceptions import APIException

from ai.models import AICreditAccount, AICreditTransaction, AIUsage

logger = logging.getLogger(__name__)


class InsufficientCredits(APIException):
    status_code = 402
    default_detail = "Insufficient AI credits. Manual editing remains available."
    default_code = "insufficient_ai_credits"


class InvalidCreditAdjustment(ValueError):
    """Raised when an operator adjustment would violate ledger invariants."""


class CreditService:
    @staticmethod
    def account(user):
        account, _ = AICreditAccount.objects.get_or_create(user=user)
        return account

    @staticmethod
    def cost(operation):
        return settings.AI_OPERATION_COSTS[operation]

    @classmethod
    def check_balance(cls, user, operation):
        return cls.account(user).available >= cls.cost(operation)

    @classmethod
    @transaction.atomic
    def adjust(
        cls,
        *,
        account,
        delta,
        reason,
        performed_by=None,
        idempotency_key="",
    ):
        """Apply an audited manual balance adjustment.

        Positive values grant credits. Negative values deduct credits, but can
        never reduce the balance below credits reserved by in-flight requests.
        """
        if performed_by is not None and not performed_by.is_staff:
            raise PermissionError("Only staff users can adjust AI credits.")
        try:
            delta = int(delta)
        except (TypeError, ValueError) as exc:
            raise InvalidCreditAdjustment("Enter a whole-number adjustment.") from exc
        reason = (reason or "").strip()
        idempotency_key = str(idempotency_key or "").strip()[:100]
        if delta == 0:
            raise InvalidCreditAdjustment("Adjustment cannot be zero.")
        if abs(delta) > settings.AI_ADMIN_MAX_ADJUSTMENT:
            raise InvalidCreditAdjustment(
                f"One adjustment cannot exceed {settings.AI_ADMIN_MAX_ADJUSTMENT} credits."
            )
        if not reason:
            raise InvalidCreditAdjustment("A reason is required.")
        if len(reason) > 255:
            raise InvalidCreditAdjustment("Reason must contain at most 255 characters.")

        locked = AICreditAccount.objects.select_for_update().select_related("user").get(
            pk=account.pk
        )
        if idempotency_key:
            existing = AICreditTransaction.objects.filter(
                account=locked,
                operation="admin_adjustment",
                idempotency_key=idempotency_key,
            ).first()
            if existing:
                return locked, existing, False

        balance_after = locked.balance + delta
        if balance_after < locked.reserved_credits:
            raise InvalidCreditAdjustment(
                "The balance cannot be lower than currently reserved credits."
            )
        if balance_after > settings.AI_CREDIT_MAX_BALANCE:
            raise InvalidCreditAdjustment(
                f"The balance cannot exceed {settings.AI_CREDIT_MAX_BALANCE} credits."
            )
        before = locked.balance
        locked.balance = balance_after
        if delta > 0:
            locked.lifetime_earned += delta
        locked.save(update_fields=["balance", "lifetime_earned", "updated_at"])
        ledger_entry = AICreditTransaction.objects.create(
            user=locked.user,
            account=locked,
            performed_by=performed_by,
            transaction_type=(
                AICreditTransaction.Type.GRANT
                if delta > 0
                else AICreditTransaction.Type.ADJUSTMENT
            ),
            amount=abs(delta),
            balance_before=before,
            balance_after=balance_after,
            operation="admin_adjustment",
            reference_type="django_admin" if performed_by else "operator",
            idempotency_key=idempotency_key,
            description=reason,
        )
        logger.info(
            "credit_adjusted user_id=%s actor_id=%s delta=%s transaction_id=%s",
            locked.user_id,
            getattr(performed_by, "pk", None),
            delta,
            ledger_entry.pk,
        )
        return locked, ledger_entry, True

    @classmethod
    @transaction.atomic
    def reserve(cls, *, user, operation, idempotency_key, reference_id):
        existing = AIUsage.objects.filter(user=user, idempotency_key=idempotency_key).first()
        if existing:
            return existing, False
        account = AICreditAccount.objects.select_for_update().filter(user=user).first()
        if account is None:
            account = AICreditAccount.objects.create(user=user)
        existing = AIUsage.objects.filter(user=user, idempotency_key=idempotency_key).first()
        if existing:
            return existing, False
        amount = cls.cost(operation)
        if account.available < amount:
            raise InsufficientCredits()
        before = account.balance
        account.reserved_credits += amount
        account.save(update_fields=["reserved_credits", "updated_at"])
        usage = AIUsage.objects.create(
            user=user, operation=operation, credits_reserved=amount,
            idempotency_key=idempotency_key, reference_id=reference_id,
            status=AIUsage.Status.PROCESSING,
        )
        AICreditTransaction.objects.create(
            user=user, account=account, transaction_type=AICreditTransaction.Type.RESERVATION,
            amount=amount, balance_before=before, balance_after=account.balance,
            operation=operation, reference_id=reference_id,
            reference_type="optimizer", idempotency_key=idempotency_key,
        )
        logger.info("credit_reserved user_id=%s transaction_id=%s reference_id=%s", user.pk, usage.pk, reference_id)
        return usage, True

    @staticmethod
    @transaction.atomic
    def commit(usage, result):
        usage = AIUsage.objects.select_for_update().get(pk=usage.pk)
        if usage.status != AIUsage.Status.PROCESSING:
            return usage
        account = AICreditAccount.objects.select_for_update().get(user=usage.user)
        before = account.balance
        account.reserved_credits -= usage.credits_reserved
        account.balance -= usage.credits_reserved
        account.lifetime_used += usage.credits_reserved
        account.save(update_fields=["reserved_credits", "balance", "lifetime_used", "updated_at"])
        usage.status = AIUsage.Status.SUCCEEDED
        usage.credits_used = usage.credits_reserved
        usage.model = result.model
        usage.input_tokens = result.input_tokens
        usage.output_tokens = result.output_tokens
        usage.total_tokens = result.total_tokens
        usage.request_id = result.request_id
        usage.latency_ms = result.latency_ms
        usage.estimated_cost = result.estimated_cost
        usage.completed_at = timezone.now()
        usage.save()
        AICreditTransaction.objects.create(
            user=usage.user, account=account, transaction_type=AICreditTransaction.Type.USAGE,
            amount=usage.credits_used, balance_before=before, balance_after=account.balance,
            operation=usage.operation, reference_id=usage.reference_id,
            reference_type="optimizer", idempotency_key=usage.idempotency_key or "",
        )
        logger.info("credit_committed user_id=%s transaction_id=%s reference_id=%s", usage.user_id, usage.pk, usage.reference_id)
        return usage

    @staticmethod
    @transaction.atomic
    def release(usage, error_code="ai_failed"):
        usage = AIUsage.objects.select_for_update().get(pk=usage.pk)
        if usage.status != AIUsage.Status.PROCESSING:
            return usage
        account = AICreditAccount.objects.select_for_update().get(user=usage.user)
        before = account.balance
        account.reserved_credits -= usage.credits_reserved
        account.save(update_fields=["reserved_credits", "updated_at"])
        usage.status = AIUsage.Status.FAILED
        usage.error_code = error_code[:60]
        usage.completed_at = timezone.now()
        usage.save(update_fields=["status", "error_code", "completed_at", "updated_at"])
        AICreditTransaction.objects.create(
            user=usage.user, account=account, transaction_type=AICreditTransaction.Type.RELEASE,
            amount=usage.credits_reserved, balance_before=before, balance_after=account.balance,
            operation=usage.operation, reference_id=usage.reference_id,
            reference_type="optimizer", idempotency_key=usage.idempotency_key or "",
        )
        logger.info("credit_released user_id=%s transaction_id=%s reference_id=%s error_code=%s", usage.user_id, usage.pk, usage.reference_id, error_code[:60])
        return usage

    @staticmethod
    @transaction.atomic
    def refund(usage):
        usage = AIUsage.objects.select_for_update().get(pk=usage.pk)
        if usage.status == AIUsage.Status.REFUNDED:
            return usage
        if usage.status != AIUsage.Status.SUCCEEDED:
            raise ValueError("Only completed AI usage can be refunded.")
        account = AICreditAccount.objects.select_for_update().get(user=usage.user)
        before = account.balance
        account.balance += usage.credits_used
        account.lifetime_used -= usage.credits_used
        account.save(update_fields=["balance", "lifetime_used", "updated_at"])
        usage.status = AIUsage.Status.REFUNDED
        usage.save(update_fields=["status", "updated_at"])
        AICreditTransaction.objects.create(
            user=usage.user, account=account, transaction_type=AICreditTransaction.Type.REFUND,
            amount=usage.credits_used, balance_before=before, balance_after=account.balance,
            operation=usage.operation, reference_id=usage.reference_id,
            reference_type="optimizer", idempotency_key=usage.idempotency_key or "",
        )
        return usage
