import logging

from .services.resume_service import ResumeAIService


logger = logging.getLogger(__name__)


def _is_rate_limit_error(error_message: str) -> bool:
    message = (error_message or "").lower()
    return "429" in message or "quota" in message


def _handle_retry(exc: Exception, task_name: str):
    error_message = str(exc)

    if _is_rate_limit_error(error_message):
        logger.warning("%s hit rate limit/quota: %s", task_name, error_message)
        return {
            "status": "error",
            "message": "AI is currently busy. Please try again in a minute.",
        }

    logger.exception("%s failed.", task_name)
    return {
        "status": "error",
        "message": "AI generation failed after multiple attempts.",
    }


def generate_summary(data: dict) -> dict:
    service = ResumeAIService()
    try:
        return service.generate_summary(data=data)
    except Exception as exc:
        return _handle_retry(exc, "generate_summary")


def improve_section(text: str, section_name: str) -> dict:
    service = ResumeAIService()
    try:
        return service.improve_section(text=text, section_name=section_name)
    except Exception as exc:
        return _handle_retry(exc, "improve_section")


def suggest_skills(role: str, existing_skills: list[str] | None = None) -> dict:
    service = ResumeAIService()
    try:
        return service.suggest_skills(role=role, existing_skills=existing_skills)
    except Exception as exc:
        return _handle_retry(exc, "suggest_skills")


def generate_bullets(experience: list[dict]) -> dict:
    service = ResumeAIService()
    try:
        return service.generate_bullets(experience=experience)
    except Exception as exc:
        return _handle_retry(exc, "generate_bullets")
