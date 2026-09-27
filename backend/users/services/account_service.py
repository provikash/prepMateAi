import logging

from django.contrib.auth.password_validation import validate_password
from django.db import transaction
from django.utils import timezone
from rest_framework.exceptions import ValidationError
from rest_framework_simplejwt.token_blacklist.models import BlacklistedToken, OutstandingToken
from users.models import EmailOTP, OTPChallenge, User
from .mobile_otp_service import MobileOTPService, OTPFlowError
from .otp_service import OTPService
from .phone_service import mask_phone


logger = logging.getLogger(__name__)


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
    def revoke(user, *, rotate_credentials=False):
        if rotate_credentials:
            user.set_unusable_password()
            user.save(update_fields=["password", "updated_at"])
        for token in OutstandingToken.objects.filter(user=user):
            BlacklistedToken.objects.get_or_create(token=token)
        EmailOTP.objects.filter(user=user, is_used=False).update(is_used=True)

    @staticmethod
    def revoke_all_sessions(user):
        with transaction.atomic():
            locked = User.objects.select_for_update().get(pk=user.pk)
            AccountService.revoke(locked, rotate_credentials=True)
        logger.info("account_sessions_revoked user_id=%s", user.pk)

    @staticmethod
    def _confirm_lifecycle_otp(user, challenge_id, otp, action):
        return MobileOTPService._consume_locked(
            challenge_id,
            user.phone_number,
            otp,
            purpose=OTPChallenge.Purpose.ACCOUNT_ACTION,
            requested_by_id=user.pk,
            action=action,
        )[1]

    @staticmethod
    def deactivate(user, challenge_id, otp):
        error = None
        with transaction.atomic():
            error = AccountService._confirm_lifecycle_otp(
                user, challenge_id, otp, "deactivate"
            )
            if not error:
                locked = User.objects.select_for_update().get(pk=user.pk)
                locked.is_active = False
                locked.deactivated_at = timezone.now()
                locked.save(update_fields=["is_active", "deactivated_at", "updated_at"])
                AccountService.revoke(locked, rotate_credentials=True)
        if error:
            raise error
        logger.info("account_deactivated user_id=%s", user.pk)

    @staticmethod
    def change_phone(user, phone_number, challenge_id, otp):
        error = None
        with transaction.atomic():
            _challenge, error = MobileOTPService._consume_locked(
                challenge_id,
                phone_number,
                otp,
                purpose=OTPChallenge.Purpose.CHANGE_PHONE,
                requested_by_id=user.pk,
                action="change_phone",
            )
            if not error:
                locked = User.objects.select_for_update().get(pk=user.pk)
                if User.objects.exclude(pk=locked.pk).filter(
                    phone_number=phone_number
                ).exists():
                    error = OTPFlowError(
                        "phone_in_use",
                        "This phone number cannot be used.",
                        409,
                    )
                else:
                    locked.phone_number = phone_number
                    locked.is_phone_verified = True
                    locked.phone_verified_at = timezone.now()
                    locked.save(
                        update_fields=[
                            "phone_number",
                            "is_phone_verified",
                            "phone_verified_at",
                            "updated_at",
                        ]
                    )
                    OTPChallenge.objects.filter(
                        requested_by=locked,
                        consumed_at__isnull=True,
                        invalidated_at__isnull=True,
                    ).update(invalidated_at=timezone.now())
                    AccountService.revoke(locked, rotate_credentials=True)
        if error:
            raise error
        logger.info(
            "account_phone_changed user_id=%s phone=%s",
            user.pk,
            mask_phone(phone_number),
        )

    @staticmethod
    def delete_permanently(user, challenge_id, otp):
        """Delete account data and remove owned media after DB commit."""
        error = None
        files = []
        user_id = user.pk
        with transaction.atomic():
            error = AccountService._confirm_lifecycle_otp(
                user, challenge_id, otp, "delete"
            )
            if not error:
                locked = User.objects.select_for_update().get(pk=user.pk)
                from resume.models import Resume, ResumeVersion

                for resume in Resume.objects.filter(user=locked).only(
                    "thumbnail", "pdf_file"
                ):
                    for field in (resume.thumbnail, resume.pdf_file):
                        if field and field.name:
                            files.append((field.storage, field.name))
                for version in ResumeVersion.objects.filter(user=locked).only("pdf_file"):
                    if version.pdf_file and version.pdf_file.name:
                        files.append((version.pdf_file.storage, version.pdf_file.name))
                profile = getattr(locked, "profile", None)
                if profile and profile.profile_image and profile.profile_image.name:
                    files.append((profile.profile_image.storage, profile.profile_image.name))

                # ResumeVersion protects its optimization session, so delete
                # versions first; all remaining owned rows cascade from User.
                ResumeVersion.objects.filter(user=locked).delete()
                locked.delete()

                def delete_files():
                    for storage, name in files:
                        try:
                            storage.delete(name)
                        except Exception:
                            # Database deletion must not be rolled back because
                            # a storage provider is temporarily unavailable.
                            logger.exception(
                                "account_media_delete_failed name=%s", name
                            )

                transaction.on_commit(delete_files)
        if error:
            raise error
        logger.info("account_deleted user_id=%s", user_id)

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
