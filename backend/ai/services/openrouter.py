"""OpenRouter transport for server-side, structured AI operations."""

import json
import time
from dataclasses import dataclass
from decimal import Decimal
from typing import Protocol

import requests
from django.conf import settings

from core.monitoring import report_operational_failure
from .exceptions import (
    AIServiceConfigurationError,
    AIServiceProviderError,
    AIServiceResponseError,
    AIServiceTimeoutError,
)


@dataclass(frozen=True)
class AIResult:
    content: dict
    model: str
    input_tokens: int
    output_tokens: int
    total_tokens: int
    request_id: str
    latency_ms: int
    estimated_cost: Decimal | None = None


class AIProvider(Protocol):
    name: str

    def generate(self, messages, *, model=None, temperature=0.2) -> AIResult:
        ...


class OpenRouterProvider:
    name = "openrouter"

    def generate(self, messages, *, model=None, temperature=0.2):
        key = settings.OPENROUTER_API_KEY
        selected_model = model or settings.OPENROUTER_MODEL_NAME
        if not key or not selected_model:
            raise AIServiceConfigurationError("OpenRouter is not configured.")
        started = time.monotonic()
        try:
            response = requests.post(
                settings.OPENROUTER_API_BASE_URL.rstrip("/") + "/chat/completions",
                headers={"Authorization": f"Bearer {key}", "Content-Type": "application/json"},
                json={
                    "model": selected_model,
                    "messages": messages,
                    "temperature": temperature,
                    "response_format": {"type": "json_object"},
                },
                timeout=settings.AI_TIMEOUT_SECONDS,
            )
        except requests.Timeout as exc:
            report_operational_failure(
                "provider_timeout", provider="openrouter", exception=exc,
                model=selected_model,
            )
            raise AIServiceTimeoutError("AI request timed out.") from exc
        except requests.RequestException as exc:
            report_operational_failure(
                "provider_request_failed", provider="openrouter", exception=exc,
                model=selected_model,
            )
            raise AIServiceProviderError("AI provider is unavailable.") from exc
        if response.status_code >= 400:
            report_operational_failure(
                "provider_response_failed", provider="openrouter",
                status_code=response.status_code, model=selected_model,
            )
            raise AIServiceProviderError(f"AI provider returned HTTP {response.status_code}.")
        try:
            body = response.json()
            content = json.loads(body["choices"][0]["message"]["content"])
            if not isinstance(content, dict):
                raise ValueError("Expected a JSON object")
            usage = body.get("usage") or {}
            return AIResult(
                content=content,
                model=str(body.get("model") or selected_model),
                input_tokens=int(usage.get("prompt_tokens") or 0),
                output_tokens=int(usage.get("completion_tokens") or 0),
                total_tokens=int(usage.get("total_tokens") or 0),
                request_id=str(body.get("id") or ""),
                latency_ms=int((time.monotonic() - started) * 1000),
                estimated_cost=Decimal(str(usage["cost"])) if usage.get("cost") is not None else None,
            )
        except (ValueError, KeyError, IndexError, TypeError) as exc:
            report_operational_failure(
                "provider_invalid_response", provider="openrouter", exception=exc,
                model=selected_model,
            )
            raise AIServiceResponseError("AI provider returned invalid structured output.") from exc


class AIService:
    def __init__(self, provider: AIProvider | None = None):
        self.provider = provider or OpenRouterProvider()

    def generate_json(self, messages):
        return self.provider.generate(messages)
