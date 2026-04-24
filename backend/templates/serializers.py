from rest_framework import serializers

from .models import ResumeTemplate


class TemplateSerializer(serializers.ModelSerializer):
    class Meta:
        model = ResumeTemplate
        fields = ["id", "name", "preview_image", "html_structure", "created_at", "updated_at"]
        read_only_fields = fields