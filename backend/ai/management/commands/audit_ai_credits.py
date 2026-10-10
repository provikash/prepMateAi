from django.core.management.base import BaseCommand
from django.db.models import Sum

from ai.models import AICreditAccount, AIUsage


class Command(BaseCommand):
    help = "Read-only audit of stored AI balances and active reservations."

    def handle(self, *args, **options):
        inconsistent = 0
        for account in AICreditAccount.objects.select_related("user").iterator():
            expected_reserved = AIUsage.objects.filter(
                user=account.user, status=AIUsage.Status.PROCESSING
            ).aggregate(total=Sum("credits_reserved"))["total"] or 0
            if account.reserved_credits != expected_reserved or account.reserved_credits > account.balance:
                inconsistent += 1
                self.stdout.write(
                    f"user={account.user_id} balance={account.balance} "
                    f"stored_reserved={account.reserved_credits} expected_reserved={expected_reserved}"
                )
        self.stdout.write(f"Audited {AICreditAccount.objects.count()} accounts; inconsistent={inconsistent}")
