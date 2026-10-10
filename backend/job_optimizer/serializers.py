from copy import deepcopy

from rest_framework import serializers

from resume.models import Resume, ResumeVersion
from .models import JobDescription, OptimizationSession, OptimizationSuggestion


class JobDescriptionSerializer(serializers.ModelSerializer):
    description = serializers.CharField(trim_whitespace=False)

    class Meta:
        model = JobDescription
        fields = [
            "id",
            "title",
            "company",
            "description",
            "source_url",
            "created_at",
            "updated_at",
        ]
        read_only_fields = ["id", "created_at", "updated_at"]

    def validate_description(self, value):
        cleaned = (value or "").strip()
        if len(cleaned) < 10:
            raise serializers.ValidationError("Job description must be at least 10 characters long.")
        if len(cleaned) > 100000:
            raise serializers.ValidationError("Job description exceeds maximum allowed length.")
        return value


class OptimizationSuggestionSerializer(serializers.ModelSerializer):
    class Meta:
        model = OptimizationSuggestion
        fields = [
            "id",
            "optimization_session",
            "suggestion_type",
            "resume_path",
            "target_section",
            "target_item_id",
            "target_field",
            "target_child_id",
            "original_value",
            "ai_suggestion",
            "user_edited_value",
            "final_value",
            "status",
            "reason",
            "keywords",
            "evidence_reference",
            "confidence",
            "severity",
            "requires_confirmation",
            "decision_version",
            "applied_at",
            "prompt_version",
            "revision_history",
            "created_at",
            "updated_at",
        ]
        read_only_fields = fields


class OptimizationSessionCreateSerializer(serializers.Serializer):
    resume_id = serializers.UUIDField(required=True)
    job_description_id = serializers.UUIDField(required=False, allow_null=True)
    job_description = JobDescriptionSerializer(required=False, allow_null=True)

    def validate(self, attrs):
        user = self.context["request"].user
        resume_id = attrs.get("resume_id")
        jd_id = attrs.get("job_description_id")
        jd_data = attrs.get("job_description")

        try:
            resume = Resume.objects.get(id=resume_id, user=user)
        except Resume.DoesNotExist:
            raise serializers.ValidationError({"resume_id": "Resume not found or does not belong to you."})
        attrs["resume"] = resume

        if jd_id:
            try:
                jd = JobDescription.objects.get(id=jd_id, user=user)
            except JobDescription.DoesNotExist:
                raise serializers.ValidationError({"job_description_id": "Job description not found or does not belong to you."})
            attrs["jd"] = jd
        elif jd_data:
            # We will create it in create()
            pass
        else:
            raise serializers.ValidationError("Either job_description_id or job_description object must be provided.")

        return attrs

    def create(self, validated_data):
        user = self.context["request"].user
        resume = validated_data["resume"]
        jd = validated_data.get("jd")

        if not jd:
            jd_serializer = JobDescriptionSerializer(
                data=validated_data["job_description"],
                context=self.context,
            )
            jd_serializer.is_valid(raise_exception=True)
            jd = jd_serializer.save(user=user)

        session = OptimizationSession.objects.create(
            user=user,
            source_resume=resume,
            source_resume_version=resume.revision,
            source_resume_updated_at=resume.updated_at,
            source_data_snapshot=deepcopy(resume.data or {}),
            job_description=jd,
            status=OptimizationSession.Status.DRAFT,
        )
        return session


class OptimizationSessionSerializer(serializers.ModelSerializer):
    job_description = JobDescriptionSerializer(read_only=True)
    source_resume_id = serializers.UUIDField(source="source_resume.id", read_only=True)
    source_resume_title = serializers.CharField(source="source_resume.title", read_only=True)
    suggestions = OptimizationSuggestionSerializer(many=True, read_only=True)
    decision_counts = serializers.SerializerMethodField()
    optimized_version = serializers.SerializerMethodField()
    pdf = serializers.SerializerMethodField()
    credit = serializers.SerializerMethodField()

    class Meta:
        model = OptimizationSession
        fields = [
            "id",
            "source_resume_id",
            "source_resume_title",
            "source_resume_version",
            "source_resume_updated_at",
            "job_description",
            "status",
            "analysis_json",
            "match_results_json",
            "final_analysis_json",
            "suggestions",
            "decision_counts",
            "optimized_version",
            "pdf",
            "credit",
            "completed_at",
            "failed_at",
            "failure_code",
            "failure_message",
            "request_id",
            "created_at",
            "updated_at",
        ]
        read_only_fields = fields

    def get_decision_counts(self, obj):
        counts = {key.lower(): 0 for key, _ in OptimizationSuggestion.Status.choices}
        for value in obj.suggestions.values_list("status", flat=True):
            counts[value.lower()] = counts.get(value.lower(), 0) + 1
        return counts

    def _version(self, obj):
        try:
            return obj.optimized_version
        except ResumeVersion.DoesNotExist:
            return None

    def get_optimized_version(self, obj):
        version = self._version(obj)
        if version is None:
            return None
        return {"id": str(version.pk), "title": version.title, "created_at": version.created_at}

    def get_pdf(self, obj):
        version = self._version(obj)
        if version is None:
            return {"status": "not_requested", "url": None, "error_code": None}
        return {
            "status": version.pdf_status.lower(),
            "url": f"/api/v1/job-optimizer/versions/{version.pk}/pdf/" if version.pdf_file else None,
            "error_code": version.pdf_error_code or None,
        }

    def get_credit(self, obj):
        from ai.services.entitlements import EntitlementService

        entitlements = EntitlementService.get_user_entitlements(obj.user)["ai_credits"]
        return {"reserved": entitlements["reserved"], "available": entitlements["available"]}
