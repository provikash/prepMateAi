from rest_framework.exceptions import NotFound, ValidationError

from resume.models import Resume
from resume.rendering import ResumeRenderService
from django.core.files.base import ContentFile
import logging

logger = logging.getLogger(__name__)


class PDFExportService:
    @staticmethod
    def _get_resume_for_user(resume_id, user):
        try:
            return Resume.objects.select_related("template").get(id=resume_id, user=user)
        except Resume.DoesNotExist as exc:
            raise NotFound("Resume not found.") from exc

    @staticmethod
    def _render_resume_html(resume):
        if not resume.template:
            raise ValidationError("Resume does not have an assigned template.")

        return ResumeRenderService.render_resume(resume.data, resume.template, resume_title=resume.title)

    @staticmethod
    def generate_pdf_bytes(resume_id, user):
        resume = PDFExportService._get_resume_for_user(resume_id=resume_id, user=user)

        html_content = PDFExportService._render_resume_html(resume)

        try:
            from weasyprint import HTML
        except ImportError as exc:
            raise ValidationError("WeasyPrint is not installed in the current environment.") from exc

        pdf_bytes = HTML(string=html_content).write_pdf()

        # Save PDF to resume.pdf_file so it's accessible via the model
        try:
            filename = f"resume_{resume.id}.pdf"
            # overwrite existing file
            resume.pdf_file.save(filename, ContentFile(pdf_bytes), save=True)
        except Exception:
            logger.exception("PDF was generated but could not be saved for resume %s", resume.id)

        return pdf_bytes, resume
