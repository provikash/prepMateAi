from datetime import timedelta

from django.core.management.base import BaseCommand
from django.utils import timezone

from users.models import EmailOTP, OTPChallenge


class Command(BaseCommand):
    help = "Delete expired OTP records after a configurable audit-retention period."

    def add_arguments(self, parser):
        parser.add_argument("--retention-days", type=int, default=7)
        parser.add_argument("--batch-size", type=int, default=1000)
        parser.add_argument("--apply", action="store_true")

    @staticmethod
    def _delete_in_batches(queryset, batch_size):
        deleted = 0
        while True:
            primary_keys = list(queryset.values_list("pk", flat=True)[:batch_size])
            if not primary_keys:
                return deleted
            count, _ = queryset.model.objects.filter(pk__in=primary_keys).delete()
            deleted += count

    def handle(self, *args, **options):
        if options["retention_days"] < 0:
            raise ValueError("retention-days must be zero or greater")
        if options["batch_size"] < 1:
            raise ValueError("batch-size must be greater than zero")

        cutoff = timezone.now() - timedelta(days=options["retention_days"])
        challenges = OTPChallenge.objects.filter(expires_at__lt=cutoff)
        email_otps = EmailOTP.objects.filter(expires_at__lt=cutoff)
        challenge_count = challenges.count()
        email_count = email_otps.count()

        if options["apply"]:
            challenge_count = self._delete_in_batches(challenges, options["batch_size"])
            email_count = self._delete_in_batches(email_otps, options["batch_size"])

        mode = "deleted" if options["apply"] else "dry-run"
        self.stdout.write(
            f"OTP cleanup {mode}; challenges={challenge_count} email_otps={email_count} "
            f"cutoff={cutoff.isoformat()}"
        )
