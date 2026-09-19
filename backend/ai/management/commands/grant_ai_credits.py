from django.contrib.auth import get_user_model
from django.core.management.base import BaseCommand, CommandError
from django.db import transaction

from ai.models import AICreditAccount, AICreditTransaction


class Command(BaseCommand):
    help = "Grant AI credits to one user through the audited backend ledger."

    def add_arguments(self, parser):
        parser.add_argument("email")
        parser.add_argument("amount", type=int)

    def handle(self, *args, **options):
        amount = options["amount"]
        if amount <= 0:
            raise CommandError("Amount must be positive.")
        user = get_user_model().objects.filter(email=options["email"]).first()
        if user is None:
            raise CommandError("User not found.")
        with transaction.atomic():
            account, _ = AICreditAccount.objects.get_or_create(user=user)
            account = AICreditAccount.objects.select_for_update().get(pk=account.pk)
            before = account.balance
            account.balance += amount
            account.lifetime_earned += amount
            account.save(update_fields=["balance", "lifetime_earned", "updated_at"])
            AICreditTransaction.objects.create(
                user=user, account=account, transaction_type=AICreditTransaction.Type.GRANT,
                amount=amount, balance_before=before, balance_after=account.balance,
                operation="manual_grant", description="Operator grant",
            )
        self.stdout.write(self.style.SUCCESS(f"Granted {amount} AI credits."))
