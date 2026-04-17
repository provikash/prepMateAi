from django.http import HttpResponse
from rest_framework.permissions import IsAuthenticated
from rest_framework.viewsets import ViewSet

from .services.pdf_service import PDFExportService


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