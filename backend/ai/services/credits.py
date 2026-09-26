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
