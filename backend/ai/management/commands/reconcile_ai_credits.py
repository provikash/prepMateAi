from datetime import timedelta

from django.conf import settings
from django.core.management.base import BaseCommand
from django.db import transaction
from django.db.models import Sum
from django.utils import timezone

from ai.models import AICreditAccount, AICreditTransaction, AIUsage
from ai.services.credits import CreditService
from core.monitoring import report_operational_failure


class Command(BaseCommand):
    help = "Reconcile active reservations. Dry-run unless --apply is explicitly supplied."

    def add_arguments(self, parser):
        parser.add_argument("--apply", action="store_true", help="Apply reservation corrections")
        parser.add_argument(
            "--stale-minutes", type=int,
            default=settings.AI_RESERVATION_STALE_MINUTES,
            help="Release processing reservations older than this age",
        )

    def handle(self, *args, **options):
        if options["stale_minutes"] < 1:
            raise ValueError("stale-minutes must be greater than zero")

        cutoff = timezone.now() - timedelta(minutes=options["stale_minutes"])
        stale = AIUsage.objects.filter(
            status=AIUsage.Status.PROCESSING,
            updated_at__lt=cutoff,
        ).order_by("updated_at")
        stale_count = stale.count()
        if stale_count:
            self.stdout.write(f"stale_reservations={stale_count} cutoff={cutoff.isoformat()}")
            report_operational_failure(
                "stale_ai_credit_reservations",
                count=stale_count,
                stale_minutes=options["stale_minutes"],
            )
            if options["apply"]:
                for usage in stale.iterator():
                    CreditService.release(usage, "stale_reservation")

        changed = 0
        for account in AICreditAccount.objects.select_related("user").iterator():
            expected = AIUsage.objects.filter(
                user=account.user, status=AIUsage.Status.PROCESSING
            ).aggregate(total=Sum("credits_reserved"))["total"] or 0
            if expected == account.reserved_credits:
                continue
            changed += 1
            self.stdout.write(
                f"user={account.user_id}: reserved {account.reserved_credits} -> {expected}"
            )
            if options["apply"]:
                with transaction.atomic():
                    locked = AICreditAccount.objects.select_for_update().get(pk=account.pk)
                    before = locked.balance
                    locked.reserved_credits = expected
                    locked.save(update_fields=["reserved_credits", "updated_at"])
                    AICreditTransaction.objects.create(
                        user=locked.user, account=locked,
                        transaction_type=AICreditTransaction.Type.ADJUSTMENT,
                        amount=abs(account.reserved_credits - expected),
                        balance_before=before, balance_after=locked.balance,
                        operation="reservation_reconciliation",
                        description="Corrected stored reservation total from active usage records",
                    )
        mode = "applied" if options["apply"] else "dry-run"
        self.stdout.write(
            f"Reconciliation {mode}; stale_reservations={stale_count} "
            f"accounts_changed={changed}"
        )
