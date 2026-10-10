# Flutter Web deployment

PrepMate Web is the same Riverpod and `go_router` application used by the
Android and iOS builds. The browser bundle contains public configuration only;
all OTP, AI, payment, PDF, object-storage, and database operations continue to
run through the Django API.

## Build

Use the real HTTPS API origin and keep the `/api/v1/` suffix:

```powershell
flutter build web --release `
  --dart-define=APP_ENV=production `
  --dart-define=API_BASE_URL=https://api.example.com/api/v1/
```

Deploy the contents of `build/web`. Do not publish source maps. A Wasm dry run
is part of the normal release compiler, but CanvasKit remains the production
default until PDF viewing, payment redirection, downloads, printing, and the
supported browser matrix have been exercised with `flutter build web --wasm`.

## Hosting requirements

- Serve every unknown application path from `/index.html` with status 200.
- Serve HTTPS only and redirect HTTP to HTTPS.
- Compress text assets with Brotli or gzip.
- Do not cache `index.html`; cache fingerprinted assets for one year.
- Apply the security headers in `web/_headers` at the CDN or reverse proxy.
- Keep staging and production deployments on separate origins.
- Retain the previous artifact for rollback.

`web/_redirects` and `web/_headers` work directly on hosts that support the
Netlify-style files. For another provider, translate the same rules into its
native configuration.

## Backend environment

The browser origin must be explicit—never use `*` with authenticated traffic:

```env
DJANGO_ENV=production
DEBUG=False
ALLOWED_HOSTS=api.example.com
CORS_ALLOWED_ORIGINS=https://app.example.com
CSRF_TRUSTED_ORIGINS=https://app.example.com
ENABLE_TEST_OTP_LOGIN=False
```

The existing bearer-token flow uses centralized short-lived token refresh and
single-flight renewal. Browser storage cannot provide HttpOnly protection, so a
future cookie-session migration must be coordinated with Django CSRF handling,
refresh rotation, revocation, and logout invalidation; it must not be changed
only in the client.

## Smoke test

1. Open `/sign-in` directly and complete OTP authentication.
2. Open `/resumes`, `/optimizations`, and a nested preview URL in a new tab.
3. Refresh each nested route and use browser Back and Forward.
4. Create and edit a resume, then download and print its backend PDF.
5. Run an optimization and verify conflict, insufficient-credit, and retry UI.
6. Exercise payment pending, cancel, and backend-verified success states.
7. Test Chrome, Edge, Firefox, and Safari where available at 100% and 200% zoom.
8. Repeat the primary flow at 390, 768, 1024, 1440, and 1920 logical pixels.
