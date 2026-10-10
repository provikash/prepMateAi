import re
import warnings
from collections import Counter

from django.db import migrations, models
import django.db.models.functions.text
import django.utils.timezone
import uuid


def normalize(value):
    digits = re.sub(r"[\s-]", "", (value or "").strip())
    if digits.startswith("+"):
        digits = digits[1:]
    if digits.startswith("91") and len(digits) == 12:
        digits = digits[2:]
    elif digits.startswith("0") and len(digits) == 11:
        digits = digits[1:]
    if len(digits) == 10 and digits[0] in "6789" and digits.isdigit():
        return "+91" + digits
    return None


def copy_unambiguous_profile_phones(apps, schema_editor):
    User = apps.get_model("users", "User")
    Profile = apps.get_model("users", "UserProfile")
    candidates = []
    invalid = []
    for profile in Profile.objects.exclude(phone="").iterator():
        value = normalize(profile.phone)
        if value:
            candidates.append((profile.user_id, value))
        else:
            invalid.append((profile.user_id, profile.phone))
    counts = Counter(value for _, value in candidates)
    duplicate_values = {value for value, count in counts.items() if count > 1}
    for user_id, value in candidates:
        if value not in duplicate_values:
            User.objects.filter(pk=user_id, phone_number__isnull=True).update(phone_number=value)
    if invalid:
        warnings.warn(f"Skipped {len(invalid)} invalid legacy profile phone value(s); user IDs: {[row[0] for row in invalid]}")
    if duplicate_values:
        affected = [user_id for user_id, value in candidates if value in duplicate_values]
        warnings.warn(f"Skipped duplicate normalized profile phone value(s); user IDs: {affected}")


class Migration(migrations.Migration):
    dependencies = [("users", "0009_emailotp_alter_user_options_user_created_at_and_more")]
    operations = [
        migrations.RemoveConstraint(model_name="user", name="users_email_ci_unique"),
        migrations.AlterField(model_name="user", name="email", field=models.EmailField(blank=True, max_length=255, null=True, unique=True)),
        migrations.AlterField(model_name="user", name="name", field=models.CharField(blank=True, default="", max_length=255)),
        migrations.AddField(model_name="user", name="phone_number", field=models.CharField(blank=True, max_length=13, null=True)),
        migrations.AddField(model_name="user", name="is_phone_verified", field=models.BooleanField(default=False)),
        migrations.AddField(model_name="user", name="phone_verified_at", field=models.DateTimeField(blank=True, null=True)),
        migrations.AddField(model_name="user", name="profile_completed", field=models.BooleanField(default=False)),
        migrations.RunPython(copy_unambiguous_profile_phones, migrations.RunPython.noop),
        migrations.AddConstraint(model_name="user", constraint=models.UniqueConstraint(django.db.models.functions.text.Lower("email"), condition=models.Q(("email__isnull", False)), name="users_email_ci_unique")),
        migrations.AddConstraint(model_name="user", constraint=models.UniqueConstraint(condition=models.Q(("phone_number__isnull", False)), fields=("phone_number",), name="users_phone_unique_not_null")),
        migrations.CreateModel(
            name="OTPChallenge",
            fields=[
                ("id", models.UUIDField(default=uuid.uuid4, editable=False, primary_key=True, serialize=False)),
                ("phone_number", models.CharField(db_index=True, max_length=13)),
                ("purpose", models.CharField(choices=[("authentication", "Authentication"), ("change_phone", "Change phone"), ("account_recovery", "Account recovery")], default="authentication", max_length=32)),
                ("otp_hash", models.CharField(max_length=128)),
                ("expires_at", models.DateTimeField(db_index=True)),
                ("attempts", models.PositiveSmallIntegerField(default=0)),
                ("maximum_attempts", models.PositiveSmallIntegerField(default=5)),
                ("resend_available_at", models.DateTimeField()),
                ("consumed_at", models.DateTimeField(blank=True, null=True)),
                ("invalidated_at", models.DateTimeField(blank=True, null=True)),
                ("provider_message_id", models.CharField(blank=True, default="", max_length=128)),
                ("provider_status", models.CharField(blank=True, default="", max_length=64)),
                ("request_ip_hash", models.CharField(blank=True, default="", max_length=64)),
                ("device_id_hash", models.CharField(blank=True, default="", max_length=64)),
                ("created_at", models.DateTimeField(default=django.utils.timezone.now, editable=False)),
            ],
            options={"indexes": [models.Index(fields=["phone_number", "purpose", "-created_at"], name="users_phone_otp_lookup")]},
        ),
        migrations.AddConstraint(model_name="otpchallenge", constraint=models.UniqueConstraint(condition=models.Q(("consumed_at__isnull", True), ("invalidated_at__isnull", True)), fields=("phone_number", "purpose"), name="users_one_active_phone_otp")),
    ]
