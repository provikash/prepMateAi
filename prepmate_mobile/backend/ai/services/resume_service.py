import logging

from .gemini_service import GeminiService
from .prompt_builder import (
    build_bullet_prompt,
    build_improve_prompt,
    build_skills_prompt,
    build_summary_prompt,
)

logger = logging.getLogger(__name__)


class ResumeAIService:
    """
    Service for AI-powered resume operations.
    Orchestrates Gemini API calls for resume generation tasks.
    """

    def __init__(self):
        self.gemini_service = GeminiService()

    def generate_summary(self, data: dict) -> dict:
        """Generate a professional summary from resume data."""
        try:
            prompt = build_summary_prompt(data)
            result = self.gemini_service.generate_json_response(prompt, expected_key="summary")
            return {"summary": result["summary"]}
        except Exception as exc:
            logger.exception("Failed to generate summary")
            raise

    def improve_section(self, text: str, section_name: str) -> dict:
        """Improve a resume section with AI suggestions."""
        try:
            prompt = build_improve_prompt(text=text, section_name=section_name)
            result = self.gemini_service.generate_json_response(prompt, expected_key="improved_text")
            return {"improved_text": result["improved_text"]}
        except Exception as exc:
            logger.exception("Failed to improve section: %s", section_name)
            raise

    def suggest_skills(self, role: str, existing_skills: list[str] | None = None) -> dict:
        """Suggest relevant skills for a job role."""
        try:
            prompt = build_skills_prompt(role=role, existing_skills=existing_skills)
            result = self.gemini_service.generate_json_response(prompt, expected_key="skills")

            skills = result["skills"]
            if not isinstance(skills, list):
                raise ValueError("AI response field 'skills' must be a list.")

            cleaned_skills = [item.strip() for item in skills if isinstance(item, str) and item.strip()]
            return {"skills": cleaned_skills}
        except Exception as exc:
            logger.exception("Failed to suggest skills for role: %s", role)
            raise

    def generate_bullets(self, experience: list[dict]) -> dict:
        """Generate achievement bullets from work experience."""
        try:
            prompt = build_bullet_prompt(experience=experience)
            result = self.gemini_service.generate_json_response(prompt, expected_key="bullets")

            bullets = result["bullets"]
            if not isinstance(bullets, list):
                raise ValueError("AI response field 'bullets' must be a list.")

            cleaned_bullets = [item.strip() for item in bullets if isinstance(item, str) and item.strip()]
            return {"bullets": cleaned_bullets}
        except Exception as exc:
            logger.exception("Failed to generate bullets")
            raise