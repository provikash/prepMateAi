from urllib.parse import urlparse

from .services import ResumeValidationService


class ResumeRenderService:
    @staticmethod
    def prepare_resume_context(data):
        normalized = ResumeValidationService.normalize_resume_data(data)

        personal_info = normalized.get("personal_info", {})
        personal_info["linkedin_url"] = ResumeRenderService._normalize_profile_url(
            personal_info.get("linkedin_url") or personal_info.get("linkedin")
        )
        personal_info["github_url"] = ResumeRenderService._normalize_profile_url(
            personal_info.get("github_url") or personal_info.get("github")
        )
        normalized["personal_info"] = personal_info

        projects = ResumeRenderService._prepare_projects(normalized.get("projects", []))
        certifications = ResumeRenderService._prepare_certifications(
            normalized.get("certifications", [])
        )
        education = ResumeRenderService._prepare_education(normalized.get("education", []))

        normalized["projects"] = projects
        normalized["certifications"] = certifications
        normalized["education"] = education

        skill_groups = normalized.get("skill_groups", {})
        has_grouped_skills = any(str(value).strip() for value in skill_groups.values())

        normalized["has_summary"] = bool(str(personal_info.get("summary", "")).strip())
        normalized["has_skills"] = bool(normalized.get("skills") or has_grouped_skills)
        normalized["has_projects"] = bool(projects)
        normalized["has_certifications"] = bool(certifications)
        normalized["has_education"] = bool(education)

        return normalized

    @staticmethod
    def _prepare_projects(projects):
        prepared_projects = []
        for project in projects:
            if not isinstance(project, dict):
                continue

            title = str(project.get("title", "")).strip()
            stack = str(project.get("stack", "")).strip()
            date_range = str(project.get("date_range", "")).strip()
            description = str(project.get("description", "")).strip()
            source_code = ResumeRenderService._normalize_profile_url(project.get("source_code", ""))

            bullets = project.get("bullets") or []
            if isinstance(bullets, str):
                bullets = [bullets]
            cleaned_bullets = [
                bullet.strip() for bullet in bullets if isinstance(bullet, str) and bullet.strip()
            ]

            has_content = bool(title or stack or date_range or cleaned_bullets or description)
            if not has_content:
                continue

            prepared_projects.append(
                {
                    "title": title,
                    "stack": stack,
                    "date_range": date_range,
                    "description": description,
                    "source_code": source_code,
                    "bullets": cleaned_bullets,
                }
            )

        return prepared_projects

    @staticmethod
    def _prepare_certifications(certifications):
        prepared = []
        for certification in certifications:
            if isinstance(certification, str):
                title = certification.strip()
                description = ""
            elif isinstance(certification, dict):
                title = str(certification.get("title", "")).strip()
                description = str(certification.get("description", "")).strip()
            else:
                continue

            if not (title or description):
                continue

            prepared.append({"title": title, "description": description})

        return prepared

    @staticmethod
    def _prepare_education(education):
        prepared = []
        for entry in education:
            if not isinstance(entry, dict):
                continue

            degree = str(entry.get("degree", "")).strip()
            institution = str(entry.get("institution", "")).strip()
            year = str(entry.get("year", "")).strip()
            location = str(entry.get("location", "")).strip()

            if not (degree or institution or year or location):
                continue

            prepared.append(
                {
                    "degree": degree,
                    "institution": institution,
                    "year": year,
                    "location": location,
                }
            )

        return prepared

    @staticmethod
    def _normalize_profile_url(value):
        if not value:
            return ""

        url = str(value).strip()
        if not url:
            return ""

        if not url.startswith(("http://", "https://")):
            url = f"https://{url}"

        parsed = urlparse(url)
        if not parsed.scheme or not parsed.netloc:
            return ""

        return url
