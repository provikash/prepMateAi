from core.media import media_url
from rest_framework import serializers

from .models import ResumeTemplate
from resume.json_resume import canonical_form_schema


class TemplateListSerializer(serializers.ModelSerializer):
    title = serializers.CharField(source="name", read_only=True)
    thumbnail = serializers.ImageField(source="preview_image", read_only=True)
    thumbnail_url = serializers.SerializerMethodField()

    class Meta:
        model = ResumeTemplate
        fields = ["id", "title", "slug", "description", "category", "version", "thumbnail", "thumbnail_url", "is_active"]
        read_only_fields = fields

    def get_thumbnail_url(self, obj):
        if not obj.preview_image:
            return None
        request = self.context.get("request")
        return media_url(request, obj.preview_image)


class TemplateDetailSerializer(serializers.ModelSerializer):
    title = serializers.CharField(source="name", read_only=True)
    thumbnail = serializers.ImageField(source="preview_image", read_only=True)
    thumbnail_url = serializers.SerializerMethodField()
    form_schema = serializers.SerializerMethodField()

    class Meta:
        model = ResumeTemplate
        fields = [
            "id",
            "title",
            "slug",
            "description",
            "category",
            "version",
            "thumbnail",
            "thumbnail_url",
            "form_schema",
            "preview_image",
            "metadata",
            "is_active",
            "created_at",
            "updated_at",
        ]
        read_only_fields = fields

    def get_thumbnail_url(self, obj):
        if not obj.preview_image:
            return None
        request = self.context.get("request")
        return media_url(request, obj.preview_image)

    def get_form_schema(self, obj):
        metadata = obj.metadata or {}
        if not isinstance(metadata, dict):
            return {}
        form_schema = metadata.get("form_schema")
        canonical = canonical_form_schema()
        if not isinstance(form_schema, dict) or not form_schema.get("sections"):
            return canonical
        presentation_keys = {
            "group", "default_visible", "order", "can_skip", "recommended_for"
        }
        defaults = {section["key"]: section for section in canonical["sections"]}
        sections = []
        for position, raw_section in enumerate(form_schema["sections"]):
            if not isinstance(raw_section, dict):
                continue
            section = dict(raw_section)
            canonical_section = defaults.get(section.get("key"), {})
            for key in presentation_keys:
                section.setdefault(key, canonical_section.get(key))
            if section.get("order") is None:
                section["order"] = (position + 1) * 10
            sections.append(section)
        return {
            **form_schema,
            "schema": form_schema.get("schema", canonical["schema"]),
            "version": max(form_schema.get("version", 1), canonical["version"]),
            "sections": sections,
        }
