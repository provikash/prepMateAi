from django.db import models
from django.conf import settings



class Resume(models.Model):
    TEMPLATE_CHOICES = [
        ('modern','The Professional'),
        ('classic','Tech Savvy'),
        ('minimal','Pure Minimal'),
    ]

    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name="resumes")
    title = models.CharField(max_length=100)
    template = models.CharField(max_length=20, choices=TEMPLATE_CHOICES)

    content = models.JSONField()

    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    def __str__(self):
        return self.title

# Create your models here.
