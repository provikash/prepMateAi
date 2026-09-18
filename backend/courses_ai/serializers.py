from rest_framework import serializers
from .models import CourseRecommendation, CourseProgress

class CourseRecommendationSerializer(serializers.ModelSerializer):
    class Meta:
        model = CourseRecommendation
        fields = ['id', 'title', 'channel', 'video_id', 'thumbnail', 'duration', 'video_count', 'match_score']

class CourseProgressSerializer(serializers.ModelSerializer):
    watch_percentage = serializers.SerializerMethodField()

    def get_watch_percentage(self, obj):
        return round(min(100, obj.watched_seconds / obj.total_seconds * 100), 2) if obj.total_seconds > 0 else 0

    class Meta:
        model = CourseProgress
        fields = ['video_id', 'watched_seconds', 'total_seconds', 'last_updated', 'watch_percentage']
        read_only_fields = ['last_updated']


class RecommendationRequestSerializer(serializers.Serializer):
    skills = serializers.ListField(child=serializers.CharField(max_length=80, trim_whitespace=True), min_length=1, max_length=15)

    def validate_skills(self, skills):
        return list(dict.fromkeys(skill.lower() for skill in skills))


class ProgressRequestSerializer(serializers.Serializer):
    video_id = serializers.RegexField(r'^[A-Za-z0-9_-]{11}$')
    watched_seconds = serializers.IntegerField(min_value=0, max_value=604800)
    total_seconds = serializers.IntegerField(min_value=1, max_value=604800)

    def validate(self, attrs):
        if attrs['watched_seconds'] > attrs['total_seconds']:
            raise serializers.ValidationError('Watched time cannot exceed video duration.')
        return attrs
