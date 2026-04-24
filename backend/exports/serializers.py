from rest_framework import serializers


class ExportRequestSerializer(serializers.Serializer):
    resume_id = serializers.UUIDField()