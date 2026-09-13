from django.http import HttpResponse
from rest_framework.permissions import IsAuthenticated
from rest_framework.viewsets import ViewSet

from .services.pdf_service import PDFExportService
from django.template import Template, Context
from django.http import HttpResponse, JsonResponse
from django.apps import apps


class ResumeExportViewSet(ViewSet):
    permission_classes = [IsAuthenticated]

    def export(self, request, resume_id=None):
        pdf_bytes, resume = PDFExportService.generate_pdf_bytes(
            resume_id=resume_id,
            user=request.user,
        )

        response = HttpResponse(pdf_bytes, content_type="application/pdf")
        response["Content-Disposition"] = f'attachment; filename="{resume.title}.pdf"'
        return response

    def preview_template(self, request, template_id=None):
        """Render template HTML using provided JSON payload and return HTML string."""
        try:
            TemplateModel = apps.get_model("templates", "ResumeTemplate")
        except LookupError:
            return JsonResponse({"detail": "Template model not available."}, status=500)

        try:
            template_obj = TemplateModel.objects.get(id=template_id)
        except TemplateModel.DoesNotExist:
            return JsonResponse({"detail": "Template not found."}, status=404)

        data = request.data.get("data", {})

        # Prepare normalized context similar to PDFExportService
        from resume.rendering import ResumeRenderService

        normalized_data = ResumeRenderService.prepare_resume_context(data)
        personal_info = normalized_data.get("personal_info", {})

        template = Template(template_obj.html_structure)
        context = Context(
            {
                "resume": normalized_data,
                **normalized_data,
                "name": personal_info.get("name", ""),
                "resume_title": normalized_data.get("title", "Preview"),
            }
        )

        rendered = template.render(context)
        return HttpResponse(rendered, content_type="text/html")