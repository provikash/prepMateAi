from rest_framework import serializers

from .models import Resume, ResumeTemplate
from .services import ResumeValidationService


class ResumeListSerializer(serializers.ModelSerializer):
    thumbnail_url = serializers.SerializerMethodField()
    pdf_url = serializers.SerializerMethodField()

    class Meta:
        model = Resume
        fields = ["id", "title", "thumbnail_url", "pdf_url", "created_at"]
        read_only_fields = fields

    def _build_absolute_file_url(self, file_field):
        if not file_field:
            return None
        url = file_field.url
        request = self.context.get("request")
        return request.build_absolute_uri(url) if request else url

    def get_thumbnail_url(self, obj):
        if obj.thumbnail:
            return self._build_absolute_file_url(obj.thumbnail)
        if obj.template and obj.template.preview_image:
            return self._build_absolute_file_url(obj.template.preview_image)
        return None

    def get_pdf_url(self, obj):
        return self._build_absolute_file_url(obj.pdf_file)


class ResumeDetailSerializer(serializers.ModelSerializer):
    thumbnail_url = serializers.SerializerMethodField()
    pdf_url = serializers.SerializerMethodField()

    class Meta:
        model = Resume
        fields = [
            "id",
            "user",
            "title",
            "template",
            "data",
            "metadata",
            "thumbnail",
            "pdf_file",
            "thumbnail_url",
            "pdf_url",
            "created_at",
            "updated_at",
        ]
        read_only_fields = ["id", "user", "created_at", "updated_at", "thumbnail_url", "pdf_url"]

    def _build_absolute_file_url(self, file_field):
        if not file_field:
            return None
        url = file_field.url
        request = self.context.get("request")
        return request.build_absolute_uri(url) if request else url

    def get_thumbnail_url(self, obj):
        if obj.thumbnail:
            return self._build_absolute_file_url(obj.thumbnail)
        if obj.template and obj.template.preview_image:
            return self._build_absolute_file_url(obj.template.preview_image)
        return None

    def get_pdf_url(self, obj):
        return self._build_absolute_file_url(obj.pdf_file)

class ResumeSerializer(serializers.ModelSerializer):
    template = serializers.PrimaryKeyRelatedField(
        queryset=ResumeTemplate.objects.filter(is_active=True),
        required=False,
        allow_null=True,
    )

    class Meta:
        model = Resume
        fields = [
            "id",
            "user",
            "title",
            "template",
            "data",
            "metadata",
            "thumbnail",
            "pdf_file",
            "created_at",
            "updated_at",
        ]
        read_only_fields = ["id", "user", "created_at", "updated_at"]

    def validate_title(self, value):
        cleaned_title = value.strip()
        if not cleaned_title:
            raise serializers.ValidationError("Title is required.")
        return cleaned_title

    def validate_data(self, value):
        normalized_value = ResumeValidationService.normalize_resume_data(value)
        ResumeValidationService.validate_resume_data(normalized_value)
        return normalized_value

    def validate(self, attrs):
        template = attrs.get("template", getattr(self.instance, "template", None))
        data = attrs.get("data", getattr(self.instance, "data", None))

        if self.instance is None and template is None:
            raise serializers.ValidationError(
                {"template": "Selecting a template is required when creating a resume."}
            )

        if template is not None and data is not None:
            ResumeValidationService.validate_data_against_template(data, template)

        return attrs