import uuid
from django.db import models
from django.conf import settings

class CourseRecommendation(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    title = models.CharField(max_length=255)
    channel = models.CharField(max_length=255)
    video_id = models.CharField(max_length=100, unique=True)
    thumbnail = models.URLField()
    duration = models.CharField(max_length=50, blank=True, null=True)
    video_count = models.IntegerField(default=1)
    match_score = models.IntegerField(default=0)
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return self.title

class CourseProgress(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='course_progress')
    video_id = models.CharField(max_length=100)
    watched_seconds = models.IntegerField(default=0)
    total_seconds = models.IntegerField(default=0)
    last_updated = models.DateTimeField(auto_now=True)

    class Meta:
        unique_together = ('user', 'video_id')

    def __str__(self):
        return f"{self.user.email} - {self.video_id} - {self.watched_seconds}/{self.total_seconds}"
