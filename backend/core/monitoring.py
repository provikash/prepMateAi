"""Small, privacy-safe helpers for operational error reporting."""

import json
import logging

from django.conf import settings

logger = logging.getLogger("core.operations")

try:
    import sentry_sdk
except ImportError:  # Allows management commands to explain missing optional setup.
    sentry_sdk = None


def report_operational_failure(event, *, provider="", exception=None, **context):
    """Log and report an operational failure without user content or credentials."""
    safe_context = {
        str(key): value
        for key, value in context.items()
        if value is not None and isinstance(value, (str, int, float, bool))
    }
    payload = {"event": event, **safe_context}
    if provider:
        payload["provider"] = provider
    logger.error(json.dumps(payload, separators=(",", ":"), default=str))

    if not getattr(settings, "SENTRY_DSN", "") or sentry_sdk is None:
        return
    with sentry_sdk.push_scope() as scope:
        scope.set_tag("operational_event", event)
        if provider:
            scope.set_tag("provider", provider)
        for key, value in safe_context.items():
            scope.set_extra(key, value)
        if exception is not None:
            sentry_sdk.capture_exception(exception)
        else:
            sentry_sdk.capture_message(event, level="error")
