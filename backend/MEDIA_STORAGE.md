# Production media storage with Cloudflare R2

PrepMate stores profile images, uploaded resumes, generated PDFs, and thumbnails
as private objects in Cloudflare R2. The API returns short-lived signed download
URLs; the bucket must not be public.

## Create the Cloudflare resources

1. In Cloudflare, open **R2 Object Storage** and create a bucket such as
   `prepmate-production-media`. Keep public access disabled.
2. Open **Manage R2 API tokens** and create a token scoped to only that bucket
   with **Object Read & Write** permission. Do not use an account-wide token.
3. Record the access-key ID, secret-access key, and S3 endpoint. The endpoint is
   `https://<ACCOUNT_ID>.r2.cloudflarestorage.com`; it does not include the
   bucket name.
4. Add a lifecycle rule appropriate for your retention policy. R2's S3 API does
   not provide bucket versioning, so lifecycle rules are not a replacement for
   a separate backup of irreplaceable user uploads.

The native Flutter app does not need a bucket CORS policy. If a browser frontend
later downloads signed R2 URLs directly, add an R2 CORS rule that permits only
the exact production frontend origin and required `GET`/`HEAD` methods; do not
make the bucket public.

Never put R2 credentials in `.env` committed to Git or paste them into an issue
or chat.

## Configure production

Set these secrets on the Render `prepmate-api` service. The Blueprint shares
them with maintenance jobs without duplicating the secret values.

```env
MEDIA_STORAGE_BACKEND=r2
R2_MEDIA_BUCKET=prepmate-production-media
R2_ENDPOINT_URL=https://ACCOUNT_ID.r2.cloudflarestorage.com
R2_ACCESS_KEY_ID=<scoped token access key>
R2_SECRET_ACCESS_KEY=<scoped token secret>
R2_REGION=auto
R2_SIGNED_URL_EXPIRY_SECONDS=300
```

Database-backup credentials (`BACKUP_S3_*` and `AWS_*`) remain separate. Give
media and backups separate buckets and tokens so either credential can be
rotated or revoked independently.

## Migrate existing local media

For a new deployment with no production media, skip this section. If production
already has files on a Render disk, keep that disk attached until this command
has completed successfully.

First run a dry run inside the old service shell:

```powershell
python manage.py migrate_media_to_object_storage --source-root /app/media
```

Then copy and verify every object:

```powershell
python manage.py migrate_media_to_object_storage --source-root /app/media --apply --verify
```

The command never deletes the source. Run it again safely if interrupted; it
skips existing keys and verifies their size and SHA-256 digest. Only after the
application has served migrated files successfully should you remove the old
persistent disk.

## Deployment smoke test

1. Deploy and confirm `GET /health/` returns HTTP 200.
2. Upload a resume and profile image.
3. Generate an optimized resume and open its PDF and thumbnail.
4. Confirm the returned object URL contains a short-lived signature and that
   the bucket has no public development URL or custom public domain enabled.
5. Delete a test object through the application and confirm it disappears from
   R2.

If an R2 key was exposed, revoke it in Cloudflare, create a replacement scoped
token, and update the Render secret immediately.
