from rest_framework import serializers

from .models import ResumeTemplate


class TemplateListSerializer(serializers.ModelSerializer):
    title = serializers.CharField(source="name", read_only=True)
    thumbnail_url = serializers.SerializerMethodField()

    class Meta:
        model = ResumeTemplate
        fields = ["id", "title", "category", "thumbnail_url"]
        read_only_fields = fields

    def get_thumbnail_url(self, obj):
        if not obj.preview_image:
            return None
        request = self.context.get("request")
        return request.build_absolute_uri(obj.preview_image.url) if request else obj.preview_image.url


class TemplateDetailSerializer(serializers.ModelSerializer):
    title = serializers.CharField(source="name", read_only=True)
    thumbnail_url = serializers.SerializerMethodField()

    class Meta:
        model = ResumeTemplate
        fields = [
            "id",
            "title",
            "category",
            "thumbnail_url",
            "preview_image",
            "html_structure",
            "css",
            "metadata",
            "created_at",
            "updated_at",
        ]
        read_only_fields = fields

    def get_thumbnail_url(self, obj):
        if not obj.preview_image:
            return None
        request = self.context.get("request")
        return request.build_absolute_uri(obj.preview_image.url) if request else obj.preview_image.url