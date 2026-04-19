from celery import shared_task

from .services import AIService
from .services.exceptions import AIServiceProviderError, AIServiceTimeoutError


@shared_task(
    bind=True,
    name="ai.generate_summary",
    autoretry_for=(AIServiceTimeoutError, AIServiceProviderError),
    retry_backoff=True,
    retry_kwargs={"max_retries": 2},
)
def generate_summary_task(self, data: dict) -> dict:
    service = AIService()
    return service.generate_summary(data=data)


@shared_task(
    bind=True,
    name="ai.improve_section",
    autoretry_for=(AIServiceTimeoutError, AIServiceProviderError),
    retry_backoff=True,
    retry_kwargs={"max_retries": 2},
)
def improve_section_task(self, text: str, section_name: str) -> dict:
    service = AIService()
    return service.improve_section(text=text, section_name=section_name)


@shared_task(
    bind=True,
    name="ai.suggest_skills",
    autoretry_for=(AIServiceTimeoutError, AIServiceProviderError),
    retry_backoff=True,
    retry_kwargs={"max_retries": 2},
)
def suggest_skills_task(self, role: str, existing_skills: list[str] | None = None) -> dict:
    service = AIService()
    return service.suggest_skills(role=role, existing_skills=existing_skills)


@shared_task(
    bind=True,
    name="ai.generate_bullets",
    autoretry_for=(AIServiceTimeoutError, AIServiceProviderError),
    retry_backoff=True,
    retry_kwargs={"max_retries": 2},
)
def generate_bullets_task(self, experience: list[dict]) -> dict:
    service = AIService()
    return service.generate_bullets(experience=experience)
