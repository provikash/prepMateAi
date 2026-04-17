from django.conf import settings
from django.db import models

from core.models import BaseModel



class ResumeTemplate(BaseModel):
    name = models.CharField(max_length=100)
    preview_image = models.ImageField(upload_to="templates/previews/", blank=True, null=True)
    html_structure = models.TextField()
    is_active = models.BooleanField(default=True)

    def __str__(self):
        return self.name


class Resume(BaseModel):
    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="resumes",
    )
    title = models.CharField(max_length=255)
    template = models.ForeignKey(
        ResumeTemplate,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name="resumes",
    )
    data = models.JSONField()

    class Meta:
        ordering = ["-updated_at"]

    def __str__(self):
        return f"{self.title} ({self.user.email})"