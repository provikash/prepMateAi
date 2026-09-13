from django.conf import settings
from django.db import models

from core.models import BaseModel
from resume.thumbnail_utils import (
    build_resume_thumbnail_name,
    build_template_thumbnail_name,
    generate_default_template_thumbnail,
    generate_thumbnail_from_html,
    generate_thumbnail_from_pdf,
)



class ResumeTemplate(BaseModel):
    name = models.CharField(max_length=100)
    category = models.CharField(max_length=60, default="general")
    preview_image = models.ImageField(upload_to="templates/previews/", blank=True, null=True)
    html_structure = models.TextField()
    css = models.TextField(blank=True, default="")
    metadata = models.JSONField(default=dict, blank=True)
    is_active = models.BooleanField(default=True)

    def save(self, *args, **kwargs):
        super().save(*args, **kwargs)

        if self.preview_image:
            return

        content_file = None

        if self.html_structure:
            content_file, _ = generate_thumbnail_from_html(self.html_structure, self.css)

        if not content_file:
            content_file, _ = generate_default_template_thumbnail(self.name)

        if not content_file:
            return

        self.preview_image.save(
            build_template_thumbnail_name(self.pk if self.pk else "default"),
            content_file,
            save=False,
        )
        super().save(update_fields=["preview_image", "updated_at"])

    def __str__(self):
        return self.name


class Resume(BaseModel):
    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="resumes",
    )
    title = models.CharField(max_length=255)
    thumbnail = models.ImageField(upload_to="resumes/thumbnails/", blank=True, null=True)
    pdf_file = models.FileField(upload_to="resumes/pdfs/", blank=True, null=True)
    template = models.ForeignKey(
        ResumeTemplate,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name="resumes",
    )
    data = models.JSONField()
    metadata = models.JSONField(default=dict, blank=True)

    def save(self, *args, **kwargs):
        super().save(*args, **kwargs)

        if self.thumbnail or not self.pdf_file:
            return

        try:
            pdf_path = self.pdf_file.path
        except Exception:
            pdf_path = ""

        content_file, _ = generate_thumbnail_from_pdf(pdf_path)
        if not content_file:
            return

        self.thumbnail.save(
            build_resume_thumbnail_name(self.pk),
            content_file,
            save=False,
        )
        super().save(update_fields=["thumbnail", "updated_at"])

    class Meta:
        ordering = ["-updated_at"]

    def __str__(self):
        return f"{self.title} ({self.user.email})"