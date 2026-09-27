from django.db.models.signals import post_save
from django.dispatch import receiver

from users.models import User

from .models import AICreditAccount


@receiver(post_save, sender=User)
def ensure_ai_credit_account(sender, instance, raw=False, **kwargs):
    if not raw:
        AICreditAccount.objects.get_or_create(user=instance)

