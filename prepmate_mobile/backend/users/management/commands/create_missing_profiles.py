from django.core.management.base import BaseCommand
from django.contrib.auth import get_user_model

from users.models import UserProfile

User = get_user_model()


class Command(BaseCommand):
    help = "Create missing UserProfile instances for existing users."

    def add_arguments(self, parser):
        parser.add_argument(
            "--dry-run",
            action="store_true",
            help="Show how many profiles would be created without saving.",
        )

    def handle(self, *args, **options):
        dry_run = options.get("dry_run", False)
        users = User.objects.all()
        created_count = 0
        total = users.count()

        for user in users.iterator():
            try:
                profile = getattr(user, "profile", None)
            except Exception:
                profile = None

            if profile is None:
                if dry_run:
                    created_count += 1
                    continue

                # create profile with sensible defaults
                UserProfile.objects.create(
                    user=user,
                    full_name=getattr(user, "name", "") or "",
                )
                created_count += 1
                self.stdout.write(self.style.SUCCESS(f"Created profile for user: {user.email}"))

        self.stdout.write(self.style.NOTICE(f"Processed {total} users."))
        if dry_run:
            self.stdout.write(self.style.SUCCESS(f"Would create {created_count} profiles (dry-run)."))
        else:
            self.stdout.write(self.style.SUCCESS(f"Created {created_count} profiles."))
