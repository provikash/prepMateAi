import copy
import re

from rest_framework import serializers


class ResumeValidationService:
    REQUIRED_LIST_FIELDS = ["education", "experience", "skills", "projects"]
    TEMPLATE_DATA_PATH_PATTERN = re.compile(r"{{\s*resume\.([a-zA-Z0-9_\.]+)")

    @staticmethod
    def normalize_resume_data(data):
        if not isinstance(data, dict):
            raise serializers.ValidationError("Resume data must be a JSON object.")

        normalized = copy.deepcopy(data)

        personal_info = normalized.get("personal_info")
        if not isinstance(personal_info, dict):
            personal_info = {}

        top_level_personal_fields = {
            "name": normalized.get("name", personal_info.get("name", "")),
            "role": normalized.get("role", personal_info.get("role", "")),
            "phone": normalized.get("phone", personal_info.get("phone", "")),
            "email": normalized.get("email", personal_info.get("email", "")),
            "linkedin": normalized.get("linkedin", personal_info.get("linkedin", "")),
            "linkedin_url": normalized.get("linkedin_url", personal_info.get("linkedin_url", "")),
            "github": normalized.get("github", personal_info.get("github", "")),
            "github_url": normalized.get("github_url", personal_info.get("github_url", "")),
            "summary": normalized.get("summary", personal_info.get("summary", "")),
        }

        linkedin_value = str(top_level_personal_fields.get("linkedin", "")).strip()
        linkedin_url_value = str(top_level_personal_fields.get("linkedin_url", "")).strip()
        if not linkedin_url_value and linkedin_value.startswith(("http://", "https://")):
            top_level_personal_fields["linkedin_url"] = linkedin_value

        github_value = str(top_level_personal_fields.get("github", "")).strip()
        github_url_value = str(top_level_personal_fields.get("github_url", "")).strip()
        if not github_url_value and github_value.startswith(("http://", "https://")):
            top_level_personal_fields["github_url"] = github_value

        normalized["personal_info"] = top_level_personal_fields

        skills = normalized.get("skills")
        skill_groups = normalized.get("skill_groups")

        if not isinstance(skill_groups, dict):
            skill_groups = {}

        if isinstance(skills, list) and skills:
            cleaned_skills = [item.strip() for item in skills if isinstance(item, str) and item.strip()]
        else:
            cleaned_skills = []
            for group_value in skill_groups.values():
                if isinstance(group_value, list):
                    cleaned_skills.extend(
                        item.strip() for item in group_value if isinstance(item, str) and item.strip()
                    )
                elif isinstance(group_value, str) and group_value.strip():
                    cleaned_skills.extend(
                        item.strip() for item in group_value.split(",") if item.strip()
                    )

        skill_group_defaults = {
            "programming_languages": "",
            "mobile_framework": "",
            "architecture": "",
            "ui_ux": "",
            "tools": "",
        }

        canonical_skill_groups = {}
        for key, default_value in skill_group_defaults.items():
            raw_value = skill_groups.get(key, default_value)
            canonical_skill_groups[key] = ResumeValidationService._stringify_skill_group_value(raw_value)

        if not any(canonical_skill_groups.values()) and cleaned_skills:
            canonical_skill_groups["programming_languages"] = ", ".join(cleaned_skills)

        normalized["skills"] = cleaned_skills or cleaned_skills_from_skill_groups(canonical_skill_groups)
        normalized["skill_groups"] = canonical_skill_groups

        normalized["certifications"] = ResumeValidationService._normalize_certifications(
            normalized.get("certifications")
        )
        normalized["projects"] = ResumeValidationService._normalize_projects(normalized.get("projects"))
        normalized["education"] = ResumeValidationService._normalize_education(normalized.get("education"))
        normalized["experience"] = ResumeValidationService._normalize_experience(normalized.get("experience"))

        return normalized

    @staticmethod
    def _normalize_certifications(value):
        if not isinstance(value, list):
            return []

        normalized = []
        for item in value:
            if isinstance(item, str) and item.strip():
                normalized.append({"title": item.strip(), "description": ""})
            elif isinstance(item, dict):
                title = str(item.get("title", "")).strip()
                description = str(item.get("description", "")).strip()
                if title or description:
                    normalized.append({"title": title, "description": description})
        return normalized

    @staticmethod
    def _normalize_projects(value):
        if not isinstance(value, list):
            return []

        normalized = []
        for item in value:
            if not isinstance(item, dict):
                continue

            bullets = item.get("bullets") or item.get("responsibilities") or []
            if isinstance(bullets, str):
                bullets = [bullets]
            if not isinstance(bullets, list):
                bullets = []

            cleaned_bullets = [
                bullet.strip() for bullet in bullets if isinstance(bullet, str) and bullet.strip()
            ]

            description = str(item.get("description", "")).strip()
            if not cleaned_bullets and description:
                cleaned_bullets = [description]

            normalized.append(
                {
                    "title": str(item.get("title", "")).strip(),
                    "stack": str(item.get("stack", "")).strip(),
                    "date_range": str(item.get("date_range", item.get("duration", ""))).strip(),
                    "bullets": cleaned_bullets,
                    "source_code": str(item.get("source_code", item.get("link", ""))).strip(),
                    "description": description,
                }
            )

        return normalized

    @staticmethod
    def _normalize_education(value):
        if not isinstance(value, list):
            return []

        normalized = []
        for item in value:
            if not isinstance(item, dict):
                continue

            normalized.append(
                {
                    "degree": str(item.get("degree", "")).strip(),
                    "institution": str(item.get("institution", item.get("school", ""))).strip(),
                    "year": str(item.get("year", item.get("graduation_year", ""))).strip(),
                    "location": str(item.get("location", "")).strip(),
                }
            )

        return normalized

    @staticmethod
    def _normalize_experience(value):
        if not isinstance(value, list):
            return []

        normalized = []
        for item in value:
            if not isinstance(item, dict):
                continue

            responsibilities = item.get("responsibilities") or item.get("bullets") or []
            if isinstance(responsibilities, str):
                responsibilities = [responsibilities]
            if not isinstance(responsibilities, list):
                responsibilities = []

            normalized.append(
                {
                    "job_title": str(item.get("job_title", item.get("title", ""))).strip(),
                    "company": str(item.get("company", "")).strip(),
                    "duration": str(item.get("duration", "")).strip(),
                    "responsibilities": [
                        responsibility.strip()
                        for responsibility in responsibilities
                        if isinstance(responsibility, str) and responsibility.strip()
                    ],
                    "technologies": [
                        technology.strip()
                        for technology in (item.get("technologies") or [])
                        if isinstance(technology, str) and technology.strip()
                    ],
                }
            )

        return normalized

    @staticmethod
    def _stringify_skill_group_value(value):
        if isinstance(value, list):
            items = [item.strip() for item in value if isinstance(item, str) and item.strip()]
            return ", ".join(items)

        if isinstance(value, str):
            parts = [item.strip() for item in value.split(",") if item.strip()]
            return ", ".join(parts)

        return ""

    @staticmethod
    def validate_resume_data(data):
        data = ResumeValidationService.normalize_resume_data(data)

        personal_info = data.get("personal_info")
        if not isinstance(personal_info, dict):
            raise serializers.ValidationError({"personal_info": "personal_info is required and must be an object."})

        for field_name in ["name", "email", "phone"]:
            if not str(personal_info.get(field_name, "")).strip():
                raise serializers.ValidationError(
                    {"personal_info": f"Missing required field: {field_name}."}
                )

        for list_field in ["education", "experience", "skills", "projects"]:
            field_value = data.get(list_field)
            if field_value is None:
                raise serializers.ValidationError({list_field: f"{list_field} is required and must be an array."})
            if not isinstance(field_value, list):
                raise serializers.ValidationError({list_field: f"{list_field} must be an array."})

        if "skill_groups" in data and not isinstance(data["skill_groups"], dict):
            raise serializers.ValidationError({"skill_groups": "skill_groups must be an object if provided."})

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


def cleaned_skills_from_skill_groups(skill_groups):
    skills = []
    for value in skill_groups.values():
        if isinstance(value, str) and value.strip():
            skills.extend(item.strip() for item in value.split(",") if item.strip())
        elif isinstance(value, list):
            skills.extend(item.strip() for item in value if isinstance(item, str) and item.strip())
    return skills