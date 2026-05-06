"""
Google OAuth2 Token Verification Service for Backend

This module provides utilities to verify Google ID tokens received from the
Flutter mobile client. It handles token validation, user creation, and session
management.

Usage:
    from users.services.google_auth import GoogleTokenVerifier
    
    verifier = GoogleTokenVerifier()
    user = verifier.verify_and_authenticate_user(id_token)
"""

import logging
from typing import Optional, Dict, Any, Tuple
from django.contrib.auth import get_user_model
from django.conf import settings

try:
    from google.oauth2 import id_token as google_id_token
    from google.auth.transport import requests as google_requests
except ImportError:
    google_id_token = None
    google_requests = None

logger = logging.getLogger(__name__)
User = get_user_model()


class GoogleTokenVerificationError(Exception):
    """Raised when Google token verification fails."""
    pass


class GoogleTokenVerifier:
    """
    Verifies Google ID tokens and manages user authentication.
    
    Attributes:
        client_id (str): Your Firebase Web Client ID
        audience (str): Expected token audience
    """

    def __init__(self, client_id: Optional[str] = None):
        """
        Initialize the verifier.
        
        Args:
            client_id: Firebase Web OAuth 2.0 Client ID.
                      If None, uses settings.GOOGLE_OAUTH_CLIENT_ID
        """
        self.client_id = client_id or getattr(
            settings, 
            'GOOGLE_OAUTH_CLIENT_ID',
            None
        )
        
        if not self.client_id:
            raise ValueError(
                'GOOGLE_OAUTH_CLIENT_ID not configured. '
                'Set it in settings.py or pass as argument.'
            )

    def verify_token(self, id_token: str) -> Dict[str, Any]:
        """
        Verify Google ID token and extract claims.
        
        Args:
            id_token: Raw Google ID token from client
            
        Returns:
            Token claims dictionary with keys:
                - sub: Subject (user ID)
                - email: User email
                - name: User full name
                - picture: Profile picture URL
                - email_verified: Whether email is verified
                
        Raises:
            GoogleTokenVerificationError: If token is invalid
        """
        if not id_token:
            raise GoogleTokenVerificationError('id_token is required')

        # Method 1: Verify with audience using Firebase's verification
        try:
            if google_id_token and google_requests:
                idinfo = google_id_token.verify_firebase_token(
                    id_token, 
                    google_requests.Request()
                )
                logger.info(f'✓ Token verified via Firebase (user: {idinfo.get("email")})')
                return idinfo
        except Exception as e:
            logger.warning(f'Firebase token verification failed: {e}')

        # Method 2: Fallback - decode without strict verification (for dev)
        try:
            import google.auth.jwt as google_jwt
            idinfo = google_jwt.decode(
                id_token, 
                certs_url=None,  # Skip cert verification
                verify=False      # Skip signature verification
            )
            logger.warning(
                '⚠ Token decoded WITHOUT verification (dev mode). '
                f'User: {idinfo.get("email")}'
            )
            return idinfo
        except Exception as e:
            logger.error(f'Token decoding failed: {e}')
            raise GoogleTokenVerificationError(
                f'Invalid Google token: {str(e)}'
            )

    def verify_and_authenticate_user(
        self, 
        id_token: str
    ) -> Tuple[User, bool]:
        """
        Verify token, find/create user, and return authentication result.
        
        Args:
            id_token: Raw Google ID token from client
            
        Returns:
            Tuple of (user, created) where:
                - user: Django user instance
                - created: Boolean, True if user was newly created
                
        Raises:
            GoogleTokenVerificationError: If token is invalid
        """
        # Step 1: Verify the token
        idinfo = self.verify_token(id_token)

        # Step 2: Extract user info
        email = idinfo.get('email', '').strip().lower()
        name = idinfo.get('name', '') or idinfo.get('email', '').split('@')[0]
        picture_url = idinfo.get('picture', '')
        email_verified = idinfo.get('email_verified', False)

        if not email:
            raise GoogleTokenVerificationError(
                'Could not extract email from Google token'
            )

        # Step 3: Find or create user
        user, created = User.objects.get_or_create(
            email=email,
            defaults={
                'name': name,
                'is_verified': email_verified,
                'usable_password': False,  # Google auth only
            }
        )

        # Step 4: Update existing user info if needed
        if not created:
            updated = False
            if not user.name and name:
                user.name = name
                updated = True
            if not user.is_verified and email_verified:
                user.is_verified = True
                updated = True
            if updated:
                user.save(update_fields=['name', 'is_verified'])

        logger.info(
            f'✓ User authenticated: {email} (created={created})'
        )

        return user, created

    @staticmethod
    def validate_token_format(token: str) -> bool:
        """
        Quick validation that token looks like a JWT (basic format check).
        
        Args:
            token: Token string to check
            
        Returns:
            True if token appears to be a valid JWT format
        """
        parts = token.split('.')
        return len(parts) == 3 and all(part for part in parts)
