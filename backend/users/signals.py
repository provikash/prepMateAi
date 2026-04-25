from django.db.models.signals import post_save
from django.dispatch import receiver

from .models import User, UserProfile


@receiver(post_save, sender=User)
def create_or_update_user_profile(sender, instance, created, **kwargs):
    if created:
        UserProfile.objects.create(user=instance, full_name=instance.name or "")
        return

    # Ensure profile always exists, even for legacy users.
    UserProfile.objects.get_or_create(
        user=instance,
        defaults={"full_name": instance.name or ""},
    )
