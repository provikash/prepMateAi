from rest_framework import serializers

from .models import Resume, ResumeTemplate
from .services import ResumeValidationService
from .json_resume import deep_merge, empty_resume, validate_and_normalize


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
            "template_version",
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
    template_id = serializers.PrimaryKeyRelatedField(
        queryset=ResumeTemplate.objects.filter(is_active=True),
        source="template",
        required=False,
        allow_null=False,
        write_only=True,
    )
    template = serializers.PrimaryKeyRelatedField(
        queryset=ResumeTemplate.objects.filter(is_active=True),
        required=False,
        allow_null=False,
    )
    thumbnail_url = serializers.SerializerMethodField(read_only=True)
    pdf_url = serializers.SerializerMethodField(read_only=True)

    class Meta:
        model = Resume
        fields = [
            "id",
            "user",
            "title",
            "template",
            "template_id",
            "template_version",
            "data",
            "metadata",
            "thumbnail",
            "pdf_file",
            "thumbnail_url",
            "pdf_url",
            "created_at",
            "updated_at",
        ]
        read_only_fields = ["id", "user", "template_version", "created_at", "updated_at", "thumbnail_url", "pdf_url"]

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

    def validate_title(self, value):
        cleaned_title = value.strip()
        if not cleaned_title:
            raise serializers.ValidationError("Title is required.")
        return cleaned_title

    def validate_data(self, value):
        if self.instance is not None and self.partial:
            value = deep_merge(self.instance.data or empty_resume(), value)
        metadata = self.initial_data.get("metadata", {})
        is_draft = isinstance(metadata, dict) and metadata.get("status") == "draft"
        return validate_and_normalize(value, strict=not is_draft)

    def validate(self, attrs):
        initial = self.initial_data
        if "template" in initial and "template_id" in initial and str(initial["template"]) != str(initial["template_id"]):
            raise serializers.ValidationError({"template_id": "Conflicts with template."})
        template = attrs.get("template", getattr(self.instance, "template", None))
        data = attrs.get("data", getattr(self.instance, "data", None))

        if self.instance is None and template is None:
            raise serializers.ValidationError(
                {"template": "Selecting a template is required when creating a resume."}
            )

        if self.instance is None and data is None:
            attrs["data"] = empty_resume()
            data = attrs["data"]
        source_data = self.initial_data.get("data", data)
        if template is not None and data is not None and template.html_structure and isinstance(source_data, dict) and any(key in source_data for key in ("personal_info", "experience", "skill_groups")):
            ResumeValidationService.validate_data_against_template(source_data, template)
        return attrs

    def create(self, validated_data):
        template = validated_data["template"]
        validated_data["template_version"] = template.version
        return super().create(validated_data)

    def update(self, instance, validated_data):
        template = validated_data.get("template")
        if template is not None and template.pk != instance.template_id:
            validated_data["template_version"] = template.version
        return super().update(instance, validated_data)
