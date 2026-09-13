from django.contrib import admin
from .models import CourseRecommendation, CourseProgress


@admin.register(CourseRecommendation)
class CourseRecommendationAdmin(admin.ModelAdmin):
    list_display = ("title", "channel", "match_score", "created_at")
    search_fields = ("title", "channel", "video_id")
    list_filter = ("match_score", "created_at")
    readonly_fields = ("id", "created_at")


@admin.register(CourseProgress)
class CourseProgressAdmin(admin.ModelAdmin):
    list_display = ("user", "video_id", "watch_percentage", "last_updated")
    search_fields = ("user__email", "video_id")
    list_filter = ("last_updated", "created_at")
    readonly_fields = ("id", "created_at", "last_updated")
