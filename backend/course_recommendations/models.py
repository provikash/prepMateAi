import uuid
from django.conf import settings
from django.db import models


class CourseRecommendation(models.Model):
    """Cache for YouTube course recommendations with scoring."""
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    title = models.CharField(max_length=255)
    channel = models.CharField(max_length=255)
    video_id = models.CharField(max_length=255, unique=True)
    thumbnail = models.URLField()
    duration = models.CharField(max_length=50, blank=True, null=True)  # "1:30:45" format
    video_count = models.IntegerField(default=0)  # For playlists
    match_score = models.FloatField(default=0.0)  # 0-100
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["-match_score"]

    def __str__(self):
        return f"{self.title} - {self.match_score}%"


class CourseProgress(models.Model):
    """Track user's video watch progress."""
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="course_progress",
    )
    video_id = models.CharField(max_length=255)
    watched_seconds = models.IntegerField(default=0)
    total_seconds = models.IntegerField(default=0)
    last_updated = models.DateTimeField(auto_now=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        unique_together = ("user", "video_id")
        ordering = ["-last_updated"]

    def __str__(self):
        return f"{self.user.email} - {self.video_id}"

    @property
    def watch_percentage(self):
        """Calculate percentage watched."""
        if self.total_seconds > 0:
            return (self.watched_seconds / self.total_seconds) * 100
        return 0.0
