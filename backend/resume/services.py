import copy
import re

from rest_framework import serializers


class ResumeValidationService:
    TEMPLATE_DATA_PATH_PATTERN = re.compile(r"{{\s*resume\.([a-zA-Z0-9_\.]+)")
    TEMPLATE_IF_BLOCK_PATTERN = re.compile(r"{%\s*if\b.*?%}(.*?){%\s*endif\s*%}", re.DOTALL)
    TEMPLATE_ANY_PATH_PATTERN = re.compile(r"(?:resume\.)?([a-zA-Z0-9_]+(?:\.[a-zA-Z0-9_]+)+)")

    @staticmethod
    def normalize_resume_data(data):
        if not isinstance(data, dict):
            raise serializers.ValidationError("Resume data must be a JSON object.")

        normalized = copy.deepcopy(data)

        # ── Bridge JSON Resume `basics` object (sent by Flutter) into our internal
        # `personal_info` key so all downstream code can rely on personal_info.
        basics = normalized.get("basics")
        if isinstance(basics, dict):
            # Merge basics into personal_info, not overwriting existing personal_info keys.
            existing_pi = normalized.get("personal_info")
            if not isinstance(existing_pi, dict):
                existing_pi = {}
            location_raw = basics.get("location", {})
            location_city = (
                location_raw.get("city", "") if isinstance(location_raw, dict)
                else str(location_raw)
            )
            profiles = ResumeValidationService._normalize_profiles(basics.get("profiles", []))
            merged = {
                "name": basics.get("name", ""),
                "label": basics.get("label", ""),
                "email": basics.get("email", ""),
                "phone": basics.get("phone", ""),
                "summary": basics.get("summary", ""),
                "url": basics.get("url", ""),
                "location": location_city,
                "profiles": profiles,
            }
            merged.update({k: v for k, v in existing_pi.items() if v})
            normalized["personal_info"] = merged
            # Also keep basics intact so templates using resume.basics.* work directly.

        personal_info = normalized.get("personal_info")
        if not isinstance(personal_info, dict):
            personal_info = {}

        top_level_personal_fields = {
            "name": normalized.get("name", personal_info.get("name", "")),
            "label": normalized.get("label", personal_info.get("label", "")),
            "role": normalized.get("role", personal_info.get("role", personal_info.get("label", ""))),
            "phone": normalized.get("phone", personal_info.get("phone", "")),
            "email": normalized.get("email", personal_info.get("email", "")),
            "website": normalized.get("website", personal_info.get("website", "")),
            "url": normalized.get("url", personal_info.get("url", "")),
            "location": normalized.get("location", personal_info.get("location", "")),
            "image": normalized.get("image", personal_info.get("image", "")),
            "profiles": ResumeValidationService._normalize_profiles(
                normalized.get("profiles", personal_info.get("profiles", []))
            ),
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

        # Bridge JSON Resume `work` → internal `experience` list.
        if isinstance(normalized.get("work"), list) and not normalized.get("experience"):
            normalized["experience"] = normalized["work"]

        if isinstance(normalized.get("references"), list) and not normalized.get("volunteer"):
            normalized["volunteer"] = normalized["references"]

        skills = normalized.get("skills")
        skill_groups = normalized.get("skill_groups")

        if not isinstance(skill_groups, dict):
            skill_groups = {}

        if isinstance(skills, list) and skills:
            skill_items = ResumeValidationService._normalize_skill_entries(skills)
            cleaned_skills = [item["name"] for item in skill_items if item.get("name")]
            normalized["skills"] = skill_items
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

        # Preserve JSON Resume skills list format (list of {name, keywords}) if already set.
        existing_skills = normalized.get("skills")
        if not isinstance(existing_skills, list) or not existing_skills:
            normalized["skills"] = ResumeValidationService._skill_entries_from_skill_groups(
                canonical_skill_groups,
                cleaned_skills,
            )
        normalized["skill_groups"] = canonical_skill_groups

        normalized["certifications"] = ResumeValidationService._normalize_certifications(
            normalized.get("certifications")
        )
        normalized["projects"] = ResumeValidationService._normalize_projects(normalized.get("projects"))
        normalized["education"] = ResumeValidationService._normalize_education(normalized.get("education"))
        normalized["experience"] = ResumeValidationService._normalize_experience(normalized.get("experience"))
        normalized["awards"] = ResumeValidationService._normalize_awards(normalized.get("awards"))
        normalized["languages"] = ResumeValidationService._normalize_languages(normalized.get("languages"))

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
            if isinstance(item, str):
                title = item.strip()
                if title:
                    normalized.append(
                        {
                            "name": title,
                            "title": title,
                            "stack": "",
                            "date_range": "",
                            "bullets": [],
                            "source_code": "",
                            "description": "",
                        }
                    )
                continue

            if not isinstance(item, dict):
                continue

            bullets = item.get("bullets") or item.get("highlights") or item.get("responsibilities") or []
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
                    "name": str(item.get("name", item.get("title", ""))).strip(),
                    "title": str(item.get("title", item.get("name", ""))).strip(),
                    "stack": str(item.get("stack", "")).strip(),
                    "date_range": str(
                        item.get(
                            "date_range",
                            item.get("duration", f'{item.get("startDate", "")} — {item.get("endDate", "")}').strip(),
                        )
                    ).strip(),
                    "bullets": cleaned_bullets,
                    "source_code": str(item.get("source_code", item.get("website", item.get("link", "")))).strip(),
                    "url": str(item.get("url", item.get("source_code", item.get("website", item.get("link", ""))))).strip(),
                    "description": description or str(item.get("summary", "")).strip(),
                    "highlights": cleaned_bullets,
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

            details = item.get("details") or []
            if isinstance(details, str):
                details = [part.strip() for part in details.splitlines() if part.strip()]
            if not isinstance(details, list):
                details = []
            cleaned_details = [detail.strip() for detail in details if isinstance(detail, str) and detail.strip()]

            normalized.append(
                {
                    "degree": str(item.get("degree", item.get("studyType", ""))).strip(),
                    "institution": str(item.get("institution", item.get("school", ""))).strip(),
                    "duration": str(
                        item.get(
                            "duration",
                            item.get("year", item.get("graduation_year", f'{item.get("startDate", "")} — {item.get("endDate", "")}')),
                        )
                    ).strip(),
                    "year": str(item.get("year", item.get("duration", item.get("graduation_year", item.get("endDate", ""))))).strip(),
                    "location": str(item.get("location", item.get("area", ""))).strip(),
                    "details": cleaned_details,
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

            details = (
                item.get("details")
                or item.get("highlights")
                or item.get("responsibilities")
                or item.get("bullets")
                or []
            )
            if isinstance(details, str):
                details = [details]
            if not isinstance(details, list):
                details = []
            cleaned_details = [
                detail.strip()
                for detail in details
                if isinstance(detail, str) and detail.strip()
            ]

            normalized.append(
                {
                    "role": str(item.get("role", item.get("position", item.get("job_title", item.get("title", ""))))).strip(),
                    "job_title": str(item.get("job_title", item.get("position", item.get("role", item.get("title", ""))))).strip(),
                    "company": str(item.get("company", item.get("name", ""))).strip(),
                    "duration": str(
                        item.get(
                            "duration",
                            f'{item.get("startDate", "")} — {item.get("endDate", "")}'.strip(" —"),
                        )
                    ).strip(),
                    "location": str(item.get("location", "")).strip(),
                    "summary": str(item.get("summary", item.get("description", ""))).strip(),
                    "details": cleaned_details,
                    "responsibilities": cleaned_details,
                    "highlights": cleaned_details,
                    "technologies": [
                        technology.strip()
                        for technology in (item.get("technologies") or [])
                        if isinstance(technology, str) and technology.strip()
                    ],
                }
            )

        return normalized

    @staticmethod
    def _normalize_awards(value):
        if not isinstance(value, list):
            return []

        normalized = []
        for item in value:
            if isinstance(item, str) and item.strip():
                normalized.append({"title": item.strip(), "awarder": "", "date": "", "summary": ""})
                continue
            if isinstance(item, dict):
                title = str(item.get("title", "")).strip()
                if title:
                    normalized.append(
                        {
                            "title": title,
                            "awarder": str(item.get("awarder", "")).strip(),
                            "date": str(item.get("date", "")).strip(),
                            "summary": str(item.get("summary", "")).strip(),
                        }
                    )
        return normalized

    @staticmethod
    def _normalize_languages(value):
        if not isinstance(value, list):
            return []

        normalized = []
        for item in value:
            if isinstance(item, dict):
                name = str(item.get("name", item.get("language", ""))).strip()
                level = str(item.get("level", item.get("fluency", ""))).strip()
                if name or level:
                    normalized.append({"name": name, "level": level})
                continue

            if isinstance(item, str) and item.strip():
                normalized.append({"name": item.strip(), "level": ""})

        return normalized

    @staticmethod
    def _normalize_profiles(value):
        if not isinstance(value, list):
            if isinstance(value, str) and value.strip():
                return [{"network": "", "username": value.strip(), "url": ""}]
            return []

        normalized = []
        for item in value:
            if isinstance(item, dict):
                network = str(item.get("network", "")).strip()
                username = str(item.get("username", "")).strip()
                url = str(item.get("url", "")).strip()
                if network or username or url:
                    normalized.append({"network": network, "username": username, "url": url})
            elif isinstance(item, str) and item.strip():
                normalized.append({"network": "", "username": item.strip(), "url": ""})

        return normalized

    @staticmethod
    def _normalize_skill_entries(value):
        if not isinstance(value, list):
            return []

        normalized = []
        for item in value:
            if isinstance(item, str):
                name = item.strip()
                if name:
                    normalized.append({"name": name, "level": "", "keywords": []})
                continue

            if not isinstance(item, dict):
                continue

            name = str(item.get("name", "")).strip()
            level = str(item.get("level", "")).strip()
            keywords = ResumeValidationService._normalize_keywords(item.get("keywords"))
            if name or level or keywords:
                normalized.append(
                    {
                        "name": name,
                        "level": level,
                        "keywords": keywords,
                    }
                )

        return normalized

    @staticmethod
    def _skill_entries_from_skill_groups(skill_groups, fallback_names=None):
        fallback_names = fallback_names or []
        entries = []

        for value in skill_groups.values():
            if isinstance(value, list):
                entries.extend(
                    {"name": item.strip(), "level": "", "keywords": []}
                    for item in value
                    if isinstance(item, str) and item.strip()
                )
            elif isinstance(value, str) and value.strip():
                entries.extend(
                    {"name": item.strip(), "level": "", "keywords": []}
                    for item in value.split(",")
                    if item.strip()
                )

        if not entries:
            entries.extend({"name": name, "level": "", "keywords": []} for name in fallback_names if name)

        return entries

    @staticmethod
    def _normalize_keywords(value):
        if isinstance(value, str):
            return [part.strip() for part in re.split(r"[\n,]", value) if part.strip()]

        if isinstance(value, list):
            return [item.strip() for item in value if isinstance(item, str) and item.strip()]

        return []

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

        if personal_info and not isinstance(personal_info, dict):
            raise serializers.ValidationError({"personal_info": "personal_info must be an object."})

        if "skill_groups" in data and not isinstance(data["skill_groups"], dict):
            raise serializers.ValidationError({"skill_groups": "skill_groups must be an object if provided."})

    @staticmethod
    def _extract_required_paths_from_template(html_structure):
        if not html_structure:
            return set()

        output_paths = set()
        for match in ResumeValidationService.TEMPLATE_DATA_PATH_PATTERN.finditer(html_structure):
            output_paths.add(match.group(1))

        conditional_paths = set()
        for block_match in ResumeValidationService.TEMPLATE_IF_BLOCK_PATTERN.finditer(html_structure):
            conditional_block = block_match.group(1)
            for path_match in ResumeValidationService.TEMPLATE_ANY_PATH_PATTERN.finditer(conditional_block):
                conditional_paths.add(path_match.group(1))

        return {path for path in output_paths if path not in conditional_paths}

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