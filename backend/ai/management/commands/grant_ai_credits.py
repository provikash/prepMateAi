from django.contrib.auth import get_user_model
from django.core.management.base import BaseCommand, CommandError
from django.db import transaction

from ai.models import AICreditAccount, AICreditTransaction


class Command(BaseCommand):
    help = "Grant AI credits to one user through the audited backend ledger."

    def add_arguments(self, parser):
        parser.add_argument("identifier", help="Email or phone number of the user")
        parser.add_argument("amount", type=int, help="Number of AI credits to grant")

    def handle(self, *args, **options):
        amount = options["amount"]
        if amount <= 0:
            raise CommandError("Amount must be positive.")
        identifier = options["identifier"].strip()
        user_model = get_user_model()
        user = (
            user_model.objects.filter(email__iexact=identifier).first()
            or user_model.objects.filter(phone_number=identifier).first()
        )
        if not user:
            try:
                from users.services.phone_service import normalize_indian_phone
                normalized = normalize_indian_phone(identifier)
                user = user_model.objects.filter(phone_number=normalized).first()
            except Exception:
                pass
        if user is None:
            raise CommandError(f"User not found for identifier: '{identifier}'.")
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
