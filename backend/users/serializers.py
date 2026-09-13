from django.contrib.auth import get_user_model
from django.contrib.auth.password_validation import validate_password
from rest_framework import serializers

from .models import UserProfile
from django.conf import settings
from rest_framework_simplejwt.serializers import TokenRefreshSerializer
from rest_framework_simplejwt.exceptions import InvalidToken, TokenError
from rest_framework_simplejwt.utils import get_md5_hash_password


User = get_user_model()


class StrictInputMixin:
    def to_internal_value(self, data):
        from collections.abc import Mapping
        if not isinstance(data, Mapping):
            raise serializers.ValidationError({"non_field_errors": ["Expected an object."]})
        unknown = set(data) - set(self.fields)
        readonly = {name for name in data if name in self.fields and self.fields[name].read_only}
        if unknown or readonly:
            raise serializers.ValidationError({name: "Unexpected or read-only field." for name in unknown | readonly})
        return super().to_internal_value(data)


class RegisterSerializer(StrictInputMixin, serializers.ModelSerializer):
    password = serializers.CharField(write_only=True, trim_whitespace=False)
    password_confirm = serializers.CharField(write_only=True, trim_whitespace=False, required=False)

    class Meta:
        model = User
        fields = ("email", "name", "first_name", "last_name", "password", "password_confirm")
        extra_kwargs = {"name": {"required": False}}

    def validate_email(self, value):
        normalized_email = value.strip().lower()
        if User.objects.filter(email__iexact=normalized_email).exists():
            raise serializers.ValidationError("A user with this email already exists.")
        return normalized_email

    def validate_name(self, value):
        cleaned_name = value.strip()
        if not cleaned_name:
            raise serializers.ValidationError("Name is required.")
        return cleaned_name

    def validate(self, attrs):
        if "password_confirm" in attrs and attrs["password"] != attrs["password_confirm"]:
            raise serializers.ValidationError({"password_confirm": "Passwords do not match."})

        attrs.setdefault("name", " ".join(filter(None, [attrs.get("first_name"), attrs.get("last_name")])) or attrs["email"])
        if len(attrs["name"]) > 255:
            raise serializers.ValidationError({"name": "Combined name must contain at most 255 characters."})
        validate_password(attrs["password"], User(email=attrs["email"], first_name=attrs.get("first_name", ""), last_name=attrs.get("last_name", "")))
        return attrs

    def create(self, validated_data):
        validated_data.pop("password_confirm", None)
        password = validated_data.pop("password")
        return User.objects.create_user(password=password, **validated_data)


class LoginSerializer(StrictInputMixin, serializers.Serializer):
    email = serializers.EmailField()
    password = serializers.CharField(write_only=True, trim_whitespace=False)

    def validate_email(self, value):
        return value.strip().lower()


class GoogleAuthSerializer(StrictInputMixin, serializers.Serializer):
    id_token = serializers.CharField(write_only=True, trim_whitespace=True)

    def validate_id_token(self, value):
        token = value.strip()
        if not token:
            raise serializers.ValidationError("id_token is required.")
        return token


class UserSummarySerializer(StrictInputMixin, serializers.ModelSerializer):
    is_email_verified = serializers.BooleanField(source="is_verified", read_only=True)
    class Meta:
        model = User
        fields = ("id", "email", "name", "first_name", "last_name", "avatar_url", "is_verified", "is_email_verified")
        read_only_fields = ("id", "email", "is_verified")


class UserProfileSerializer(StrictInputMixin, serializers.ModelSerializer):
    profile_image_url = serializers.SerializerMethodField(read_only=True)
    headline = serializers.CharField(source="job_title", max_length=120, required=False, allow_blank=True)
    linkedin_url = serializers.URLField(source="linkedin", max_length=1024, required=False, allow_blank=True)
    github_url = serializers.URLField(source="github", max_length=1024, required=False, allow_blank=True)
    bio = serializers.CharField(max_length=5000, required=False, allow_blank=True)

    def to_internal_value(self, data):
        for alias, legacy in (("headline", "job_title"), ("linkedin_url", "linkedin"), ("github_url", "github")):
            if alias in data and legacy in data and data[alias] != data[legacy]:
                raise serializers.ValidationError({alias: "Conflicts with legacy field."})
        return super().to_internal_value(data)

    def validate_profile_image(self, value):
        if value and (value.size > 5 * 1024 * 1024 or value.image.format not in {"JPEG", "PNG", "WEBP"}):
            raise serializers.ValidationError("Use a JPEG, PNG or WebP image no larger than 5 MB.")
        return value

    class Meta:
        model = UserProfile
        fields = (
            "full_name",
            "phone",
            "location",
            "job_title",
            "bio",
            "linkedin",
            "github",
            "profile_image",
            "profile_image_url",
            "updated_at",
            "created_at", "headline", "linkedin_url", "github_url", "portfolio_url",
        )
        read_only_fields = ("updated_at", "created_at", "profile_image_url")

    def get_profile_image_url(self, obj):
        if not obj.profile_image:
            return None
        request = self.context.get("request")
        return request.build_absolute_uri(obj.profile_image.url) if request else obj.profile_image.url


class EmailSerializer(StrictInputMixin, serializers.Serializer):
    email = serializers.EmailField(max_length=255)

    def validate_email(self, value):
        return value.strip().lower()


class VerifyEmailSerializer(EmailSerializer):
    otp = serializers.CharField(trim_whitespace=False)

    def validate_otp(self, value):
        if len(value) != settings.OTP_LENGTH or not value.isascii() or not value.isdigit():
            raise serializers.ValidationError("Invalid code format.")
        return value


class PasswordResetConfirmSerializer(VerifyEmailSerializer):
    new_password = serializers.CharField(write_only=True, trim_whitespace=False, validators=[validate_password])


class PasswordConfirmationSerializer(StrictInputMixin, serializers.Serializer):
    current_password = serializers.CharField(write_only=True, trim_whitespace=False)


class ChangePasswordSerializer(PasswordConfirmationSerializer):
    new_password = serializers.CharField(write_only=True, trim_whitespace=False, validators=[validate_password])


class RefreshInputSerializer(StrictInputMixin, serializers.Serializer):
    refresh = serializers.CharField(trim_whitespace=False, write_only=True)


class GuardedTokenRefreshSerializer(TokenRefreshSerializer):
    def validate(self, attrs):
        from django.db import transaction
        try:
            token = self.token_class(attrs["refresh"])
            with transaction.atomic():
                user = User.objects.select_for_update().get(pk=token["user_id"], is_active=True, is_verified=True, deleted_at__isnull=True)
                if token.get("hash_password") != get_md5_hash_password(user.password):
                    raise InvalidToken("Credentials have changed. Please log in again.")
                return super().validate(attrs)
        except (TokenError, User.DoesNotExist, KeyError, ValueError, TypeError):
            raise InvalidToken("Invalid refresh token.") from None


class DashboardLatestResumeSerializer(serializers.Serializer):
    id = serializers.UUIDField()
    title = serializers.CharField()
    thumbnail_url = serializers.CharField(allow_null=True)
    pdf_url = serializers.CharField(allow_null=True)
    ats_score = serializers.IntegerField(required=False)
    skill_gap_percentage = serializers.IntegerField(required=False)
    improvement_impact = serializers.IntegerField(required=False)


class DashboardSerializer(serializers.Serializer):
    latest_resume = DashboardLatestResumeSerializer(allow_null=True)
    missing_skills = serializers.ListField(child=serializers.CharField(), required=False)
    suggested_skills = serializers.ListField(child=serializers.CharField(), required=False)
    analysis_available = serializers.BooleanField(required=False)
    message = serializers.CharField(required=False)
