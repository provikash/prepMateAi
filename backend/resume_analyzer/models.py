import uuid

from django.conf import settings
from django.db import models


class ResumeAnalysis(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="resume_analyses",
    )
    resume = models.ForeignKey(
        "resume.Resume",
        on_delete=models.SET_NULL,
        related_name="analyses",
        blank=True,
        null=True,
    )
    uploaded_file = models.FileField(
        upload_to="resume_analysis/uploads/",
        blank=True,
        null=True,
    )
    job_role = models.CharField(max_length=120)
    ats_score = models.PositiveSmallIntegerField(default=0)
    skill_score = models.PositiveSmallIntegerField(default=0)
    analysis_data = models.JSONField(default=dict)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["-created_at"]

    def __str__(self):
        return f"{self.user.email} - {self.job_role} ({self.ats_score})"
