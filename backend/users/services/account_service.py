from django.contrib.auth.password_validation import validate_password
from django.db import transaction
from django.utils import timezone
from rest_framework.exceptions import ValidationError
from rest_framework_simplejwt.token_blacklist.models import BlacklistedToken, OutstandingToken
from users.models import EmailOTP, User
from .otp_service import OTPService


class AccountService:
    @staticmethod
    @transaction.atomic
    def register(serializer):
        user = serializer.save()
        OTPService.issue(user, EmailOTP.Purpose.EMAIL_VERIFICATION)
        return user

    @staticmethod
    def verify(email, code, purpose, new_password=None):
        valid = False
        with transaction.atomic():
            user = User.objects.select_for_update().filter(email__iexact=email, is_active=True, deleted_at__isnull=True).first()
            if user:
                if new_password is not None:
                    validate_password(new_password, user)
                    if user.check_password(new_password):
                        raise ValidationError({"new_password": "Choose a different password."})
                valid = OTPService.consume_locked(user, code, purpose)
                if valid:
                    if purpose == EmailOTP.Purpose.EMAIL_VERIFICATION:
                        user.is_verified = True
                        user.save(update_fields=["is_verified", "updated_at"])
                    else:
                        user.set_password(new_password)
                        user.save(update_fields=["password", "updated_at"])
                        AccountService.revoke(user)
        if not valid:
            raise ValidationError({"otp": "Invalid or expired code."})
        return user

    @staticmethod
    def revoke(user):
        for token in OutstandingToken.objects.filter(user=user):
            BlacklistedToken.objects.get_or_create(token=token)
        EmailOTP.objects.filter(user=user, is_used=False).update(is_used=True)

    @staticmethod
    @transaction.atomic
    def change(user, current_password, new_password=None, deactivate=False, delete=False):
        user = User.objects.select_for_update().get(pk=user.pk)
        if not user.is_active or user.deleted_at or not user.check_password(current_password):
            raise ValidationError({"current_password": "Password confirmation failed."})
        if new_password is not None:
            validate_password(new_password, user)
            if user.check_password(new_password):
                raise ValidationError({"new_password": "Choose a different password."})
            user.set_password(new_password)
        if deactivate or delete:
            user.is_active = False
            user.set_unusable_password()
        if delete:
            user.deleted_at = timezone.now()
        user.save()
        AccountService.revoke(user)
