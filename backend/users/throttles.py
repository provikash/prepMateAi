import hashlib
from django.conf import settings
from rest_framework.throttling import SimpleRateThrottle


class AuthIPThrottle(SimpleRateThrottle):
    scope = "auth"

    def get_rate(self):
        return "10/min"

    def allow_request(self, request, view):
        self.scope = getattr(view, "action", None) or getattr(view, "auth_scope", "login")
        self.rate = settings.AUTH_THROTTLE_RATES.get(self.scope, "10/min")
        self.num_requests, self.duration = self.parse_rate(self.rate)
        return super().allow_request(request, view)

    def get_cache_key(self, request, view):
        return self.cache_format % {"scope": "auth_ip_" + self.scope, "ident": self.get_ident(request)}


class AuthIdentityThrottle(AuthIPThrottle):
    def get_cache_key(self, request, view):
        email = request.data.get("email", "") if hasattr(request.data, "get") else ""
        if not isinstance(email, str) or not email:
            return None
        digest = hashlib.sha256(email.strip().lower().encode()).hexdigest()
        return self.cache_format % {"scope": "auth_identity_" + self.scope, "ident": digest}
