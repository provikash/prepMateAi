from rest_framework import serializers

from .models import ResumeAnalysis


class AnalyzeResumeRequestSerializer(serializers.Serializer):
    resume_id = serializers.UUIDField(required=False, allow_null=True)
    uploaded_file = serializers.FileField(required=False, allow_null=True)
    job_role = serializers.CharField(max_length=120)

    def validate_uploaded_file(self, value):
        if value is None:
            return value

        filename = (value.name or "").lower()
        if not filename.endswith(".pdf"):
            raise serializers.ValidationError("Only PDF files are supported.")

        if value.size <= 0:
            raise serializers.ValidationError("Uploaded file is empty.")

        max_size_bytes = 10 * 1024 * 1024
        if value.size > max_size_bytes:
            raise serializers.ValidationError("PDF size must be <= 10MB.")

        return value

    def validate_job_role(self, value):
        cleaned = value.strip()
        if not cleaned:
            raise serializers.ValidationError("job_role is required.")
        return cleaned

    def validate(self, attrs):
        resume_id = attrs.get("resume_id")
        uploaded_file = attrs.get("uploaded_file")

        if not resume_id and not uploaded_file:
            raise serializers.ValidationError("Provide either resume_id or uploaded_file.")

        if resume_id and uploaded_file:
            raise serializers.ValidationError("Provide only one source: either resume_id or uploaded_file.")

        return attrs


class ReanalyzeRequestSerializer(serializers.Serializer):
    job_role = serializers.CharField(max_length=120, required=False, allow_blank=True)


class ResumeAnalysisHistorySerializer(serializers.ModelSerializer):
    analysis_id = serializers.UUIDField(source="id", read_only=True)

    class Meta:
        model = ResumeAnalysis
        fields = [
            "analysis_id",
            "job_role",
            "ats_score",
            "skill_score",
            "created_at",
            "resume",
            "uploaded_file",
        ]


class ResumeSerializer(serializers.Serializer):
    id = serializers.UUIDField()
    title = serializers.CharField()
    pdf_url = serializers.CharField(allow_null=True)


class ResumeAnalysisResponseSerializer(serializers.Serializer):
    analysis_id = serializers.UUIDField()
    ats_score = serializers.IntegerField()
    skill_score = serializers.IntegerField()
    missing_sections = serializers.ListField(child=serializers.CharField())
    missing_skills = serializers.DictField()
    matched_skills = serializers.DictField()
    keyword_analysis = serializers.DictField()
    format_issues = serializers.ListField(child=serializers.CharField())
    contact_issues = serializers.ListField(child=serializers.CharField())
    suggestions = serializers.ListField(child=serializers.CharField())
    ats_breakdown = serializers.DictField()
    job_role = serializers.CharField()
    resume_id = serializers.UUIDField(allow_null=True)
    resume_title = serializers.CharField(allow_blank=True, required=False)
    created_at = serializers.DateTimeField()
