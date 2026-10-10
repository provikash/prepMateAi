"""Isolated full-project tests; never connect to deployment databases or send SMTP."""
import os
os.environ["DJANGO_ENV"] = "test"
# Local .env files may intentionally enable the development-only OTP shortcut.
# Disable external integrations before importing the shared settings so tests
# remain isolated and the production safety checks cannot fail during import.
os.environ["ENABLE_TEST_OTP_LOGIN"] = "False"
os.environ["SENTRY_DSN"] = ""
from .settings import *  # noqa: F403
from django.core.management.utils import get_random_secret_key

SECRET_KEY = get_random_secret_key()
DEBUG = False
DATABASES = {"default": {"ENGINE": "django.db.backends.sqlite3", "NAME": ":memory:"}}
if os.getenv("AUTH_TEST_DATABASE_URL"):
    DATABASES = {"default": dj_database_url.parse(os.environ["AUTH_TEST_DATABASE_URL"])}
EMAIL_BACKEND = "django.core.mail.backends.locmem.EmailBackend"
CACHES = {"default": {"BACKEND": "django.core.cache.backends.locmem.LocMemCache"}}
ALLOWED_HOSTS = ["testserver", "localhost"]
MEDIA_ROOT = BASE_DIR.parent / ".venv" / "test-media"
