from .constants import DEFAULT_ROLE_SKILLS, ROLE_SKILLS


class SkillGapEngine:
    @staticmethod
    def _normalize_skill(value: str) -> str:
        return " ".join(value.lower().strip().split())

    @staticmethod
    def _get_role_skills(job_role: str) -> dict:
        role_key = SkillGapEngine._normalize_skill(job_role)
        return ROLE_SKILLS.get(role_key, DEFAULT_ROLE_SKILLS)

    @staticmethod
    def _extract_candidate_skills(structured_data: dict) -> set[str]:
        skills = structured_data.get("skills") or []
        skill_groups = structured_data.get("skill_groups") or {}

        normalized = set()
        for skill in skills:
            if isinstance(skill, str) and skill.strip():
                normalized.add(SkillGapEngine._normalize_skill(skill))

        for group_value in skill_groups.values():
            if isinstance(group_value, str):
                for item in group_value.split(","):
                    if item.strip():
                        normalized.add(SkillGapEngine._normalize_skill(item))
            elif isinstance(group_value, list):
                for item in group_value:
                    if isinstance(item, str) and item.strip():
                        normalized.add(SkillGapEngine._normalize_skill(item))

        return normalized

    @staticmethod
    def evaluate(structured_data: dict, job_role: str) -> dict:
        role_skills = SkillGapEngine._get_role_skills(job_role)
        candidate_skills = SkillGapEngine._extract_candidate_skills(structured_data)

        matched = {}
        missing = {}
        total_required = 0
        total_matched = 0

        for category, required_list in role_skills.items():
            required_norm = [SkillGapEngine._normalize_skill(item) for item in required_list]
            matched_list = [item for item in required_norm if item in candidate_skills]
            missing_list = [item for item in required_norm if item not in candidate_skills]

            matched[category] = matched_list
            missing[category] = missing_list

            total_required += len(required_norm)
            total_matched += len(matched_list)

        skill_score = int((total_matched / total_required) * 100) if total_required else 0

        return {
            "matched_skills": matched,
            "missing_skills": missing,
            "skill_score": max(0, min(100, skill_score)),
            "role_skills": role_skills,
        }
