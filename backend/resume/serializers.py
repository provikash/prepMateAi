from rest_framework import serializers

from .models import Resume, ResumeTemplate
from .services import ResumeValidationService

class ResumeSerializer(serializers.ModelSerializer):
    template = serializers.PrimaryKeyRelatedField(
        queryset=ResumeTemplate.objects.filter(is_active=True),
        required=False,
        allow_null=True,
    )

    class Meta:
        model = Resume
        fields = ["id", "user", "title", "template", "data", "created_at", "updated_at"]
        read_only_fields = ["id", "user", "created_at", "updated_at"]

    def validate_title(self, value):
        cleaned_title = value.strip()
        if not cleaned_title:
            raise serializers.ValidationError("Title is required.")
        return cleaned_title

    def validate_data(self, value):
        ResumeValidationService.validate_resume_data(value)
        return value