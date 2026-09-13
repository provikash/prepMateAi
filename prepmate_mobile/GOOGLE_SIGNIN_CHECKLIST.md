# ✅ Google Sign-In Implementation Checklist

Complete this checklist to implement the Google Sign-In fix.

---

## 📋 Pre-Implementation

- [ ] Read [GOOGLE_SIGNIN_FIX_SUMMARY.md](GOOGLE_SIGNIN_FIX_SUMMARY.md) (2 min)
- [ ] Choose a setup guide based on your style:
  - [ ] [GOOGLE_SIGNIN_QUICKREF.md](GOOGLE_SIGNIN_QUICKREF.md) (5 min, quick steps)
  - [ ] [GOOGLE_SIGNIN_SETUP.md](GOOGLE_SIGNIN_SETUP.md) (20 min, detailed)
  - [ ] [GOOGLE_SIGNIN_EXAMPLES.md](GOOGLE_SIGNIN_EXAMPLES.md) (code examples)
- [ ] Understand the issue (serverClientId = Firebase Web Client ID, NOT Android ID)
- [ ] Have your Firebase project ready

---

## 🔐 Firebase Console Setup

### Get Web Client ID
- [ ] Go to [Firebase Console](https://console.firebase.google.com)
- [ ] Select your project
- [ ] Click Project Settings (gear icon)
- [ ] Go to "Service Accounts" tab
- [ ] Find the **Web OAuth 2.0 Client ID**
- [ ] Copy it: `___________________________________________`
  (Save it somewhere safe)

### Get SHA-1 Fingerprint (Debug Key)

**Windows PowerShell:**
- [ ] Open PowerShell
- [ ] Run: `cd C:\Users\<YourUsername>\.android`
- [ ] Run: `keytool -list -v -keystore debug.keystore -alias androiddebugkey -storepass android -keypass android`
- [ ] Find the line starting with "SHA1:"
- [ ] Copy the SHA1 value (remove colons): `___________________________________________`

**macOS/Linux:**
- [ ] Open terminal
- [ ] Run: `keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android`
- [ ] Find the line starting with "SHA1:"
- [ ] Copy the SHA1 value (remove colons): `___________________________________________`

### Update Firebase Console
- [ ] Firebase Console → Project Settings
- [ ] Find your **Android app** in "Your apps"
- [ ] Click the three dots → "Edit"
- [ ] Find the **Android OAuth Client**
- [ ] Update the **SHA-1 certificate hash** field with your fingerprint
- [ ] Save changes
- [ ] ⏱️ Wait a few seconds for changes to propagate

### Download google-services.json
- [ ] Firebase Console → Project Settings
- [ ] Find your **Android app** in "Your apps"
- [ ] Click three dots → **Download google-services.json**
- [ ] Save the file to: `prepmate_mobile/android/app/google-services.json`
- [ ] Verify file is in correct location: `android/app/google-services.json`

### Enable Google Authentication
- [ ] Firebase Console → **Authentication**
- [ ] Click **Sign-in method** tab
- [ ] Find **Google** in the list
- [ ] Click on it and toggle **Enable**
- [ ] Verify your Web Client ID is shown
- [ ] Save

---

## 💻 Code Updates

### Update Flutter Code
- [ ] Open: `prepmate_mobile/lib/features/auth/data/datasources/auth_remote_data_source.dart`
- [ ] Find line with: `serverClientId: 'YOUR_WEB_CLIENT_ID.apps.googleusercontent.com',`
- [ ] Replace `YOUR_WEB_CLIENT_ID` with your actual Web Client ID (from Firebase Console)
- [ ] **Example:** If your ID is `123456789-abc123.apps.googleusercontent.com`, make it:
  ```dart
  serverClientId: '123456789-abc123.apps.googleusercontent.com',
  ```
- [ ] Save the file

### Verify google-services.json Location
- [ ] Check file exists: `prepmate_mobile/android/app/google-services.json`
- [ ] Open it and verify it contains your Firebase config
- [ ] Look for your project_id, package name, etc.
- [ ] If missing values, re-download from Firebase Console

### Verify Android Build Files
- [ ] Open: `prepmate_mobile/android/app/build.gradle.kts`
- [ ] Verify it contains: `id("com.google.gms.google-services")`
- [ ] Open: `prepmate_mobile/android/settings.gradle.kts`
- [ ] Verify it contains: `id("com.google.gms.google-services") version "4.4.0" apply false`
- [ ] Both files should already be updated ✅

---

## 🔧 Backend Configuration

### Update Django Settings
- [ ] Open: `backend/settings.py`
- [ ] Find or add the section:
  ```python
  import os
  GOOGLE_OAUTH_CLIENT_ID = os.environ.get(
      'GOOGLE_OAUTH_CLIENT_ID',
      'YOUR_WEB_CLIENT_ID.apps.googleusercontent.com'
  )
  ```
- [ ] Replace `YOUR_WEB_CLIENT_ID` with your actual Web Client ID
- [ ] Save the file

### Optional: Use Backend Verification Service
- [ ] Review: `backend/users/services/google_auth.py`
- [ ] Review: `backend/users/services/google_auth_example.py`
- [ ] Update your views.py to use GoogleTokenVerifier (see example file)
- [ ] This is optional but recommended for production

### Verify Dependencies
- [ ] Open terminal in backend directory
- [ ] Run: `pip list | grep google`
- [ ] Verify you have:
  - [ ] `google-auth`
  - [ ] `google-auth-httplib2`
  - [ ] `google-auth-oauthlib`
- [ ] If missing, run: `pip install google-auth google-auth-httplib2 google-auth-oauthlib`

---

## 🧪 Testing

### Build the App
- [ ] Open terminal in `prepmate_mobile` directory
- [ ] Run: `flutter clean`
- [ ] Run: `flutter pub get`
- [ ] Run: `flutter run`
- [ ] Wait for app to build and launch
- [ ] Check logs for any errors (should be none)

### Test Google Sign-In
- [ ] Tap "Sign in with Google" button
- [ ] ❌ If you see "serverClientId must be provided" error → Go back to "Code Updates" section
- [ ] ✅ If Google Sign-In UI appears → Continue below
- [ ] Sign in with your Google account
- [ ] Verify you're redirected back to app
- [ ] Check that tokens are displayed/saved

### Test Backend Integration
- [ ] After successful Google Sign-In in app
- [ ] Check backend logs (if running locally)
- [ ] Look for "Google login successful" message
- [ ] Verify new user created in database:
  ```bash
  # From Django shell
  python manage.py shell
  >>> from users.models import User
  >>> User.objects.filter(email='your_google_email@gmail.com').first()
  ```
- [ ] Verify user is authenticated in app

### Optional: Test with curl
- [ ] Get an ID token from the app (check logs)
- [ ] Run:
  ```bash
  curl -X POST http://localhost:8000/api/v1/auth/google/ \
    -H "Content-Type: application/json" \
    -d '{"id_token": "YOUR_TOKEN_HERE"}'
  ```
- [ ] Verify response includes tokens and user data

---

## ✅ Verification Checklist

After implementation, verify:

- [ ] No "serverClientId" errors in app logs
- [ ] Google Sign-In UI appears when tapping button
- [ ] Can complete Google authentication
- [ ] App receives ID token successfully
- [ ] Backend receives token at `/auth/google/` endpoint
- [ ] Backend returns JWT tokens
- [ ] User created in database automatically
- [ ] Can log in with existing Google account
- [ ] App stores tokens securely
- [ ] Can access protected API endpoints

---

## 🐛 If Something Fails

### Error: serverClientId must be provided on Android
**Solution:**
1. Check you replaced `YOUR_WEB_CLIENT_ID` with actual ID
2. Verify it's the **Web Client ID**, not Android Client ID
3. Run: `flutter clean && flutter pub get && flutter run`

### Error: SHA-1 certificate hash is wrong
**Solution:**
1. Get correct SHA-1 from your signing key (see Pre-Implementation)
2. Update Firebase Console with correct value (remove colons)
3. Re-download google-services.json
4. Place at: `android/app/google-services.json`

### Error: google-services.json not found
**Solution:**
1. Verify file is at: `android/app/google-services.json` (exact path)
2. Check file contents are valid JSON
3. Re-download from Firebase Console if corrupted

### Error: Invalid Google token from backend
**Solution:**
1. Verify GOOGLE_OAUTH_CLIENT_ID is set in `backend/settings.py`
2. Verify it matches your Web Client ID
3. Check token hasn't expired (ID tokens last ~1 hour)
4. Ensure google-auth library installed: `pip install google-auth`

### Error: com.google.android.gms.common.GooglePlayServicesNotAvailableException
**Solution:**
1. Make sure Google Play Services is installed on test device
2. Update google_sign_in package: `flutter pub get`
3. Rebuild: `flutter clean && flutter run`

---

## 📊 Implementation Progress

Track your progress:

| Phase | Status | Notes |
|-------|--------|-------|
| Pre-Implementation | ⬜ | Read docs, get Web Client ID |
| Firebase Setup | ⬜ | Get SHA-1, update Firebase Console |
| Code Updates | ⬜ | Update Flutter and Django code |
| Build & Test | ⬜ | Build app and test Google Sign-In |
| Backend Verification | ⬜ | Verify tokens received correctly |
| Database Check | ⬜ | Verify user created in database |
| Final Testing | ⬜ | Full end-to-end test |
| **COMPLETE** | ⬜ | All working! ✅ |

---

## 🎯 Success Metrics

You've succeeded when:

✅ App builds without errors  
✅ No "serverClientId" error when tapping Sign-In  
✅ Google Sign-In UI appears  
✅ Can complete authentication  
✅ Backend receives ID token  
✅ User created automatically  
✅ Can log in next time  
✅ Can access protected endpoints  

---

## 📞 Support Resources

If stuck, check these in order:

1. **Quick Reference:** [GOOGLE_SIGNIN_QUICKREF.md](GOOGLE_SIGNIN_QUICKREF.md)
2. **Troubleshooting:** [GOOGLE_SIGNIN_SETUP.md](GOOGLE_SIGNIN_SETUP.md#-common-issues)
3. **Code Examples:** [GOOGLE_SIGNIN_EXAMPLES.md](GOOGLE_SIGNIN_EXAMPLES.md)
4. **Full Documentation:** [GOOGLE_SIGNIN_SETUP.md](GOOGLE_SIGNIN_SETUP.md)

---

## ⏱️ Time Estimates

| Task | Time | Notes |
|------|------|-------|
| Read summary | 5 min | [GOOGLE_SIGNIN_FIX_SUMMARY.md](GOOGLE_SIGNIN_FIX_SUMMARY.md) |
| Firebase setup | 15 min | Get ID, SHA-1, download config |
| Code updates | 10 min | Update Flutter and Django |
| Build & test | 15 min | flutter run and verify |
| **Total** | **45 min** | For complete setup |

---

## 🎓 Learning Resources

- [Google Sign-In Flutter Docs](https://pub.dev/packages/google_sign_in)
- [Firebase Auth Setup](https://firebase.google.com/docs/auth/flutter/start)
- [OAuth 2.0 Protocol](https://developers.google.com/identity/protocols/oauth2)

---

## 📝 Notes

Use this space to track important information:

**Web Client ID:**  
`___________________________________________`

**SHA-1 Fingerprint:**  
`___________________________________________`

**Firebase Project ID:**  
`___________________________________________`

**Completion Date:**  
`___________________________________________`

---

**Checklist Version:** 1.0  
**Status:** ✅ Ready to Use  
**Last Updated:** 2026-05-06
