# Mobile OTP authentication

PrepMate authenticates mobile clients only with an Indian mobile number and a one-time SMS code. Email remains optional contact/profile data. Public email/password, password-reset, and Google endpoints are removed; Django admin password authentication remains separate.

## API

All routes are below `/api/v1/`:

- `POST auth/otp/request/` with `{"phone_number":"9876543210"}`
- `POST auth/otp/verify/` with `{"challenge_id":"<uuid>","phone_number":"9876543210","otp":"654321"}`
- `POST auth/otp/resend/` with `{"challenge_id":"<uuid>","phone_number":"9876543210"}`
- `POST auth/token/refresh/` with `{"refresh":"<refresh-token>"}`
- `POST auth/logout/` with `{"refresh":"<refresh-token>"}` and a Bearer access token
- `POST auth/logout-all/` with a Bearer access token; immediately revokes all access and refresh tokens
- `GET/PATCH auth/me/`; `phone_number` is read-only here

Account lifecycle routes require a Bearer access token:

- `POST auth/phone/change/request/` with `{"phone_number":"8765432109"}`
- `POST auth/phone/change/verify/` with the new `phone_number`, `challenge_id`, and `otp`; all sessions are revoked after success
- `POST auth/account/verification/request/` with `{"action":"deactivate"}` or `{"action":"delete"}`
- `POST auth/account/deactivate/` with `challenge_id` and `otp`; a later verified login reactivates a user-deactivated account
- `DELETE auth/account/` with `challenge_id` and `otp`; permanently removes the user, owned database records, and owned media

Lifecycle challenges are bound to the requesting user, action, purpose, and phone number. They cannot be exchanged between accounts or reused for a more sensitive action. Administratively disabled accounts are not automatically reactivated.

Phone input is normalized to `+91XXXXXXXXXX`. Only ten-digit Indian mobile numbers beginning with 6–9 are accepted. Error responses include a stable `code` such as `invalid_phone_number`, `otp_invalid`, `otp_expired`, `otp_attempts_exceeded`, `challenge_consumed`, `resend_not_available`, `otp_rate_limited`, `provider_unavailable`, or `account_disabled`.

Optional emails are normalized to lowercase and remain case-insensitively unique. They are editable profile/contact data only and are never accepted by an authentication endpoint. Authentication phone numbers are read-only through general profile APIs and can only be changed by verifying an OTP sent to the new number.

## Fast2SMS and DLT

Production uses Fast2SMS's current `POST https://www.fast2sms.com/dev/otp/send` endpoint. Configure a Fast2SMS account, any required KYC, a registered DLT entity, approved sender/header, an approved OTP template, sufficient wallet balance, and a production API key. The approved server-side OTP template must exactly match the DLT registration. Set `FAST2SMS_DLT_TEMPLATE_ID` to the Fast2SMS OTP template ID (`otp_id`).

Required production variables are listed in `backend/.env.example`. In particular, set `OTP_PROVIDER=fast2sms`, `FAST2SMS_API_KEY`, and `FAST2SMS_DLT_TEMPLATE_ID`; keep these values only on the backend. Production startup rejects missing provider configuration, a local cache, or an enabled test OTP login.

Local development should use `OTP_PROVIDER=console`. This provider intentionally does not print the OTP. Automated tests mock deterministic generation/provider behavior and never contact Fast2SMS.

The optional test login is disabled by default and requires all of: `DJANGO_ENV=development` or `test`, `DEBUG=True`, `ENABLE_TEST_OTP_LOGIN=True`, an explicit `TEST_OTP_PHONE_NUMBERS` allowlist, and a secret `TEST_OTP_CODE`. Production startup rejects it.

## Migration and rollback

1. Back up the database and test the migration on a production snapshot.
2. Run `python manage.py migrate`. Migration `users.0010_mobile_otp_auth` keeps the existing user table/IDs and adds nullable phone verification fields plus OTP challenges. Migration `users.0011_account_lifecycle` adds action-bound lifecycle challenges and reversible user-deactivation state.
3. The data migration normalizes unambiguous values from `UserProfile.phone`. It warns and skips invalid or duplicate normalized values rather than assigning them silently.
4. Review warnings and remediate affected accounts before requiring a phone for legacy users. The database enforces uniqueness only for non-null phone numbers.
5. Deploy the backend before the mobile release. Old auth URLs return 404, so coordinate the client rollout if an older app is deployed.

Rollback the application before reversing the migration. `python manage.py migrate users 0009` removes the new OTP schema/fields but preserves all pre-existing users and feature foreign keys. Export newly created mobile accounts first if their data must survive rollback.

## Flutter

Run with an API URL ending in `/api/v1/`:

```console
flutter run --dart-define=API_BASE_URL=https://api.example.com/api/v1/
```

JWTs are stored with `flutter_secure_storage`. Startup restores the session through the access/refresh tokens and `/auth/me/`; it never requests an OTP automatically. Refresh is single-flight and a rejected refresh clears secure credentials. New/incomplete users go to profile onboarding; completed users go home.

## Production checklist

- PostgreSQL migration reviewed and applied; skipped legacy phone warnings resolved.
- Redis configured through `django-redis` for cross-worker limits.
- Fast2SMS KYC/DLT entity/header/template approved and wallet funded.
- API key and template ID present only in backend secrets.
- HTTPS, explicit hosts/origins, strong `SECRET_KEY`, secure cookies, and proxy settings verified.
- Request/verify/resend, token rotation/logout, onboarding, returning session restoration, and provider failure paths smoke-tested.
- Monitor masked structured OTP events, rate limits, provider failures, send/verification/resend rates, and Fast2SMS billing.
