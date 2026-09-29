import logging
import uuid

from django.core.cache import cache
from django.db import connection
from django.http import JsonResponse
from django.views.decorators.http import require_GET

from .monitoring import report_operational_failure

logger = logging.getLogger(__name__)


def _response(payload, status=200):
    response = JsonResponse(payload, status=status)
    response["Cache-Control"] = "no-store"
    return response


@require_GET
def live(request):
    """Process-only liveness probe; does not touch external dependencies."""
    return _response({"status": "ok"})


@require_GET
def health(request):
    checks = {"database": "ok", "cache": "ok"}
    try:
        with connection.cursor() as cursor:
            cursor.execute("SELECT 1")
    except Exception as exc:
        checks["database"] = "unavailable"
        logger.exception("Database readiness check failed")
        report_operational_failure("health_check_failed", exception=exc, dependency="database")

    cache_key = f"health:{uuid.uuid4().hex}"
    try:
        cache.set(cache_key, "ok", timeout=5)
        if cache.get(cache_key) != "ok":
            raise RuntimeError("Cache round-trip failed")
        cache.delete(cache_key)
    except Exception as exc:
        checks["cache"] = "unavailable"
        logger.exception("Cache readiness check failed")
        report_operational_failure("health_check_failed", exception=exc, dependency="cache")

    available = all(value == "ok" for value in checks.values())
    return _response(
        {"status": "ok" if available else "unavailable", "checks": checks},
        status=200 if available else 503,
    )
