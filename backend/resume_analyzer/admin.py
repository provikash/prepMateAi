from django.contrib import admin

from .models import ResumeAnalysis


@admin.register(ResumeAnalysis)
class ResumeAnalysisAdmin(admin.ModelAdmin):
    list_display = ("id", "user", "job_role", "ats_score", "skill_score", "created_at")
    list_filter = ("job_role", "created_at")
    search_fields = ("user__email", "job_role")
