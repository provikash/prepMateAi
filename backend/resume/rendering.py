import json
import logging
from pathlib import Path

from django.template.loader import render_to_string
from rest_framework.exceptions import ValidationError

from .json_resume import prepare_context

logger = logging.getLogger(__name__)


class ResumeRenderingError(ValidationError):
    default_detail = "Resume could not be rendered."


class ThemeRegistry:
    THEMES = {
        "professional": {
            "template": "resume_themes/professional/template.html",
            "metadata": Path(__file__).parent / "templates" / "resume_themes" / "professional" / "metadata.json",
        },
        "thomas-slate": {
            "template": "resume_themes/thomas_slate/template.html",
            "metadata": Path(__file__).parent / "templates" / "resume_themes" / "thomas_slate" / "metadata.json",
        },
        "thomas-desert-modern": {
            "template": "resume_themes/thomas_desert_modern/template.html",
            "metadata": Path(__file__).parent / "templates" / "resume_themes" / "thomas_desert_modern" / "metadata.json",
        },
        "thomas-navy-sidebar": {
            "template": "resume_themes/thomas_navy_sidebar/template.html",
            "metadata": Path(__file__).parent / "templates" / "resume_themes" / "thomas_navy_sidebar" / "metadata.json",
        },
    }

    @classmethod
    def resolve(cls, template):
        identifier = getattr(template, "theme_identifier", "")
        if not getattr(template, "is_active", False) or identifier not in cls.THEMES:
            raise ResumeRenderingError("The selected resume theme is unavailable.")
        theme = cls.THEMES[identifier]
        metadata = json.loads(theme["metadata"].read_text(encoding="utf-8"))
        if int(getattr(template, "version", 0)) != int(metadata["version"]):
            raise ResumeRenderingError("The selected resume theme version is unavailable.")
        return {**theme, "metadata_data": metadata}


class ResumeRenderService:
    @staticmethod
    def prepare_resume_context(data):
        return prepare_context(data)

    @classmethod
    def render_resume(cls, resume_data, template, *, resume_title=""):
        theme = ThemeRegistry.resolve(template)
        context = cls.prepare_resume_context(resume_data)
        logger.debug(
            "Rendering resume theme=%s sections=%s",
            getattr(template, "theme_identifier", ""),
            sorted(key for key, value in context.items() if value),
        )
        try:
            html = render_to_string(theme["template"], {"resume": context, "resume_title": resume_title})
        except Exception as exc:
            raise ResumeRenderingError() from exc
        return html
