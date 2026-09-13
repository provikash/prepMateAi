import os
os.environ["DJANGO_ENV"] = "development"
from .settings import *  # noqa: F403

DEBUG = True
# Ephemeral only: configure a stable environment secret for persistent local tokens.
if not SECRET_KEY:
    from django.core.management.utils import get_random_secret_key
    SECRET_KEY = get_random_secret_key()
