# Backend deployment

The backend is packaged as a production Docker service. It requires PostgreSQL,
Redis, private Cloudflare R2 media storage, Fast2SMS credentials, and an
OpenRouter API key. SQLite, local production media, and Django's in-memory cache
are intentionally rejected because they lose or split data when a service
restarts, scales, or uses multiple workers.

## Recommended: Render Blueprint

1. Push the repository to GitHub. Never commit `backend/.env`.
2. In Render, choose **New > Blueprint** and connect the repository. Render reads
   the root `render.yaml` and creates the API, PostgreSQL database, Redis-compatible
   Key Value service, and scheduled maintenance jobs.
3. When prompted, enter these secret variables:
   - `FAST2SMS_API_KEY`
   - `FAST2SMS_OTP_ID`
   - `OPENROUTER_API_KEY`
   - `SENTRY_DSN`
   - `R2_MEDIA_BUCKET`, `R2_ENDPOINT_URL`, `R2_ACCESS_KEY_ID`, and
     `R2_SECRET_ACCESS_KEY` from a bucket-scoped Cloudflare token
   - the S3 backup bucket and restricted writer credentials requested for the
     database-backup cron job
4. Deploy the Blueprint. Startup runs Django's deployment checks, migrations,
   template seeding, and static collection before Gunicorn starts.
5. Open `https://<your-render-host>/health/`. A successful deployment returns
   `status: ok` with successful database and cache checks.
6. In Render, connect email or Slack under **Integrations > Notifications** and
   enable failure notifications. This activates alerts for failed health checks,
   deploys, and maintenance jobs.

See [backend/OPERATIONS.md](backend/OPERATIONS.md) for Sentry alert rules,
maintenance schedules, backup retention, and restore testing. See
[backend/MEDIA_STORAGE.md](backend/MEDIA_STORAGE.md) for bucket creation,
existing-media migration, access policy, and smoke tests.

If you use a browser frontend, also set:

```env
CSRF_TRUSTED_ORIGINS=https://your-frontend.example.com,https://your-api.onrender.com
CORS_ALLOWED_ORIGINS=https://your-frontend.example.com
```

The native Flutter Android/iOS app does not require a CORS origin.

## Any Docker platform

Use `backend/Dockerfile` with `backend` as the Docker build context. Copy the
variables from `backend/.env.example` into the platform's secret/environment
settings. Do not upload the `.env` file itself.

Required infrastructure and settings:

- `DATABASE_URL`: PostgreSQL connection URL.
- `CACHE_LOCATION`: Redis connection URL.
- `ALLOWED_HOSTS`: API hostname without `https://`.
- `TRUST_PROXY_HEADERS=True`: only when the platform proxy overwrites
  `X-Forwarded-Proto` and the container is not directly public.
- A private Cloudflare R2 bucket and bucket-scoped Object Read & Write token.
- `FAST2SMS_API_KEY`, `FAST2SMS_OTP_ID`, and `OPENROUTER_API_KEY`.
- `SENTRY_DSN` for exception, provider-failure, latency, and error-rate monitoring.

The container listens on the platform-provided `PORT` and exposes `/health/`.

## Point Flutter at production

Build the application with the deployed API base URL (keep `/api/v1/`):

```powershell
flutter build apk --release --dart-define=API_BASE_URL=https://your-api-host/api/v1/
```

For an Android App Bundle:

```powershell
flutter build appbundle --release --dart-define=API_BASE_URL=https://your-api-host/api/v1/
```

## Pre-deployment checks

Before pushing, run:

```powershell
cd backend
python manage.py test --settings=core.test_settings
```

After deployment, verify `/health/`, request and verify a real OTP, upload a
resume, run resume optimization, and download the generated PDF.

## Security

Rotate any API keys, SMTP passwords, or Django secrets that were ever pasted into
chat, committed, or included in a shared `.env` file. Production must keep
`DEBUG=False` and `ENABLE_TEST_OTP_LOGIN=False`.
