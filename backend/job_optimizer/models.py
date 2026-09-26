from django.conf import settings
from django.db import models

from core.models import BaseModel


class JobDescription(BaseModel):
    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="job_descriptions",
        db_index=True,
    )
    title = models.CharField(max_length=255, blank=True, default="")
    company = models.CharField(max_length=255, blank=True, default="")
    description = models.TextField()
    source_url = models.URLField(max_length=500, blank=True, default="")

    class Meta:
        ordering = ["-created_at"]

    def __str__(self):
        label = self.title or "Job Description"
        if self.company:
            label = f"{label} at {self.company}"
        return f"{label} ({self.user.email})"


class OptimizationSession(BaseModel):
    class Status(models.TextChoices):
        DRAFT = "DRAFT", "Draft"
        ANALYZING = "ANALYZING", "Analyzing"
        ANALYZED = "ANALYZED", "Analyzed"
        MATCHING = "MATCHING", "Matching"
        READY_FOR_REVIEW = "READY_FOR_REVIEW", "Ready for Review"
        APPLYING = "APPLYING", "Applying"
        GENERATING_PDF = "GENERATING_PDF", "Generating PDF"
        COMPLETED = "COMPLETED", "Completed"
        FAILED = "FAILED", "Failed"
        CANCELLED = "CANCELLED", "Cancelled"

    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="optimization_sessions",
        db_index=True,
    )
    source_resume = models.ForeignKey(
        "resume.Resume",
        on_delete=models.CASCADE,
        related_name="optimization_sessions",
    )
    source_resume_version = models.PositiveIntegerField(default=1)
    source_resume_updated_at = models.DateTimeField(null=True, blank=True)
    job_description = models.ForeignKey(
        JobDescription,
        on_delete=models.CASCADE,
        related_name="optimization_sessions",
    )
    status = models.CharField(
        max_length=30,
        choices=Status.choices,
        default=Status.DRAFT,
        db_index=True,
    )
    analysis_json = models.JSONField(default=dict, blank=True)
    match_results_json = models.JSONField(default=dict, blank=True)
    source_data_snapshot = models.JSONField(default=dict, blank=True)
    final_analysis_json = models.JSONField(default=dict, blank=True)
    completed_at = models.DateTimeField(null=True, blank=True)
    failed_at = models.DateTimeField(null=True, blank=True)
    failure_code = models.CharField(max_length=60, blank=True, default="")
    failure_message = models.CharField(max_length=255, blank=True, default="")
    request_id = models.CharField(max_length=100, blank=True, default="")
    apply_idempotency_key = models.CharField(max_length=100, blank=True, default="")

    class Meta:
        ordering = ["-created_at"]
        constraints = [
            models.UniqueConstraint(
                fields=["user", "request_id"],
                condition=~models.Q(request_id=""),
                name="unique_user_optimizer_request_id",
            )
        ]

    def __str__(self):
        return f"Session<{self.id}> - {self.status} ({self.user.email})"


class OptimizationSuggestion(BaseModel):
    class SuggestionType(models.TextChoices):
        SUMMARY_IMPROVEMENT = "SUMMARY_IMPROVEMENT", "Summary Improvement"
        EXPERIENCE_BULLET_IMPROVEMENT = "EXPERIENCE_BULLET_IMPROVEMENT", "Experience Bullet Improvement"
        PROJECT_BULLET_IMPROVEMENT = "PROJECT_BULLET_IMPROVEMENT", "Project Bullet Improvement"
        SUMMARY_REWRITE = "SUMMARY_REWRITE", "Summary Rewrite"
        EXPERIENCE_REWRITE = "EXPERIENCE_REWRITE", "Experience Rewrite"
        PROJECT_REWRITE = "PROJECT_REWRITE", "Project Rewrite"
        SKILL_EMPHASIS = "SKILL_EMPHASIS", "Skill Emphasis"
        SKILL_REORDER = "SKILL_REORDER", "Skill Reorder"
        KEYWORD_ALIGNMENT = "KEYWORD_ALIGNMENT", "Keyword Alignment"
        CLARITY = "CLARITY", "Clarity"
        CONCISENESS = "CONCISENESS", "Conciseness"
        ATS_FORMATTING = "ATS_FORMATTING", "ATS Formatting"
        MISSING_EVIDENCE = "MISSING_EVIDENCE", "Missing Evidence"

    class Status(models.TextChoices):
        PENDING = "PENDING", "Pending"
        ACCEPTED = "ACCEPTED", "Accepted"
        REJECTED = "REJECTED", "Rejected"
        EDITED = "EDITED", "Edited"
        APPLIED = "APPLIED", "Applied"
        STALE = "STALE", "Stale"

    optimization_session = models.ForeignKey(
        OptimizationSession,
        on_delete=models.CASCADE,
        related_name="suggestions",
    )
    suggestion_type = models.CharField(
        max_length=40,
        choices=SuggestionType.choices,
    )
    resume_path = models.CharField(max_length=255)
    target_section = models.CharField(max_length=40, blank=True, default="")
    target_item_id = models.UUIDField(null=True, blank=True)
    target_field = models.CharField(max_length=80, blank=True, default="")
    target_child_id = models.UUIDField(null=True, blank=True)
    original_value = models.TextField(blank=True, default="")
    ai_suggestion = models.TextField(blank=True, default="")
    user_edited_value = models.TextField(null=True, blank=True)
    final_value = models.TextField(null=True, blank=True)
    status = models.CharField(
        max_length=20,
        choices=Status.choices,
        default=Status.PENDING,
        db_index=True,
    )
    reason = models.TextField(blank=True, default="")
    keywords = models.JSONField(default=list, blank=True)
    evidence_reference = models.JSONField(default=list, blank=True)
    confidence = models.CharField(max_length=20, default="HIGH")
    severity = models.CharField(max_length=20, default="MEDIUM")
    requires_confirmation = models.BooleanField(default=False)
    decision_version = models.PositiveIntegerField(default=1)
    applied_at = models.DateTimeField(null=True, blank=True)
    prompt_version = models.CharField(max_length=40, default="resume_optimizer_v1")
    revision_history = models.JSONField(default=list, blank=True)

    class Meta:
        ordering = ["created_at"]

    def __str__(self):
        return f"Suggestion<{self.id}> - {self.suggestion_type} ({self.status})"
