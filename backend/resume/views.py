import logging

from django.http import HttpResponse
from django.template import Context, Template
from rest_framework import status, viewsets
from rest_framework.decorators import action
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response

from core.permissions import IsOwner

from .models import Resume
from .rendering import ResumeRenderService
from .serializers import ResumeDetailSerializer, ResumeListSerializer, ResumeSerializer

logger = logging.getLogger(__name__)


class ResumeViewSet(viewsets.ModelViewSet):
    serializer_class = ResumeDetailSerializer
    permission_classes = [IsAuthenticated, IsOwner]

    def get_serializer_class(self):
        if self.action == "list":
            return ResumeListSerializer
        if self.action in {"create", "update", "partial_update"}:
            return ResumeSerializer
        return ResumeDetailSerializer

    def get_queryset(self):
        base_qs = Resume.objects.select_related("template").filter(user=self.request.user).order_by("-created_at")
        if self.action == "list":
            return base_qs.only(
                "id",
                "title",
                "created_at",
                "thumbnail",
                "pdf_file",
                "template__preview_image",
                "template__id",
                "user_id",
            )
        return base_qs

    def perform_create(self, serializer):
        serializer.save(user=self.request.user)

    @action(detail=True, methods=["get"], url_path="pdf")
    def generate_pdf(self, request, pk=None):
        """
        Renders the resume to PDF using the template's html_structure.

        Context passed to the template is always {"resume": <resume.data>}
        so templates can safely use {{ resume.personal_info.name }} etc.

        The pdf_file field is also updated on the Resume model so subsequent
        GET /resumes/{id}/ calls return a working pdf_url.
        """
        resume = self.get_object()

        if not resume.template:
            return Response(
                {"detail": "No template associated with this resume."},
                status=status.HTTP_400_BAD_REQUEST,
            )

        template = resume.template
        raw_html = template.html_structure or ""
        inline_css = template.css or ""

        # Prepare context — normalize data and inject has_* helper flags.
        context_data = ResumeRenderService.prepare_resume_context(resume.data)

        # Inject inline CSS into the HTML if the template doesn't already have
        # a <style> block (WeasyPrint only reads inline/embedded styles).
        if inline_css and "<style" not in raw_html:
            raw_html = f"<style>{inline_css}</style>\n{raw_html}"

        # Render the Django template string with our resume context.
        try:
            django_template = Template(raw_html)
            html = django_template.render(Context({"resume": context_data}))
        except Exception as exc:
            logger.exception("Template rendering failed for resume %s: %s", pk, exc)
            return Response(
                {"detail": f"Template rendering error: {exc}"},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR,
            )

        # Debug: log the first 2000 chars of rendered HTML in DEBUG mode.
        logger.debug("Rendered HTML (first 2000 chars):\n%s", html[:2000])

        # Generate PDF using WeasyPrint.
        try:
            from weasyprint import HTML as WeasyHTML

            pdf_bytes = WeasyHTML(string=html).write_pdf()
        except Exception as exc:
            logger.exception("PDF generation failed for resume %s: %s", pk, exc)
            return Response(
                {"detail": f"PDF generation error: {exc}"},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR,
            )

        # Persist the PDF file back to the Resume model.
        try:
            import io
            from django.core.files.base import ContentFile

            file_name = f"resume_{resume.pk}.pdf"
            resume.pdf_file.save(file_name, ContentFile(pdf_bytes), save=True)
        except Exception as exc:
            logger.warning("Could not persist PDF for resume %s: %s", pk, exc)

        return HttpResponse(
            pdf_bytes,
            content_type="application/pdf",
            headers={"Content-Disposition": f'inline; filename="resume_{resume.pk}.pdf"'},
        )
