from rest_framework import serializers
from .models import CourseRecommendation, CourseProgress


class CourseRecommendationSerializer(serializers.ModelSerializer):
    class Meta:
        model = CourseRecommendation
        fields = [
            "id",
            "title",
            "channel",
            "video_id",
            "thumbnail",
            "duration",
            "video_count",
            "match_score",
            "created_at",
        ]
        read_only_fields = ["id", "created_at"]


class CourseProgressSerializer(serializers.ModelSerializer):
    watch_percentage = serializers.SerializerMethodField()

    class Meta:
        model = CourseProgress
        fields = [
            "id",
            "video_id",
            "watched_seconds",
            "total_seconds",
            "watch_percentage",
            "last_updated",
        ]
        read_only_fields = ["id", "last_updated"]

    def get_watch_percentage(self, obj):
        return obj.watch_percentage


class CourseProgressUpdateSerializer(serializers.Serializer):
    """Serializer for creating/updating course progress."""
    video_id = serializers.CharField(max_length=255)
    watched_seconds = serializers.IntegerField(min_value=0)
    total_seconds = serializers.IntegerField(min_value=0)


class CourseRecommendationRequestSerializer(serializers.Serializer):
    """Serializer for course recommendation request."""
    skills = serializers.ListField(
        child=serializers.CharField(max_length=100),
        min_length=1,
    )
