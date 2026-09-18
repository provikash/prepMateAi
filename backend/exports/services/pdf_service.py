from django.db import transaction
from rest_framework.exceptions import APIException, NotFound, ValidationError

from resume.models import Resume
from resume.rendering import ResumeRenderService
from django.core.files.base import ContentFile
import logging

logger = logging.getLogger(__name__)


class PDFGenerationUnavailable(APIException):
    status_code = 503
    default_detail = "The PDF could not be generated right now. Please try again."
    default_code = "pdf_generation_unavailable"


class PDFExportService:
    @staticmethod
    def _get_resume_for_user(resume_id, user):
        try:
            return Resume.objects.select_for_update().select_related("template").get(id=resume_id, user=user)
        except Resume.DoesNotExist as exc:
            raise NotFound("Resume not found.") from exc

    @staticmethod
    def _render_resume_html(resume):
        if not resume.template:
            raise ValidationError("Resume does not have an assigned template.")

        return ResumeRenderService.render_resume(resume.data, resume.template, resume_title=resume.title)

    @staticmethod
    @transaction.atomic
    def generate_pdf_bytes(resume_id, user):
        resume = PDFExportService._get_resume_for_user(resume_id=resume_id, user=user)

        # The serializer invalidates this file whenever render inputs change.
        # Reusing it makes repeated/double-tapped GETs idempotent.
        if resume.pdf_file:
            try:
                resume.pdf_file.open("rb")
                return resume.pdf_file.read(), resume
            except OSError:
                logger.warning("Stored PDF is unreadable for resume %s; regenerating", resume.id)
            finally:
                try:
                    resume.pdf_file.close()
                except Exception:
                    pass

        html_content = PDFExportService._render_resume_html(resume)

        try:
            from weasyprint import HTML
        except ImportError as exc:
            raise ValidationError("WeasyPrint is not installed in the current environment.") from exc

        try:
            pdf_bytes = HTML(string=html_content).write_pdf()
        except Exception as exc:
            logger.exception("PDF rendering failed for resume %s", resume.id)
            raise PDFGenerationUnavailable() from exc

        if not pdf_bytes:
            raise PDFGenerationUnavailable("The PDF renderer returned an empty document. Please try again.")

        # Save PDF to resume.pdf_file so it's accessible via the model
        try:
            filename = f"resume_{resume.id}.pdf"
            # overwrite existing file
            resume.pdf_file.save(filename, ContentFile(pdf_bytes), save=True)
        except Exception as exc:
            logger.exception("PDF was generated but could not be saved for resume %s", resume.id)
            raise PDFGenerationUnavailable("The PDF was generated but could not be stored. Please try again.") from exc

        return pdf_bytes, resume
