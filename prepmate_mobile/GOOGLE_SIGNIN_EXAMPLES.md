"""
Complete Google Sign-In Flow - End-to-End Example

This file demonstrates the complete authentication flow from Flutter client
through to backend verification.
"""

# ============================================================================
# PART 1: FLUTTER CLIENT (prepmate_mobile)
# ============================================================================

"""
File: lib/features/auth/data/datasources/auth_remote_data_source.dart

Steps:
1. User taps "Sign in with Google"
2. GoogleSignIn is initialized with serverClientId
3. Native Google Sign-In UI appears
4. User authenticates with Google
5. idToken is retrieved
6. Token is sent to backend at auth/google/ endpoint
"""

# Example Dart code (ALREADY IMPLEMENTED):
"""
import 'package:google_sign_in/google_sign_in.dart';
import 'package:dio/dio.dart';

class AuthRemoteDataSource {
  final Dio dio;
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  bool _googleInitialized = false;

  Future<User?> signInWithGoogle() async {
    if (!_googleInitialized) {
      // ⚠️ CRITICAL: Configure with Web Client ID
      await _googleSignIn.initialize(
        serverClientId: '123456789-abc.apps.googleusercontent.com',
        scopes: ['email', 'profile'],
      );
      _googleInitialized = true;
    }

    try {
      // Show Google Sign-In UI
      final GoogleSignInAccount account = 
        await _googleSignIn.signInSilently() 
        ?? await _googleSignIn.signIn();
      
      if (account == null) {
        throw Exception('Google sign-in was cancelled by user.');
      }

      // Get authentication details
      final GoogleSignInAuthentication auth = await account.authentication;
      final String? idToken = auth.idToken;

      if (idToken == null || idToken.isEmpty) {
        throw Exception('Google sign-in failed: id_token is missing.');
      }

      // Send token to backend
      final response = await dio.post(
        'auth/google/',
        data: {'id_token': idToken},
      );

      // Save tokens
      final accessToken = response.data['tokens']['access'];
      final refreshToken = response.data['tokens']['refresh'];
      
      await TokenService.saveTokens(
        accessToken: accessToken,
        refreshToken: refreshToken,
      );

      return UserModel.fromJson(response.data['user']);
    } catch (e) {
      if (e.toString().contains('serverClientId')) {
        throw Exception(
          'Google Sign-In configuration error: serverClientId is missing.'
        );
      }
      rethrow;
    }
  }
}
"""

# ============================================================================
# PART 2: BACKEND VERIFICATION (Django)
# ============================================================================

"""
File: backend/users/services/google_auth.py

Receives the idToken from Flutter client and:
1. Verifies token with Google
2. Extracts user information
3. Creates/finds user in database
4. Issues JWT tokens for app
"""

# Example Python code (ALREADY CREATED):
"""
from django.contrib.auth import get_user_model
from google.oauth2 import id_token as google_id_token
from google.auth.transport import requests as google_requests
import logging

User = get_user_model()
logger = logging.getLogger(__name__)

class GoogleTokenVerifier:
    def __init__(self, client_id):
        self.client_id = client_id

    def verify_and_authenticate_user(self, id_token):
        '''
        Verify Google ID token and return/create user.
        
        Args:
            id_token: Raw token from Flutter client
            
        Returns:
            (user, created) tuple
        '''
        
        # Step 1: Verify token with Google
        try:
            idinfo = google_id_token.verify_firebase_token(
                id_token, 
                google_requests.Request()
            )
        except Exception as e:
            logger.warning(f"Token verification failed: {e}")
            raise

        # Step 2: Extract user information
        email = idinfo.get('email', '').lower()
        name = idinfo.get('name', '')

        if not email:
            raise ValueError('Email not found in token')

        # Step 3: Find or create user
        user, created = User.objects.get_or_create(
            email=email,
            defaults={'name': name, 'is_verified': True}
        )

        return user, created


# Backend API endpoint
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
from rest_framework.permissions import AllowAny

class GoogleAuthView(APIView):
    '''
    POST /api/v1/auth/google/
    Body: {"id_token": "<token_from_flutter>"}
    '''
    permission_classes = [AllowAny]

    def post(self, request):
        id_token = request.data.get('id_token')
        
        if not id_token:
            return Response(
                {'detail': 'id_token is required.'},
                status=status.HTTP_400_BAD_REQUEST
            )

        try:
            verifier = GoogleTokenVerifier(
                client_id='YOUR_WEB_CLIENT_ID.apps.googleusercontent.com'
            )
            user, created = verifier.verify_and_authenticate_user(id_token)
            
            # Issue JWT tokens
            tokens = AuthService.issue_tokens(user)
            
            return Response({
                'message': 'Google login successful.',
                'user': {
                    'id': user.id,
                    'email': user.email,
                    'name': user.name,
                },
                'tokens': tokens,
                'created': created,
            }, status=status.HTTP_200_OK)
            
        except Exception as e:
            logger.error(f"Google auth failed: {e}")
            return Response(
                {'detail': 'Authentication failed.'},
                status=status.HTTP_401_UNAUTHORIZED
            )
"""

# ============================================================================
# PART 3: CONFIGURATION REQUIREMENTS
# ============================================================================

"""
Backend Settings (settings.py):
"""

# settings.py
import os

# Google OAuth2 Configuration
GOOGLE_OAUTH_CLIENT_ID = os.environ.get(
    'GOOGLE_OAUTH_CLIENT_ID',
    '123456789-abcdefghijklmnopqrstuvwxyz.apps.googleusercontent.com'
)

# Required packages
INSTALLED_APPS = [
    # ...
    'users',
]

# ============================================================================
# PART 4: FIREBASE SETUP CONFIGURATION
# ============================================================================

"""
google-services.json structure (placed at android/app/google-services.json):
"""

google_services_json = {
    "project_info": {
        "project_number": "123456789",
        "project_id": "your-firebase-project",
        "storage_bucket": "your-firebase-project.appspot.com"
    },
    "client": [
        {
            "client_info": {
                "mobilesdk_app_id": "1:123456789:android:abc123...",
                "android_client_info": {
                    "package_name": "com.example.prepmate_mobile"
                }
            },
            "oauth_client": [
                {
                    "client_id": "123456789-android.apps.googleusercontent.com",
                    "client_type": 1,
                    "android_info": {
                        "package_name": "com.example.prepmate_mobile",
                        "certificate_hash": "YOUR_SHA1_FINGERPRINT"
                    }
                },
                {
                    "client_id": "123456789-web.apps.googleusercontent.com",
                    "client_type": 3
                }
            ]
        }
    ]
}

# ============================================================================
# PART 5: TESTING THE FLOW
# ============================================================================

"""
End-to-End Test Steps:

1. FLUTTER SIDE:
   - Tap "Sign in with Google"
   - Google Sign-In UI appears
   - Sign in with test account
   - Check console for successful token retrieval
   
2. BACKEND SIDE:
   - Send POST request to auth/google/
   - Verify response has tokens
   - Check user created in database
   
3. VERIFICATION:
   - User can access authenticated endpoints
   - JWT token works for API calls
   - User data is correctly stored
"""

# Test curl command:
curl_test = '''
curl -X POST http://localhost:8000/api/v1/auth/google/ \\
  -H "Content-Type: application/json" \\
  -d '{
    "id_token": "eyJhbGciOiJSUzI1NiIsImtpZCI6IjExMjM0NTY3ODkwYWJjZGVmIn0..."
  }'
'''

# Expected response:
expected_response = {
    "message": "Google login successful.",
    "user": {
        "id": 1,
        "email": "user@gmail.com",
        "name": "John Doe"
    },
    "tokens": {
        "access": "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9...",
        "refresh": "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9..."
    },
    "created": True
}

# ============================================================================
# PART 6: ERROR HANDLING
# ============================================================================

"""
Common Errors and Solutions:

Error: GoogleSignInException: serverClientId must be provided on Android
Fix:
  await _googleSignIn.initialize(
    serverClientId: 'YOUR_WEB_CLIENT_ID.apps.googleusercontent.com',  # Add this
  );

Error: com.google.android.gms.common.GooglePlayServicesNotAvailableException
Fix:
  - Check Google Play Services is installed
  - Update google_sign_in package

Error: Invalid Google token
Fix:
  - Verify GOOGLE_OAUTH_CLIENT_ID in settings.py
  - Check token hasn't expired
  - Ensure google-auth library installed: pip install google-auth

Error: Certificate path issue
Fix:
  - Place google-services.json at: android/app/google-services.json
  - Verify JSON syntax
  - Rebuild: flutter clean && flutter pub get
"""

# ============================================================================
# PART 7: SECURITY CHECKLIST
# ============================================================================

security_checklist = [
    "✓ SHA-1 fingerprint registered in Firebase",
    "✓ google-services.json downloaded from Firebase",
    "✓ serverClientId configured in Flutter",
    "✓ GOOGLE_OAUTH_CLIENT_ID set in Django settings",
    "✓ Google authentication enabled in Firebase",
    "✓ ID token validated on backend",
    "✓ JWT tokens stored securely in Flutter",
    "✓ HTTPS enforced in production",
    "✓ Token expiration handled",
    "✓ Error messages don't leak sensitive info",
]

# ============================================================================
# PART 8: HELPFUL COMMANDS
# ============================================================================

commands = {
    "Get SHA-1 fingerprint (Windows)": (
        'cd C:\\Users\\<YourUsername>\\.android && '
        'keytool -list -v -keystore debug.keystore -alias androiddebugkey '
        '-storepass android -keypass android'
    ),
    "Get SHA-1 fingerprint (macOS/Linux)": (
        'keytool -list -v -keystore ~/.android/debug.keystore '
        '-alias androiddebugkey -storepass android -keypass android'
    ),
    "Rebuild Flutter app": (
        'flutter clean && flutter pub get && flutter run'
    ),
    "Clear Android build cache": (
        'cd android && ./gradlew clean && cd ..'
    ),
    "Install backend packages": (
        'pip install google-auth google-auth-httplib2 google-auth-oauthlib'
    ),
}

"""
Version: 1.0
Last Updated: 2026-05-06
Status: Complete and Ready ✅
"""
