from django.conf import settings
from django.core.checks import Error, register


@register()
def authentication_policy_checks(app_configs, **kwargs):
    errors = []
    limits = {
        "OTP_LENGTH": (6, 10), "OTP_EXPIRY_SECONDS": (60, 1800),
        "OTP_MAX_ATTEMPTS": (1, 10), "OTP_RESEND_COOLDOWN_SECONDS": (1, 3600),
        "OTP_ISSUE_WINDOW_SECONDS": (60, 86400), "OTP_MAX_ISSUES": (1, 20),
    }
    for name, (minimum, maximum) in limits.items():
        if not minimum <= getattr(settings, name) <= maximum:
            errors.append(Error(f"{name} must be between {minimum} and {maximum}.", id="users.E001"))
    for name, duration in (("ACCESS_TOKEN_LIFETIME", 3600), ("REFRESH_TOKEN_LIFETIME", 30 * 86400)):
        if not 0 < settings.SIMPLE_JWT[name].total_seconds() <= duration:
            errors.append(Error(f"Unsafe {name}.", id="users.E002"))
    return errors
