# PrepMate mobile

The Flutter app uses passwordless Indian mobile-number OTP authentication. It contains no email/password or Google sign-in flow. JWT access and refresh tokens are stored with `flutter_secure_storage`; the existing interceptor performs a single refresh for concurrent 401 responses and clears rejected sessions.

```console
flutter pub get
flutter run --dart-define=API_BASE_URL=https://api.example.com/api/v1/
flutter analyze
flutter test
```

The API URL must use HTTPS outside local development and end in `/api/v1/`. Fast2SMS credentials must never be supplied as Dart defines or included in the app. See [../AUTHENTICATION.md](../AUTHENTICATION.md) for backend, DLT, migration, and deployment details.
