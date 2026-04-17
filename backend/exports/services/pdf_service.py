from django.template import Context, Template
from rest_framework.exceptions import NotFound, ValidationError

from resume.models import Resume


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

        template = Template(resume.template.html_structure)
        context = Context(
            {
                "resume": resume.data,
                "resume_title": resume.title,
                "user": resume.user,
            }
        )
        return template.render(context)

    @staticmethod
    def generate_pdf_bytes(resume_id, user):
        resume = PDFExportService._get_resume_for_user(resume_id=resume_id, user=user)

        html_content = PDFExportService._render_resume_html(resume)

        try:
            from weasyprint import HTML
        except ImportError as exc:
            raise ValidationError("WeasyPrint is not installed in the current environment.") from exc

        return HTML(string=html_content).write_pdf(), resume