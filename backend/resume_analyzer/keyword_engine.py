import re

from .constants import ROLE_KEYWORDS


class KeywordAnalysisEngine:
    TOKEN_PATTERN = re.compile(r"[a-zA-Z][a-zA-Z0-9+#\.\-]{1,}")

    @staticmethod
    def _normalize(value: str) -> str:
        return " ".join(value.lower().strip().split())

    @staticmethod
    def _role_keywords(job_role: str, role_skills: dict | None = None) -> list[str]:
        role_key = KeywordAnalysisEngine._normalize(job_role)
        keywords = list(ROLE_KEYWORDS.get(role_key, []))

        if role_skills:
            for values in role_skills.values():
                for item in values:
                    if item not in keywords:
                        keywords.append(item)

        normalized = []
        for item in keywords:
            cleaned = KeywordAnalysisEngine._normalize(item)
            if cleaned and cleaned not in normalized:
                normalized.append(cleaned)
        return normalized

    @staticmethod
    def _extract_resume_keywords(structured_data: dict, raw_text: str) -> set[str]:
        keywords = set()

        for token in KeywordAnalysisEngine.TOKEN_PATTERN.findall(raw_text.lower()):
            if len(token) >= 3:
                keywords.add(token)

        for skill in structured_data.get("skills") or []:
            if isinstance(skill, str):
                cleaned = KeywordAnalysisEngine._normalize(skill)
                if cleaned:
                    keywords.add(cleaned)

        for project in structured_data.get("projects") or []:
            if isinstance(project, dict):
                stack = project.get("stack", "")
                for part in str(stack).split(","):
                    cleaned = KeywordAnalysisEngine._normalize(part)
                    if cleaned:
                        keywords.add(cleaned)

        return keywords

    @staticmethod
    def analyze(structured_data: dict, raw_text: str, job_role: str, role_skills: dict | None = None) -> dict:
        role_keywords = KeywordAnalysisEngine._role_keywords(job_role, role_skills=role_skills)
        resume_keywords = KeywordAnalysisEngine._extract_resume_keywords(structured_data, raw_text)

        matched = []
        missing = []
        for keyword in role_keywords:
            if keyword in resume_keywords:
                matched.append(keyword)
            else:
                missing.append(keyword)

        percentage = int((len(matched) / len(role_keywords)) * 100) if role_keywords else 0
        return {
            "matched_keywords": matched,
            "missing_keywords": missing,
            "match_percentage": max(0, min(100, percentage)),
        }
