from rest_framework import serializers


MAX_ROLE_LENGTH = 120
MAX_SECTION_LENGTH = 4000
MAX_TEXT_ITEMS = 25
MAX_TEXT_ITEM_LENGTH = 300
MAX_EXPERIENCE_ITEMS = 10
MAX_EXPERIENCE_FIELD_LENGTH = 500


class GenerateSummaryRequestSerializer(serializers.Serializer):
    role = serializers.CharField(max_length=MAX_ROLE_LENGTH, trim_whitespace=True)
    skills = serializers.ListField(
        child=serializers.CharField(max_length=MAX_TEXT_ITEM_LENGTH, trim_whitespace=True),
        allow_empty=False,
        max_length=MAX_TEXT_ITEMS,
    )
    experience = serializers.ListField(
        child=serializers.CharField(max_length=MAX_TEXT_ITEM_LENGTH, trim_whitespace=True),
        required=False,
        allow_empty=True,
        max_length=MAX_TEXT_ITEMS,
    )
    target_job_description = serializers.CharField(
        required=False,
        allow_blank=True,
        max_length=MAX_SECTION_LENGTH,
        trim_whitespace=True,
    )

    def validate_role(self, value):
        cleaned = value.strip()
        if not cleaned:
            raise serializers.ValidationError("role is required.")
        return cleaned


class ImproveSectionRequestSerializer(serializers.Serializer):
    section_name = serializers.CharField(max_length=80, trim_whitespace=True)
    text = serializers.CharField(max_length=MAX_SECTION_LENGTH, trim_whitespace=True)

    def validate_section_name(self, value):
        cleaned = value.strip()
        if not cleaned:
            raise serializers.ValidationError("section_name is required.")
        return cleaned

    def validate_text(self, value):
        cleaned = value.strip()
        if not cleaned:
            raise serializers.ValidationError("text is required.")
        return cleaned


class SuggestSkillsRequestSerializer(serializers.Serializer):
    role = serializers.CharField(max_length=MAX_ROLE_LENGTH, trim_whitespace=True)
    existing_skills = serializers.ListField(
        child=serializers.CharField(max_length=MAX_TEXT_ITEM_LENGTH, trim_whitespace=True),
        required=False,
        allow_empty=True,
        max_length=MAX_TEXT_ITEMS,
    )

    def validate_role(self, value):
        cleaned = value.strip()
        if not cleaned:
            raise serializers.ValidationError("role is required.")
        return cleaned


class ExperienceItemSerializer(serializers.Serializer):
    job_title = serializers.CharField(max_length=150, trim_whitespace=True)
    company = serializers.CharField(max_length=150, trim_whitespace=True)
    duration = serializers.CharField(max_length=80, required=False, allow_blank=True, trim_whitespace=True)
    responsibilities = serializers.ListField(
        child=serializers.CharField(max_length=MAX_EXPERIENCE_FIELD_LENGTH, trim_whitespace=True),
        required=False,
        allow_empty=True,
        max_length=MAX_TEXT_ITEMS,
    )
    technologies = serializers.ListField(
        child=serializers.CharField(max_length=MAX_TEXT_ITEM_LENGTH, trim_whitespace=True),
        required=False,
        allow_empty=True,
        max_length=MAX_TEXT_ITEMS,
    )

    def validate_job_title(self, value):
        cleaned = value.strip()
        if not cleaned:
            raise serializers.ValidationError("job_title is required.")
        return cleaned

    def validate_company(self, value):
        cleaned = value.strip()
        if not cleaned:
            raise serializers.ValidationError("company is required.")
        return cleaned


class GenerateBulletsRequestSerializer(serializers.Serializer):
    experience = serializers.ListField(
        child=ExperienceItemSerializer(),
        allow_empty=False,
        max_length=MAX_EXPERIENCE_ITEMS,
    )


class SummaryResponseSerializer(serializers.Serializer):
    summary = serializers.CharField()


class ImproveSectionResponseSerializer(serializers.Serializer):
    improved_text = serializers.CharField()


class SuggestSkillsResponseSerializer(serializers.Serializer):
    skills = serializers.ListField(child=serializers.CharField())


class GenerateBulletsResponseSerializer(serializers.Serializer):
    bullets = serializers.ListField(child=serializers.CharField())
