from django.db.models.signals import post_save
from django.dispatch import receiver
import logging

from .models import User, UserProfile

logger = logging.getLogger(__name__)


@receiver(post_save, sender=User)
def create_or_update_user_profile(sender, instance, created, **kwargs):
    try:
        if created:
            UserProfile.objects.create(user=instance, full_name=instance.name or "")
            return

        # Ensure profile always exists, even for legacy users.
        UserProfile.objects.get_or_create(
            user=instance,
            defaults={"full_name": instance.name or ""},
        )
    except Exception as exc:
        logger.error("Error creating/updating UserProfile for user %s: %s", instance.email, exc, exc_info=True)
