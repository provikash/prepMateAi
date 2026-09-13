import json
from functools import lru_cache
from pathlib import Path


PROMPTS_DIR = Path(__file__).resolve().parent.parent / "prompts"


@lru_cache(maxsize=32)
def _load_prompt_template(filename: str) -> str:
	file_path = PROMPTS_DIR / filename
	return file_path.read_text(encoding="utf-8").strip()


def _render_prompt(template: str, mapping: dict[str, str]) -> str:
	rendered = template
	for key, value in mapping.items():
		rendered = rendered.replace(f"{{{key}}}", value)
	return rendered


def build_summary_prompt(data: dict) -> str:
	template = _load_prompt_template("summary.txt")
	candidate_data = json.dumps(data, ensure_ascii=True)
	return _render_prompt(template, {"candidate_data": candidate_data})


def build_improve_prompt(text: str, section_name: str = "section") -> str:
	template = _load_prompt_template("improve_section.txt")
	return _render_prompt(template, {"section_name": section_name, "section_text": text})


def build_skills_prompt(role: str, existing_skills: list[str] | None = None) -> str:
	template = _load_prompt_template("suggest_skills.txt")
	skills = existing_skills or []
	return _render_prompt(
		template,
		{
			"role": role,
			"existing_skills": json.dumps(skills, ensure_ascii=True),
		},
	)


def build_bullet_prompt(experience: list[dict]) -> str:
	template = _load_prompt_template("generate_bullets.txt")
	experience_data = json.dumps(experience, ensure_ascii=True)
	return _render_prompt(template, {"experience_data": experience_data})
