"""
Example: Updated GoogleAuthView using GoogleTokenVerifier service

Replace the existing GoogleAuthView in backend/users/views.py with this
implementation for improved error handling and maintainability.
"""

from rest_framework.response import Response
from rest_framework import status
from rest_framework.permissions import AllowAny
from rest_framework.views import APIView
import logging

from users.services.google_auth import GoogleTokenVerifier, GoogleTokenVerificationError
from users.services import AuthService
from users.serializers import UserSummarySerializer

logger = logging.getLogger(__name__)


class GoogleAuthViewUpdated(APIView):
    """
    Google OAuth2 Authentication Endpoint
    
    POST /api/v1/auth/google/
    
    Body:
        {
            "id_token": "<Google ID token from Flutter client>"
        }
    
    Response (Success - 200):
        {
            "message": "Google login successful.",
            "user": { "id": 1, "email": "user@example.com", "name": "John" },
            "tokens": {
                "access": "eyJ0eXAiOiJKV1QiLC...",
                "refresh": "eyJ0eXAiOiJKV1QiLC..."
            },
            "created": false
        }
    
    Response (Error - 400/401):
        {
            "detail": "Invalid Google token."
        }
    """
    
    permission_classes = [AllowAny]

    def post(self, request):
        """
        Authenticate user with Google ID token.
        
        The token is expected to be a Firebase ID token from google_sign_in
        package on the Flutter client.
        """
        
        # Extract token (accept both 'id_token' and 'token' field names)
        id_token = (
            request.data.get("id_token") 
            or request.data.get("token")
        )

        if not id_token:
            return Response(
                {
                    "detail": "id_token is required.",
                    "code": "MISSING_TOKEN"
                },
                status=status.HTTP_400_BAD_REQUEST,
            )

        # Validate token format (quick check before verification)
        if not GoogleTokenVerifier.validate_token_format(id_token):
            return Response(
                {
                    "detail": "Invalid token format.",
                    "code": "INVALID_FORMAT"
                },
                status=status.HTTP_400_BAD_REQUEST,
            )

        try:
            # Initialize verifier (uses settings.GOOGLE_OAUTH_CLIENT_ID)
            verifier = GoogleTokenVerifier()
            
            # Verify token and get/create user
            user, created = verifier.verify_and_authenticate_user(id_token)
            
            # Issue JWT tokens for the user
            tokens = AuthService.issue_tokens(user)

            logger.info(
                f"✓ Google auth successful: {user.email} (created={created})"
            )

            return Response(
                {
                    "message": "Google login successful.",
                    "user": UserSummarySerializer(user).data,
                    "tokens": tokens,
                    "created": created,
                },
                status=status.HTTP_200_OK,
            )

        except GoogleTokenVerificationError as e:
            logger.warning(f"Google token verification failed: {e}")
            return Response(
                {
                    "detail": str(e),
                    "code": "VERIFICATION_FAILED"
                },
                status=status.HTTP_401_UNAUTHORIZED,
            )
        except Exception as e:
            logger.error(f"Unexpected error during Google auth: {e}")
            return Response(
                {
                    "detail": "Authentication failed. Please try again.",
                    "code": "AUTH_ERROR"
                },
                status=status.HTTP_500_INTERNAL_SERVER_ERROR,
            )


# Configuration required in settings.py:
"""
# Google OAuth Configuration
GOOGLE_OAUTH_CLIENT_ID = 'YOUR_WEB_CLIENT_ID.apps.googleusercontent.com'

# Or set from environment variable:
import os
GOOGLE_OAUTH_CLIENT_ID = os.environ.get(
    'GOOGLE_OAUTH_CLIENT_ID',
    '123456789-abcdefghijklmnopqrstuvwxyz123456.apps.googleusercontent.com'
)
"""
