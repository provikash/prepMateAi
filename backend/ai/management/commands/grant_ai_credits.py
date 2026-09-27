from django.contrib.auth import get_user_model
from django.core.management.base import BaseCommand, CommandError
from ai.services.credits import CreditService


class Command(BaseCommand):
    help = "Grant AI credits to one user through the audited backend ledger."

    def add_arguments(self, parser):
        parser.add_argument("identifier", help="Email or phone number of the user")
        parser.add_argument("amount", type=int, help="Number of AI credits to grant")
        parser.add_argument(
            "--reason",
            required=True,
            help="Required audit reason for this manual grant",
        )

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
        account = CreditService.account(user)
        CreditService.adjust(
            account=account,
            delta=amount,
            reason=options["reason"],
        )
        self.stdout.write(self.style.SUCCESS(f"Granted {amount} AI credits."))
