import json
import logging
import os
import re

import requests

logger = logging.getLogger(__name__)


class AIImprovementEngine:
    DEFAULT_TIMEOUT_SECONDS = 25

    @staticmethod
    def _provider_config() -> dict:
        return {
            "provider": os.getenv("AI_PROVIDER", "gemini").strip().lower(),
            "timeout": int(os.getenv("AI_TIMEOUT_SECONDS", str(AIImprovementEngine.DEFAULT_TIMEOUT_SECONDS))),
            "gemini_api_key": os.getenv("GEMINI_API_KEY", "").strip(),
            "gemini_model": os.getenv("GEMINI_MODEL", "gemini-1.5-flash").strip(),
            "openai_api_key": os.getenv("OPENAI_API_KEY", "").strip(),
            "openai_model": os.getenv("OPENAI_MODEL", "gpt-4o-mini").strip(),
        }

    @staticmethod
    def _parse_json(raw_text: str) -> dict:
        cleaned = (raw_text or "").strip()
        if not cleaned:
            return {}

        try:
            data = json.loads(cleaned)
            return data if isinstance(data, dict) else {}
        except json.JSONDecodeError:
            code_block_match = re.search(r"```(?:json)?\\s*(\{[\s\S]*\})\\s*```", cleaned)
            if code_block_match:
                try:
                    return json.loads(code_block_match.group(1))
                except json.JSONDecodeError:
                    return {}

            first = cleaned.find("{")
            last = cleaned.rfind("}")
            if first != -1 and last != -1 and last > first:
                try:
                    return json.loads(cleaned[first : last + 1])
                except json.JSONDecodeError:
                    return {}

        return {}

    @staticmethod
    def _call_openai(prompt: str, config: dict) -> str:
        if not config["openai_api_key"]:
            return ""

        url = "https://api.openai.com/v1/chat/completions"
        headers = {
            "Authorization": f"Bearer {config['openai_api_key']}",
            "Content-Type": "application/json",
        }
        payload = {
            "model": config["openai_model"],
            "temperature": 0.2,
            "messages": [
                {"role": "system", "content": "You are a strict JSON generator."},
                {"role": "user", "content": prompt},
            ],
            "response_format": {"type": "json_object"},
        }

        response = requests.post(url, headers=headers, json=payload, timeout=config["timeout"])
        if response.status_code >= 400:
            return ""

        body = response.json()
        return body.get("choices", [{}])[0].get("message", {}).get("content", "")

    @staticmethod
    def _call_gemini(prompt: str, config: dict) -> str:
        if not config["gemini_api_key"]:
            logger.error("Gemini API key is missing.")
            return ""

        # Use v1 as default but allowing fallback or specific versions
        api_version = os.getenv("GEMINI_API_VERSION", "v1beta").strip()
        model_name = config["gemini_model"]

        # Standardize model name if it looks like a typo (e.g., 2.5 -> 1.5)
        if "2.5" in model_name:
            logger.warning(f"Suspected model name typo: {model_name}. Attempting with gemini-1.5-flash.")
            model_name = "gemini-1.5-flash"

        url = (
            f"https://generativelanguage.googleapis.com/{api_version}/"
            f"models/{model_name}:generateContent?key={config['gemini_api_key']}"
        )

        payload = {
            "generationConfig": {
                "temperature": 0.2,
                "responseMimeType": "application/json",
            },
            "contents": [
                {
                    "parts": [
                        {
                            "text": "You are a strict JSON generator. Return valid JSON only.\n\n" + prompt
                        }
                    ]
                }
            ],
        }

        try:
            response = requests.post(url, json=payload, timeout=config["timeout"])
            if response.status_code != 200:
                logger.error(f"Gemini API Error {response.status_code}: {response.text}")
                return ""

            body = response.json()
            candidates = body.get("candidates", [])
            if not candidates:
                logger.warning("Gemini returned no candidates.")
                return ""

            return candidates[0].get("content", {}).get("parts", [{}])[0].get("text", "")
        except Exception as e:
            logger.error(f"Gemini Request Exception: {str(e)}")
            return ""

    @staticmethod
    def _call_provider(prompt: str) -> dict:
        config = AIImprovementEngine._provider_config()

        try:
            if config["provider"] == "openai":
                raw = AIImprovementEngine._call_openai(prompt, config)
            else:
                raw = AIImprovementEngine._call_gemini(prompt, config)
        except requests.RequestException:
            return {}

        return AIImprovementEngine._parse_json(raw)

    @staticmethod
    def structure_resume_text(raw_text: str, job_role: str) -> dict:
        prompt = (
            "Convert the following resume text into JSON with keys: "
            "personal_info, skills, experience, projects, education. "
            "Return arrays/objects only and never markdown. "
            f"Target role: {job_role}.\\n\\nResume Text:\\n{raw_text[:12000]}"
        )
        response = AIImprovementEngine._call_provider(prompt)
        return response if isinstance(response, dict) else {}

    @staticmethod
    def generate_suggestions(structured_data: dict, analysis_data: dict, job_role: str) -> list[str]:
        prompt = (
            "You are an ATS expert. Generate concise actionable suggestions. "
            "Return JSON object: {\"suggestions\": [\"...\"]}. "
            f"Role: {job_role}. Resume data: {json.dumps(structured_data, ensure_ascii=True)[:10000]}. "
            f"Analysis: {json.dumps(analysis_data, ensure_ascii=True)[:5000]}"
        )
        response = AIImprovementEngine._call_provider(prompt)
        suggestions = response.get("suggestions", []) if isinstance(response, dict) else []

        cleaned = [item.strip() for item in suggestions if isinstance(item, str) and item.strip()]
        if cleaned:
            return cleaned[:12]

        # Fallback suggestions when provider is unavailable or quota-limited.
        return [
            "Rewrite summary with role-focused impact and measurable outcomes.",
            "Add missing role keywords naturally in experience and project bullets.",
            "Use action verbs and quantifiable achievements for each experience entry.",
            "Add missing technical skills required for the target role.",
        ]
