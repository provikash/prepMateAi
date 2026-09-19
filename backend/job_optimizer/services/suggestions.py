"""Evidence-limited suggestion generation and deterministic validation."""

import json
import re

from django.conf import settings
from rest_framework.exceptions import ValidationError

from ai.services.openrouter import AIService

PROMPT_VERSION = "resume_optimizer_v1"
SYSTEM_PROMPT = """You are a resume optimization assistant. Rewrite only supplied resume text.
Use only facts explicitly supported by the supplied resume evidence. Never invent skills,
technologies, employers, projects, certifications, degrees, achievements, metrics, years,
responsibilities, tools or qualifications. A missing requirement is not experience.
If evidence is insufficient, return no suggestion. Preserve factual meaning.
Return one JSON object with a suggestions array matching the requested schema.
"""
ALLOWED_TYPES = {
    "SUMMARY_IMPROVEMENT", "EXPERIENCE_BULLET_IMPROVEMENT",
    "PROJECT_BULLET_IMPROVEMENT", "SKILL_EMPHASIS", "KEYWORD_ALIGNMENT",
}
EDITABLE_PATH = re.compile(r"^(basics\.summary|(?:work|projects)\[\d+\]\.(?:summary|description|highlights\[\d+\]))$")
PATH_PARTS = re.compile(r"([A-Za-z][A-Za-z0-9_]*)(?:\[(\d+)\])?")
RISKY_TERMS = {
    "aws", "azure", "gcp", "docker", "kubernetes", "flutter", "react", "dart",
    "kotlin", "firebase", "postgresql", "mysql", "redis", "python", "django",
    "java", "javascript", "typescript", "riverpod", "bloc", "git", "graphql",
    "certified", "certification", "managed", "led", "increased", "reduced",
    "improved", "saved", "deployed", "architected", "launched",
}
SAFE_REPHRASE_WORDS = {
    "a", "an", "the", "to", "for", "from", "in", "on", "of", "by", "and",
    "or", "with", "using", "used", "that", "which", "through", "across",
    "built", "build", "developed", "develop", "application", "applications",
    "app", "apps", "integrated", "integrate", "implemented", "implement",
    "supported", "support", "as", "at", "is", "was", "were",
}


def get_path(data, path):
    if not isinstance(path, str) or not EDITABLE_PATH.fullmatch(path):
        raise ValidationError("Unsupported resume path.")
    current = data
    for part in path.split("."):
        match = PATH_PARTS.fullmatch(part)
        if not match or not isinstance(current, dict) or match.group(1) not in current:
            raise ValidationError("Resume path does not exist.")
        current = current[match.group(1)]
        if match.group(2) is not None:
            index = int(match.group(2))
            if not isinstance(current, list) or index >= len(current):
                raise ValidationError("Resume path does not exist.")
            current = current[index]
    if not isinstance(current, str):
        raise ValidationError("Resume path must point to text.")
    return current


def set_path(data, path, value):
    get_path(data, path)
    current = data
    parts = path.split(".")
    for part in parts[:-1]:
        match = PATH_PARTS.fullmatch(part)
        current = current[match.group(1)]
        if match.group(2) is not None:
            current = current[int(match.group(2))]
    match = PATH_PARTS.fullmatch(parts[-1])
    if match.group(2) is None:
        current[match.group(1)] = value
    else:
        current[match.group(1)][int(match.group(2))] = value


class SuggestionValidator:
    def validate(self, proposal, *, candidate, resume_data):
        if not isinstance(proposal, dict) or proposal.get("should_suggest") is not True:
            raise ValidationError("AI did not provide a suggestion.")
        path = proposal.get("resume_path")
        if path != candidate["resume_path"]:
            raise ValidationError("Suggestion targeted an unapproved resume path.")
        original = get_path(resume_data, path)
        if proposal.get("original_value") != original or original != candidate["original_value"]:
            raise ValidationError("Original resume text does not match.")
        evidence_paths = proposal.get("evidence_paths")
        if not isinstance(evidence_paths, list) or not evidence_paths or any(
            path not in candidate["evidence_paths"] for path in evidence_paths
        ):
            raise ValidationError("Suggestion cites invalid evidence.")
        suggestion_type = proposal.get("suggestion_type")
        if suggestion_type not in ALLOWED_TYPES:
            raise ValidationError("Unsupported suggestion type.")
        value = proposal.get("suggested_value")
        if not isinstance(value, str) or not value.strip() or len(value) > 1500 or value.strip() == original.strip():
            raise ValidationError("Suggested text is empty, unchanged, or too long.")
        supported_text = original + " " + " ".join(candidate["evidence_texts"])
        numbers = set(re.findall(r"\b\d+(?:\.\d+)?%?\b", value))
        if numbers - set(re.findall(r"\b\d+(?:\.\d+)?%?\b", supported_text)):
            raise ValidationError("Suggestion contains unsupported metrics or experience.")
        value_words = set(re.findall(r"[a-z][a-z+#]*", value.lower()))
        supported_words = set(re.findall(r"[a-z][a-z+#]*", supported_text.lower()))
        if (value_words & RISKY_TERMS) - supported_words:
            raise ValidationError("Suggestion contains an unsupported claim or technology.")
        if value_words - supported_words - SAFE_REPHRASE_WORDS:
            raise ValidationError("Suggestion introduces details absent from resume evidence.")
        reason = proposal.get("reason")
        if not isinstance(reason, str) or not reason.strip():
            raise ValidationError("Suggestion reason is required.")
        keywords = proposal.get("keywords")
        if not isinstance(keywords, list) or any(not isinstance(k, str) for k in keywords):
            raise ValidationError("Invalid keywords.")
        return {
            "suggestion_type": suggestion_type,
            "resume_path": path,
            "original_value": original,
            "ai_suggestion": value.strip(),
            "reason": reason.strip()[:2000],
            "keywords": keywords[:10],
            "evidence_reference": evidence_paths,
            "prompt_version": PROMPT_VERSION,
        }


class SuggestionEngine:
    def __init__(self, ai_service=None):
        self.ai_service = ai_service or AIService()
        self.validator = SuggestionValidator()

    def candidates(self, session):
        resume_data = session.source_data_snapshot or session.source_resume.data or {}
        candidates = []
        seen_paths = set()
        for result in session.match_results_json.get("results", []):
            if result.get("status") not in ("MATCHED", "PARTIAL"):
                continue
            evidence = result.get("evidence") or []
            editable = next((item for item in evidence if EDITABLE_PATH.fullmatch(item.get("path", ""))), None)
            path = editable["path"] if editable else "basics.summary"
            if path in seen_paths:
                continue
            try:
                original = get_path(resume_data, path)
            except ValidationError:
                continue
            if not original.strip():
                continue
            seen_paths.add(path)
            candidates.append({
                "requirement": result.get("name", ""),
                "status": result["status"],
                "resume_path": path,
                "original_value": original,
                "evidence_paths": [e["path"] for e in evidence if e.get("path")],
                "evidence_texts": [e["text"] for e in evidence if e.get("text")],
            })
            if len(candidates) >= settings.OPTIMIZER_MAX_SUGGESTIONS:
                break
        return candidates

    def generate(self, session, *, instruction="", candidate_override=None):
        candidates = [candidate_override] if candidate_override else self.candidates(session)
        if not candidates:
            return [], None
        prompt = {
            "prompt_version": PROMPT_VERSION,
            "instruction": instruction[:300],
            "candidates": candidates,
            "schema": {"suggestions": [{
                "should_suggest": True, "suggestion_type": "PROJECT_BULLET_IMPROVEMENT",
                "resume_path": "projects[0].highlights[0]", "original_value": "exact original",
                "suggested_value": "evidence-backed rewrite", "reason": "why",
                "keywords": [], "evidence_paths": ["projects[0].highlights[0]"],
            }]},
        }
        response = self.ai_service.generate_json([
            {"role": "system", "content": SYSTEM_PROMPT},
            {"role": "user", "content": json.dumps(prompt)},
        ])
        proposals = response.content.get("suggestions")
        if not isinstance(proposals, list):
            raise ValidationError("AI response has no suggestions array.")
        by_path = {c["resume_path"]: c for c in candidates}
        accepted = []
        for proposal in proposals[:settings.OPTIMIZER_MAX_SUGGESTIONS]:
            candidate = by_path.get(proposal.get("resume_path")) if isinstance(proposal, dict) else None
            if candidate is None:
                continue
            try:
                accepted.append(self.validator.validate(
                    proposal, candidate=candidate,
                    resume_data=session.source_data_snapshot or session.source_resume.data or {},
                ))
            except ValidationError:
                continue
        return accepted, response
