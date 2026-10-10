import hashlib
from django.conf import settings
from rest_framework.throttling import SimpleRateThrottle


class AuthIPThrottle(SimpleRateThrottle):
    scope = "auth"

    def get_rate(self):
        return "10/min"

    def allow_request(self, request, view):
        if getattr(settings, "ENABLE_TEST_OTP_LOGIN", False):
            identity = request.data.get("phone_number", "") if hasattr(request.data, "get") else ""
            if identity:
                allowed = getattr(settings, "TEST_OTP_PHONE_NUMBERS", set())
                if identity in allowed:
                    return True
                try:
                    from .services.phone_service import normalize_indian_phone
                    if normalize_indian_phone(identity) in allowed:
                        return True
                except Exception:
                    pass
        self.scope = getattr(view, "action", None) or getattr(view, "auth_scope", "login")
        self.rate = settings.AUTH_THROTTLE_RATES.get(self.scope, "10/min")
        self.num_requests, self.duration = self.parse_rate(self.rate)
        return super().allow_request(request, view)

    def get_cache_key(self, request, view):
        return self.cache_format % {"scope": "auth_ip_" + self.scope, "ident": self.get_ident(request)}


class AuthIdentityThrottle(AuthIPThrottle):
    def allow_request(self, request, view):
        if getattr(settings, "ENABLE_TEST_OTP_LOGIN", False):
            identity = request.data.get("phone_number", "") if hasattr(request.data, "get") else ""
            if identity:
                allowed = getattr(settings, "TEST_OTP_PHONE_NUMBERS", set())
                if identity in allowed:
                    return True
                try:
                    from .services.phone_service import normalize_indian_phone
                    if normalize_indian_phone(identity) in allowed:
                        return True
                except Exception:
                    pass
        return super().allow_request(request, view)

    def get_cache_key(self, request, view):
        identity = request.data.get("phone_number", "") if hasattr(request.data, "get") else ""
        if not isinstance(identity, str) or not identity:
            return None
        try:
            from .services.phone_service import normalize_indian_phone
            identity = normalize_indian_phone(identity)
        except ValueError:
            identity = identity.strip()
        digest = hashlib.sha256(identity.encode()).hexdigest()
        return self.cache_format % {"scope": "auth_identity_" + self.scope, "ident": digest}
