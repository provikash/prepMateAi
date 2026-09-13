from rest_framework import serializers
from .models import CourseRecommendation, CourseProgress

class CourseRecommendationSerializer(serializers.ModelSerializer):
    class Meta:
        model = CourseRecommendation
        fields = ['id', 'title', 'channel', 'video_id', 'thumbnail', 'duration', 'video_count', 'match_score']

class CourseProgressSerializer(serializers.ModelSerializer):
    class Meta:
        model = CourseProgress
        fields = ['video_id', 'watched_seconds', 'total_seconds', 'last_updated']
        read_only_fields = ['last_updated']
