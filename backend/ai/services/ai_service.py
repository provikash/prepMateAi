import json
import os
import re

import requests

from .exceptions import (
	AIServiceConfigurationError,
	AIServiceProviderError,
	AIServiceResponseError,
	AIServiceTimeoutError,
)
from .prompt_builder import (
	build_bullet_prompt,
	build_improve_prompt,
	build_skills_prompt,
	build_summary_prompt,
)


class AIService:
	DEFAULT_TIMEOUT_SECONDS = 25

	def __init__(self):
		self.provider = os.getenv("AI_PROVIDER", "gemini").strip().lower()
		self.timeout = int(os.getenv("AI_TIMEOUT_SECONDS", str(self.DEFAULT_TIMEOUT_SECONDS)))

		self.openai_api_key = os.getenv("OPENAI_API_KEY", "").strip()
		self.openai_model = os.getenv("OPENAI_MODEL", "gpt-4o-mini").strip()

		self.gemini_api_key = os.getenv("GEMINI_API_KEY", "").strip()
		self.gemini_model = os.getenv("GEMINI_MODEL", "gemini-2.5-flash").strip()

	def generate_summary(self, data: dict) -> dict:
		prompt = build_summary_prompt(data)
		result = self._generate_json_response(prompt=prompt, expected_key="summary")
		return {"summary": result["summary"]}

	def improve_section(self, text: str, section_name: str = "section") -> dict:
		prompt = build_improve_prompt(text=text, section_name=section_name)
		result = self._generate_json_response(prompt=prompt, expected_key="improved_text")
		return {"improved_text": result["improved_text"]}

	def suggest_skills(self, role: str, existing_skills: list[str] | None = None) -> dict:
		prompt = build_skills_prompt(role=role, existing_skills=existing_skills)
		result = self._generate_json_response(prompt=prompt, expected_key="skills")

		skills = result["skills"]
		if not isinstance(skills, list):
			raise AIServiceResponseError("AI response field 'skills' must be a list.")

		cleaned_skills = [item.strip() for item in skills if isinstance(item, str) and item.strip()]
		return {"skills": cleaned_skills}

	def generate_bullets(self, experience: list[dict]) -> dict:
		prompt = build_bullet_prompt(experience=experience)
		result = self._generate_json_response(prompt=prompt, expected_key="bullets")

		bullets = result["bullets"]
		if not isinstance(bullets, list):
			raise AIServiceResponseError("AI response field 'bullets' must be a list.")

		cleaned_bullets = [item.strip() for item in bullets if isinstance(item, str) and item.strip()]
		return {"bullets": cleaned_bullets}

	def _generate_json_response(self, prompt: str, expected_key: str) -> dict:
		raw_text = self._call_provider(prompt)
		parsed = self._parse_json(raw_text)

		if expected_key not in parsed:
			raise AIServiceResponseError(f"AI response missing expected key: {expected_key}.")

		return parsed

	def _call_provider(self, prompt: str) -> str:
		if self.provider == "openai":
			return self._call_openai(prompt)
		if self.provider == "gemini":
			return self._call_gemini(prompt)
		raise AIServiceConfigurationError("Unsupported AI_PROVIDER. Use 'openai' or 'gemini'.")

	def _call_openai(self, prompt: str) -> str:
		if not self.openai_api_key:
			raise AIServiceConfigurationError("OPENAI_API_KEY is not configured.")

		url = "https://api.openai.com/v1/chat/completions"
		headers = {
			"Authorization": f"Bearer {self.openai_api_key}",
			"Content-Type": "application/json",
		}
		payload = {
			"model": self.openai_model,
			"temperature": 0.3,
			"messages": [
				{"role": "system", "content": "You are a strict JSON generator."},
				{"role": "user", "content": prompt},
			],
			"response_format": {"type": "json_object"},
		}

		try:
			response = requests.post(url, headers=headers, json=payload, timeout=self.timeout)
		except requests.Timeout as exc:
			raise AIServiceTimeoutError("OpenAI request timed out.") from exc
		except requests.RequestException as exc:
			raise AIServiceProviderError("OpenAI request failed.") from exc

		if response.status_code >= 400:
			raise AIServiceProviderError(
				f"OpenAI returned status {response.status_code}: {response.text[:500]}"
			)

		data = response.json()
		try:
			return data["choices"][0]["message"]["content"]
		except (KeyError, IndexError, TypeError) as exc:
			raise AIServiceResponseError("Invalid OpenAI response format.") from exc

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
			response = requests.post(url, json=payload, timeout=self.timeout)
		except requests.Timeout as exc:
			raise AIServiceTimeoutError("Gemini request timed out.") from exc
		except requests.RequestException as exc:
			raise AIServiceProviderError("Gemini request failed.") from exc

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
