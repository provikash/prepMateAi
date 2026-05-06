# Google Sign-In Quick Reference

## ⚡ Quick Setup (5-10 minutes)

### 1️⃣ Get Web Client ID
```
Firebase Console → Project Settings → Service Accounts → Web Client ID
Example: 123456789-abc123def456.apps.googleusercontent.com
```

### 2️⃣ Get SHA-1 Fingerprint
```powershell
# Windows PowerShell
cd C:\Users\<YourUsername>\.android
keytool -list -v -keystore debug.keystore -alias androiddebugkey `
  -storepass android -keypass android
```
Look for: **SHA1: AB:CD:EF:...**

### 3️⃣ Update Firebase Console
```
Firebase → Service Accounts → Edit Android client
- Package: com.example.prepmate_mobile
- SHA-1: ABCDEF0123456789... (no colons)
```

### 4️⃣ Download google-services.json
```
Firebase → Project Settings → Your apps → Android → Download
Place at: prepmate_mobile/android/app/google-services.json
```

### 5️⃣ Update Flutter Code
```dart
// In auth_remote_data_source.dart (already done)
await _googleSignIn.initialize(
  serverClientId: 'YOUR_WEB_CLIENT_ID.apps.googleusercontent.com',
  scopes: ['email', 'profile'],
);
```

### 6️⃣ Enable Google Auth
```
Firebase → Authentication → Sign-in method → Enable Google
```

### 7️⃣ Configure Backend
```python
# settings.py
GOOGLE_OAUTH_CLIENT_ID = 'YOUR_WEB_CLIENT_ID.apps.googleusercontent.com'
```

### 8️⃣ Test
```bash
cd prepmate_mobile
flutter clean && flutter pub get && flutter run
```

---

## ✅ What's Already Done

- ✔ Flutter code updated with serverClientId support
- ✔ Android build.gradle configured for Firebase
- ✔ google-services.json template created
- ✔ Backend verification service implemented
- ✔ Comprehensive setup guide provided

---

## ❌ Common Error & Fix

**Error:** `GoogleSignInException: serverClientId must be provided on Android`

**Fix:** Replace `YOUR_WEB_CLIENT_ID` with your actual Firebase Web Client ID

```dart
await _googleSignIn.initialize(
  serverClientId: '123456789-abcdefghijklmnopqrstuvwxyz.apps.googleusercontent.com',  // ← Real ID here
);
```

---

## 📂 Files to Update

1. **auth_remote_data_source.dart** - ✅ Already updated
2. **google-services.json** - 📝 Template ready at `android/app/`
3. **build.gradle.kts** - ✅ Already updated
4. **settings.gradle.kts** - ✅ Already updated
5. **Django settings.py** - 📝 Add GOOGLE_OAUTH_CLIENT_ID

---

## 🔗 Full Setup Guide
See: `GOOGLE_SIGNIN_SETUP.md`

---

## 📊 ID Mapping Reference

```
INCORRECT (Don't use):
❌ Android Client ID
❌ iOS Client ID
❌ Service Account Key ID

CORRECT (Use this):
✅ Web OAuth 2.0 Client ID (from Firebase Service Accounts)
```

---

## 🚀 Testing Checklist

- [ ] SHA-1 in Firebase Console
- [ ] google-services.json downloaded
- [ ] serverClientId updated in Flutter
- [ ] GOOGLE_OAUTH_CLIENT_ID in backend
- [ ] Google auth enabled in Firebase
- [ ] `flutter clean && flutter run` works
- [ ] Sign-in button tap opens Google UI
- [ ] Token sent to backend successfully

---

**Last Updated:** 2026-05-06
