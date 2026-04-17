import re

from rest_framework import serializers


class ResumeValidationService:
    REQUIRED_LIST_FIELDS = ["education", "experience", "skills", "projects"]
    TEMPLATE_DATA_PATH_PATTERN = re.compile(r"{{\s*resume\.([a-zA-Z0-9_\.]+)")

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

    @staticmethod
    def _extract_required_paths_from_template(html_structure):
        if not html_structure:
            return set()
        return {match.group(1) for match in ResumeValidationService.TEMPLATE_DATA_PATH_PATTERN.finditer(html_structure)}

    @staticmethod
    def _path_exists_in_data(data, path):
        current = data
        for segment in path.split("."):
            if not isinstance(current, dict) or segment not in current:
                return False
            current = current[segment]
        return True

    @staticmethod
    def validate_data_against_template(data, template):
        required_paths = ResumeValidationService._extract_required_paths_from_template(
            template.html_structure
        )
        missing_paths = sorted(
            path for path in required_paths if not ResumeValidationService._path_exists_in_data(data, path)
        )

        if missing_paths:
            raise serializers.ValidationError(
                {
                    "data": (
                        "Resume data does not match the selected template structure. "
                        f"Missing required fields: {', '.join(missing_paths)}."
                    )
                }
            )