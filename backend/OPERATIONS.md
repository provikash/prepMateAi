# Production monitoring and maintenance

Private user uploads and generated resume PDFs use Cloudflare R2 in production.
Bucket provisioning, token scope, migration, and verification are documented in
[MEDIA_STORAGE.md](MEDIA_STORAGE.md). Keep media credentials separate from the
database-backup credentials described below.

## Monitoring

### Sentry

Create a Sentry Python/Django project and set `SENTRY_DSN` in Render. Production
settings reject a deployment without it. The integration sends exceptions and
sampled performance traces, but does not send request bodies or default PII.

Recommended Sentry alert rules:

- alert on every new issue and any regression;
- alert when the `provider` tag is `fast2sms` or `openrouter`;
- alert when the five-minute failure rate exceeds 5%;
- alert when API p95 transaction duration exceeds 1.5 seconds for 10 minutes;
- route warnings to email and production failures to the on-call destination.

Provider reports contain provider name, failure category, HTTP status where
available, and AI model name. They never contain OTP values, API keys, phone
numbers, resume text, prompts, or provider response bodies.

### Health and request monitoring

- `/health/live/` confirms that the Django process is alive.
- `/health/` is the readiness check used by Render. It verifies both PostgreSQL
  and Redis with bounded operations and returns HTTP 503 when either is down.
- Every request log includes its request ID, status, duration, and a `slow`
  flag. Responses of 500 or higher are error logs. Slow and 4xx responses are
  warning logs.

In **Render > Integrations > Notifications**, connect email or Slack and choose
at least **Only failure notifications**. Render will then alert when `/health/`
keeps failing, a deploy fails, or a maintenance cron job exits unsuccessfully.
Use an independent uptime service to probe `/health/` from outside Render as a
second signal.

## Scheduled maintenance

`render.yaml` defines these UTC schedules:

| Schedule | Command | Purpose |
| --- | --- | --- |
| Daily 00:15 | `cleanup_expired_otp --retention-days 7 --apply` | Remove OTP audit records after retention |
| Daily 00:30 | `flushexpiredtokens` | Remove expired SimpleJWT blacklist records |
| Every 15 minutes | `reconcile_ai_credits --stale-minutes 30 --apply` | Release stale AI reservations and repair totals |
| Every 15 minutes | `monitor_optimization_sessions --stale-minutes 30 --failure-lookback-minutes 20 --apply` | Mark stuck optimizer sessions failed and alert |
| Daily 02:00 | `backup_database` | Verify and upload an encrypted PostgreSQL dump |

The optimizer monitor exits unsuccessfully only for a newly detected failure.
Redis suppresses repeated alerts for the same session for 24 hours.

## Database backup policy

Use a paid Render PostgreSQL plan so point-in-time recovery remains enabled.
The independent daily backup job additionally requires:

```env
BACKUP_S3_BUCKET=your-private-backup-bucket
BACKUP_S3_PREFIX=prepmate
BACKUP_S3_REGION=ap-south-1
AWS_ACCESS_KEY_ID=limited-backup-writer-key
AWS_SECRET_ACCESS_KEY=limited-backup-writer-secret
```

For another S3-compatible provider, also set `BACKUP_S3_ENDPOINT`. The IAM
identity should only be able to upload objects beneath the configured prefix.
Block public access, enable bucket versioning, and configure lifecycle retention.
The command creates a PostgreSQL custom-format dump, verifies it with
`pg_restore --list`, enables server-side encryption, uploads it, and removes the
temporary local file.

Perform a restore drill at least quarterly. A backup is not considered reliable
until it has been restored into an isolated database and checked.

## Useful manual checks

```powershell
python manage.py cleanup_expired_otp --retention-days 7
python manage.py reconcile_ai_credits --stale-minutes 30
python manage.py monitor_optimization_sessions --stale-minutes 30
python manage.py audit_ai_credits
```

The cleanup and reconciliation commands are dry-run unless `--apply` is given.
