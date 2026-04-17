from rest_framework import serializers


class ResumeValidationService:
    REQUIRED_LIST_FIELDS = ["education", "experience", "skills", "projects"]

    @staticmethod
    def validate_resume_data(data):
        if not isinstance(data, dict):
            raise serializers.ValidationError("Resume data must be a JSON object.")

        personal_info = data.get("personal_info")
        if not isinstance(personal_info, dict):
            raise serializers.ValidationError(
                {"personal_info": "personal_info is required and must be an object."}
            )

        for field_name in ["name", "email", "phone"]:
            if field_name not in personal_info:
                raise serializers.ValidationError(
                    {"personal_info": f"Missing required field: {field_name}."}
                )

        for list_field in ResumeValidationService.REQUIRED_LIST_FIELDS:
            field_value = data.get(list_field)
            if field_value is None:
                raise serializers.ValidationError(
                    {list_field: f"{list_field} is required and must be an array."}
                )
            if not isinstance(field_value, list):
                raise serializers.ValidationError(
                    {list_field: f"{list_field} must be an array."}
                )