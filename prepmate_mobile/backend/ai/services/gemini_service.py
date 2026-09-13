import json
import logging
import os
import re

import requests
from requests.adapters import HTTPAdapter
from urllib3.util.retry import Retry

from .exceptions import (
	AIServiceConfigurationError,
	AIServiceProviderError,
	AIServiceResponseError,
	AIServiceTimeoutError,
)

logger = logging.getLogger(__name__)


class GeminiService:
	DEFAULT_TIMEOUT_SECONDS = 25

	def __init__(self):
		self.timeout = int(os.getenv("AI_TIMEOUT_SECONDS", str(self.DEFAULT_TIMEOUT_SECONDS)))

		self.gemini_api_key = os.getenv("GEMINI_API_KEY", "").strip()
		self.gemini_model = os.getenv("GEMINI_MODEL", "gemini-2.5-flash").strip()

		self.session = requests.Session()
		retry_strategy = Retry(
			total=2,
			status_forcelist=[429, 500, 502, 503, 504],
			allowed_methods=["POST"],
			backoff_factor=0.8,
		)
		adapter = HTTPAdapter(max_retries=retry_strategy)
		self.session.mount("https://", adapter)
		self.session.mount("http://", adapter)

	def generate_json_response(self, prompt: str, expected_key: str) -> dict:
		raw_text = self._call_gemini(prompt)
		parsed = self._parse_json(raw_text)

		if expected_key not in parsed:
			raise AIServiceResponseError(f"AI response missing expected key: {expected_key}.")

		return parsed

	def _call_gemini(self, prompt: str) -> str:
		if not self.gemini_api_key:
			raise AIServiceConfigurationError("GEMINI_API_KEY is not configured.")

		url = (
			"https://generativelanguage.googleapis.com/v1beta/"
			f"models/{self.gemini_model}:generateContent?key={self.gemini_api_key}"
		)
		payload = {
			"generationConfig": {
				"temperature": 0.3,
				"responseMimeType": "application/json",
			},
			"contents": [
				{
					"parts": [
						{
							"text": (
								"You are a strict JSON generator. Return valid JSON only.\n\n"
								+ prompt
							)
						}
					]
				}
			],
		}

		try:
			response = self.session.post(url, json=payload, timeout=self.timeout)
		except requests.Timeout as exc:
			logger.exception("Gemini request timed out: %s", exc)
			raise AIServiceTimeoutError("Gemini request timed out.") from exc
		except requests.RequestException as exc:
			logger.exception("Gemini request failed: %s", exc)
			raise AIServiceProviderError(f"Gemini request failed: {exc}") from exc

		if response.status_code >= 400:
			raise AIServiceProviderError(
				f"Gemini returned status {response.status_code}: {response.text[:500]}"
			)

		data = response.json()
		try:
			return data["candidates"][0]["content"]["parts"][0]["text"]
		except (KeyError, IndexError, TypeError) as exc:
			raise AIServiceResponseError("Invalid Gemini response format.") from exc

	@staticmethod
	def _parse_json(raw_text: str) -> dict:
		if not isinstance(raw_text, str) or not raw_text.strip():
			raise AIServiceResponseError("AI response body is empty.")

		trimmed = raw_text.strip()
		try:
			parsed = json.loads(trimmed)
		except json.JSONDecodeError:
			parsed = AIService._parse_json_from_code_block_or_fragment(trimmed)

		if not isinstance(parsed, dict):
			raise AIServiceResponseError("AI response must be a JSON object.")
		return parsed

	@staticmethod
	def _parse_json_from_code_block_or_fragment(raw_text: str) -> dict:
		code_block_match = re.search(r"```(?:json)?\s*(\{[\s\S]*\})\s*```", raw_text)
		if code_block_match:
			return json.loads(code_block_match.group(1))

		first_brace = raw_text.find("{")
		last_brace = raw_text.rfind("}")
		if first_brace != -1 and last_brace != -1 and last_brace > first_brace:
			return json.loads(raw_text[first_brace : last_brace + 1])

		raise AIServiceResponseError("AI response is not valid JSON.")
