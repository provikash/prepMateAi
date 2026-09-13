"""Google OAuth verification helpers for the users app."""

from django.conf import settings
from google.auth.transport import requests as google_requests
from google.oauth2 import id_token as google_id_token


class GoogleTokenError(ValueError):
    """Raised when a Google ID token cannot be verified."""


def verify_google_id_token(id_token: str) -> dict:
    client_id = getattr(settings, "GOOGLE_OAUTH_CLIENT_ID", None)
    if not client_id:
        raise GoogleTokenError("GOOGLE_OAUTH_CLIENT_ID is not configured.")

    try:
        return google_id_token.verify_oauth2_token(
            id_token,
            google_requests.Request(),
            audience=client_id,
        )
    except ValueError as exc:
        raise GoogleTokenError(str(exc)) from exc