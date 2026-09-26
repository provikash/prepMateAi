from django.core.management.base import BaseCommand
from django.db import transaction
from django.db.models import Sum

from ai.models import AICreditAccount, AICreditTransaction, AIUsage


class Command(BaseCommand):
    help = "Reconcile active reservations. Dry-run unless --apply is explicitly supplied."

    def add_arguments(self, parser):
        parser.add_argument("--apply", action="store_true", help="Apply reservation corrections")

    def handle(self, *args, **options):
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
        self.stdout.write(f"Reconciliation {mode}; accounts_changed={changed}")
