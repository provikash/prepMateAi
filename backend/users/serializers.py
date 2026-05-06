from django.contrib.auth import get_user_model
from django.contrib.auth.password_validation import validate_password
from rest_framework import serializers

from .models import UserProfile


User = get_user_model()


class RegisterSerializer(serializers.ModelSerializer):
    password = serializers.CharField(write_only=True, trim_whitespace=False)
    password_confirm = serializers.CharField(write_only=True, trim_whitespace=False)

    class Meta:
        model = User
        fields = ("email", "name", "password", "password_confirm")

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
        if attrs["password"] != attrs["password_confirm"]:
            raise serializers.ValidationError({"password_confirm": "Passwords do not match."})

        validate_password(attrs["password"])
        return attrs

    def create(self, validated_data):
        validated_data.pop("password_confirm", None)
        password = validated_data.pop("password")
        return User.objects.create_user(password=password, **validated_data)


class LoginSerializer(serializers.Serializer):
    email = serializers.EmailField()
    password = serializers.CharField(write_only=True, trim_whitespace=False)

    def validate_email(self, value):
        return value.strip().lower()


class GoogleAuthSerializer(serializers.Serializer):
    id_token = serializers.CharField(write_only=True, trim_whitespace=True)

    def validate_id_token(self, value):
        token = value.strip()
        if not token:
            raise serializers.ValidationError("id_token is required.")
        return token


class UserSummarySerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = ("id", "email", "name", "avatar_url", "is_verified")
        read_only_fields = ("id", "email", "is_verified")


class UserProfileSerializer(serializers.ModelSerializer):
    profile_image_url = serializers.SerializerMethodField(read_only=True)

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
        )
        read_only_fields = ("updated_at", "profile_image_url")

    def get_profile_image_url(self, obj):
        if not obj.profile_image:
            return None
        request = self.context.get("request")
        return request.build_absolute_uri(obj.profile_image.url) if request else obj.profile_image.url


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
