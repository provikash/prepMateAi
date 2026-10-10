# Admin-managed AI credits

AI credits use an append-only ledger. Staff must not edit database balances or
transaction rows directly.

## Django Admin

1. Open `/admin/` and sign in with a Django superuser.
2. Open **Users** and use the **AI credits** link, or open
   **AI > AI credit accounts** and search by phone, email, name, or username.
3. Enter a **Credit adjustment**:
   - positive values grant credits, for example `100`;
   - negative values deduct credits, for example `-25`.
4. Enter a required audit reason and save.

The balance, reservations, lifetime totals, transactions, and usage records are
read-only. A deduction is rejected if it would make the balance negative or
consume credits reserved by an in-progress AI request. Duplicate form
submissions use an idempotency token and cannot apply the same adjustment twice.

Every adjustment records the staff user, reason, amount, previous balance, new
balance, timestamp, and idempotency key. Transaction and AI usage records can be
viewed in Django Admin but cannot be edited or deleted there.

## Command line fallback

Use the audited command when Django Admin is unavailable:

```powershell
python manage.py grant_ai_credits +919876543210 100 --reason "Launch allocation"
```

The command accepts an email address or phone number. It only grants a positive
amount; deductions must be reviewed and performed through Django Admin.

## Operational checks

```powershell
python manage.py audit_ai_credits
python manage.py reconcile_ai_credits
```

`reconcile_ai_credits` is dry-run by default. Only use `--apply` after reviewing
its output.
