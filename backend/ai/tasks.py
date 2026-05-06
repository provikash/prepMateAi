import logging

try:
    from celery import shared_task
except Exception:
    # Fallback for environments without Celery installed (allows migrations to run).
    def shared_task(*a, **kw):
        def _decorator(fn):
            return fn
        return _decorator

from .services import AIService


logger = logging.getLogger(__name__)


def _is_rate_limit_error(error_message: str) -> bool:
    message = (error_message or "").lower()
    return "429" in message or "quota" in message


def _handle_retry(task, exc: Exception, task_name: str):
    error_message = str(exc)

    if _is_rate_limit_error(error_message):
        logger.warning("%s hit rate limit/quota: %s", task_name, error_message)
        return {
            "status": "error",
            "message": "AI is currently busy. Please try again in a minute.",
        }

    countdown = 5 * (task.request.retries + 1)
    try:
        raise task.retry(exc=exc, countdown=countdown, max_retries=2)
    except task.MaxRetriesExceededError:
        logger.exception("%s failed after max retries.", task_name)
        return {
            "status": "error",
            "message": "AI generation failed after multiple attempts.",
        }


@shared_task(
    bind=True,
    name="ai.generate_summary",
)
def generate_summary_task(self, data: dict) -> dict:
    service = AIService()
    try:
        return service.generate_summary(data=data)
    except Exception as exc:
        return _handle_retry(self, exc, "generate_summary")


@shared_task(
    bind=True,
    name="ai.improve_section",
)
def improve_section_task(self, text: str, section_name: str) -> dict:
    service = AIService()
    try:
        return service.improve_section(text=text, section_name=section_name)
    except Exception as exc:
        return _handle_retry(self, exc, "improve_section")


@shared_task(
    bind=True,
    name="ai.suggest_skills",
)
def suggest_skills_task(self, role: str, existing_skills: list[str] | None = None) -> dict:
    service = AIService()
    try:
        return service.suggest_skills(role=role, existing_skills=existing_skills)
    except Exception as exc:
        return _handle_retry(self, exc, "suggest_skills")


@shared_task(
    bind=True,
    name="ai.generate_bullets",
)
def generate_bullets_task(self, experience: list[dict]) -> dict:
    service = AIService()
    try:
        return service.generate_bullets(experience=experience)
    except Exception as exc:
        return _handle_retry(self, exc, "generate_bullets")
