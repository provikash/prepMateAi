import json
import logging
import re
import time
import uuid

from django.conf import settings
from django.utils.cache import patch_vary_headers


request_logger = logging.getLogger("core.request")
_REQUEST_ID = re.compile(r"^[A-Za-z0-9._-]{1,80}$")


class RequestIdMiddleware:
    """Propagate a safe request ID and emit metadata-only access logs."""

    def __init__(self, get_response):
        self.get_response = get_response

    def __call__(self, request):
        supplied = request.headers.get("X-Request-ID", "")
        request_id = supplied if _REQUEST_ID.fullmatch(supplied) else uuid.uuid4().hex
        request.request_id = request_id
        started = time.monotonic()
        response = self.get_response(request)
        response["X-Request-ID"] = request_id
        if request.path.startswith("/api/v1/auth/"):
            response["Cache-Control"] = "no-store"
        elif request.headers.get("Authorization"):
            response.setdefault("Cache-Control", "private, no-cache")
            patch_vary_headers(response, ("Authorization",))
        duration_ms = round((time.monotonic() - started) * 1000, 2)
        payload = json.dumps(
            {
                "event": "http_request",
                "request_id": request_id,
                "method": request.method,
                "path": request.path,
                "status": response.status_code,
                "duration_ms": duration_ms,
                "slow": duration_ms >= settings.SLOW_REQUEST_THRESHOLD_MS,
            },
            separators=(",", ":"),
        )
        if response.status_code >= 500:
            request_logger.error(payload)
        elif response.status_code >= 400 or duration_ms >= settings.SLOW_REQUEST_THRESHOLD_MS:
            request_logger.warning(payload)
        else:
            request_logger.info(payload)
        return response
