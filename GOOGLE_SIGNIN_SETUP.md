# Google Sign-In Setup Guide for PrepMateAI

## Problem
```
GoogleSignInException: serverClientId must be provided on Android
```

This error occurs because the `google_sign_in` package on Android requires explicit configuration with your Firebase Web Client ID.

---

## ✅ Solution Overview

1. **Get Firebase Web Client ID** from Firebase Console
2. **Calculate SHA-1 fingerprint** of your Android signing key
3. **Configure google-services.json** with SHA-1 and credentials
4. **Update Flutter code** with serverClientId
5. **Enable Google auth** in Firebase Console
6. **Test end-to-end** authentication flow

---

## 📋 Step-by-Step Setup

### Step 1: Get Your Firebase Web Client ID

1. Go to [Firebase Console](https://console.firebase.google.com)
2. Select your project → **Project Settings** (gear icon)
3. Go to **Service Accounts** tab
4. Look for the **Web Client ID** in the OAuth 2.0 Client IDs section
   - Format: `123456789-abcdefghijklmnopqrstuvwxyz123456.apps.googleusercontent.com`

**If you don't see it:**
1. Go to [Google Cloud Console](https://console.cloud.google.com)
2. Select your Firebase project
3. Click **Credentials** in the left sidebar
4. Under **OAuth 2.0 Client IDs**, create a new **Web application** client if needed
5. Copy the Client ID

### Step 2: Calculate SHA-1 Fingerprint

You need your Android signing key's SHA-1 hash. Follow the steps for your setup:

#### Option A: Debug Key (Development)
```bash
# Windows - PowerShell
cd C:\Users\<YourUsername>\.android
keytool -list -v -keystore debug.keystore -alias androiddebugkey -storepass android -keypass android

# macOS/Linux
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
```

Look for the **SHA1** line in the output. Example:
```
SHA1: AB:CD:EF:01:23:45:67:89:AB:CD:EF:01:23:45:67:89:AB:CD:EF:01
```

#### Option B: Release Key (Production)
```bash
keytool -list -v -keystore path/to/your/keystore.jks -alias release_key
```

### Step 3: Update Firebase Console

1. Firebase Console → Project Settings → **Service Accounts**
2. Click **Manage all** next to OAuth 2.0 Client IDs
3. Edit the **Android** client:
   - Package name: `com.example.prepmate_mobile`
   - SHA-1 fingerprint: Paste from Step 2 (without colons)
     - Example: `ABCDEF0123456789ABCDEF0123456789ABCDEF01`
4. Save the changes

### Step 4: Download google-services.json

1. Firebase Console → **Project Settings**
2. Scroll down to **Your apps** section
3. Find your **Android app** → Click the three dots → **Download google-services.json**
4. Place the file at: `prepmate_mobile/android/app/google-services.json`

**The file should look like:**
```json
{
  "project_info": {
    "project_number": "123456789",
    "project_id": "your-project-id",
    "storage_bucket": "your-project-id.appspot.com"
  },
  "client": [
    {
      "client_info": {
        "mobilesdk_app_id": "1:123456789:android:abcd1234...",
        "android_client_info": {
          "package_name": "com.example.prepmate_mobile"
        }
      },
      "oauth_client": [
        {
          "client_id": "123456789-abcdefg....apps.googleusercontent.com",
          "client_type": 1,
          "android_info": {
            "package_name": "com.example.prepmate_mobile",
            "certificate_hash": "your_sha1_fingerprint"
          }
        }
      ]
    }
  ]
}
```

### Step 5: Enable Google Authentication in Firebase

1. Firebase Console → **Authentication**
2. Click **Sign-in method** tab
3. Enable **Google** provider
4. Make sure your Web Client ID is linked

### Step 6: Update Flutter Code

The code has already been updated in `lib/features/auth/data/datasources/auth_remote_data_source.dart`.

**Update this line with your actual Web Client ID:**
```dart
await _googleSignIn.initialize(
  serverClientId: 'YOUR_WEB_CLIENT_ID.apps.googleusercontent.com',
  // Example: '123456789-abc123def456.apps.googleusercontent.com'
  scopes: ['email', 'profile'],
);
```

### Step 7: Backend Configuration

Update your Django settings.py:
```python
# settings.py

import os

# Google OAuth Configuration
GOOGLE_OAUTH_CLIENT_ID = os.environ.get(
    'GOOGLE_OAUTH_CLIENT_ID',
    '123456789-abcdefghijklmnopqrstuvwxyz123456.apps.googleusercontent.com'
)
```

Or set the environment variable:
```bash
export GOOGLE_OAUTH_CLIENT_ID="123456789-abcdefghijklmnopqrstuvwxyz123456.apps.googleusercontent.com"
```

---

## 🔧 Updated Android Build Configuration

Already applied changes:

**android/app/build.gradle.kts:**
```kotlin
plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")  // ← Added for google-services.json
}
```

**android/settings.gradle.kts:**
```kotlin
plugins {
    id("com.google.gms.google-services") version "4.4.0" apply false
}
```

---

## 📱 Updated Flutter Code

Key changes in `auth_remote_data_source.dart`:

```dart
Future<User?> signInWithGoogle() async {
  if (!_googleInitialized) {
    // ⚠️ CRITICAL: serverClientId must be your Firebase Web Client ID
    await _googleSignIn.initialize(
      serverClientId: 'YOUR_WEB_CLIENT_ID.apps.googleusercontent.com',
      scopes: ['email', 'profile'],
    );
    _googleInitialized = true;
  }

  try {
    // Sign in with fallback to silent sign-in
    final GoogleSignInAccount account = await _googleSignIn.signInSilently() 
      ?? await _googleSignIn.signIn();
    
    if (account == null) {
      throw Exception('Google sign-in was cancelled by user.');
    }

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

    // Process response and save tokens
    // ...
  } on Exception catch (e) {
    if (e.toString().contains('serverClientId')) {
      throw Exception(
        'Google Sign-In configuration error: serverClientId is missing.'
      );
    }
    rethrow;
  }
}
```

---

## 🧪 Testing the Implementation

### 1. Flutter Side
```bash
cd prepmate_mobile
flutter clean
flutter pub get
flutter run
```

Tap "Sign in with Google" and verify:
- No `serverClientId` error
- Google Sign-In UI appears
- ID token is successfully obtained

### 2. Backend Side
```bash
# Test the endpoint
curl -X POST http://localhost:8000/api/v1/auth/google/ \
  -H "Content-Type: application/json" \
  -d '{"id_token": "<token_from_flutter>"}'
```

Expected response:
```json
{
  "message": "Google login successful.",
  "user": {
    "id": 1,
    "email": "user@gmail.com",
    "name": "John Doe"
  },
  "tokens": {
    "access": "eyJ0eXAiOiJKV1QiLC...",
    "refresh": "eyJ0eXAiOiJKV1QiLC..."
  },
  "created": true
}
```

---

## 🐛 Common Issues

### Issue: "serverClientId must be provided on Android"

**Solution:**
1. ✅ Ensure `serverClientId` is set in `_googleSignIn.initialize()`
2. ✅ Verify it's your **Web Client ID**, not Android Client ID
3. ✅ Rebuild: `flutter clean && flutter pub get && flutter run`

### Issue: "com.google.android.gms:play-services-auth not found"

**Solution:**
The dependency is already in `pubspec.yaml`. Run:
```bash
flutter pub get
flutter clean
flutter run
```

### Issue: "The provided SHA-1 fingerprint doesn't match"

**Solution:**
1. Get the correct SHA-1 (Step 2)
2. Update Firebase Console with exact SHA-1 (without colons)
3. Re-download google-services.json
4. Rebuild app

### Issue: Backend returns "Invalid Google token"

**Possible causes:**
1. Token has expired (ID tokens last ~1 hour)
2. GOOGLE_OAUTH_CLIENT_ID not configured in backend
3. Token verification library not installed

**Solution:**
```bash
cd backend
pip install google-auth google-auth-httplib2 google-auth-oauthlib
```

---

## 📚 Backend Verification Service

A ready-to-use verification service is provided in:
- **File:** `backend/users/services/google_auth.py`
- **Example:** `backend/users/services/google_auth_example.py`

Usage:
```python
from users.services.google_auth import GoogleTokenVerifier

verifier = GoogleTokenVerifier()
user, created = verifier.verify_and_authenticate_user(id_token)
tokens = AuthService.issue_tokens(user)
```

---

## 🔐 Security Checklist

- [ ] SHA-1 fingerprint registered in Firebase
- [ ] google-services.json downloaded and placed correctly
- [ ] GOOGLE_OAUTH_CLIENT_ID set in Django settings
- [ ] Google authentication enabled in Firebase Console
- [ ] serverClientId configured in Flutter code
- [ ] ID token validation implemented on backend
- [ ] Tokens stored securely in Flutter
- [ ] HTTPS enforced in production

---

## 📖 References

- [Google Sign-In for Flutter](https://pub.dev/packages/google_sign_in)
- [Firebase Authentication Setup](https://firebase.google.com/docs/auth/flutter/start)
- [Google OAuth 2.0 Documentation](https://developers.google.com/identity/protocols/oauth2)
- [Firebase Project Setup](https://firebase.google.com/docs/projects/learn-more)

---

## 💡 Additional Tips

1. **Test with both signed and unsigned keys** before releasing
2. **Use environment variables** for client IDs in production
3. **Implement token refresh** if tokens expire during session
4. **Add error boundaries** around Google Sign-In calls
5. **Log authentication events** for debugging

---

**Version:** 1.0  
**Last Updated:** 2026-05-06  
**Status:** ✅ Ready for Implementation
