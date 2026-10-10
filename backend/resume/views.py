import hashlib

from django.http import HttpResponse, HttpResponseNotModified
from rest_framework import viewsets
from rest_framework.decorators import action
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response

from core.permissions import IsOwner
from exports.services.pdf_service import PDFExportService

from .models import Resume
from .rendering import ResumeRenderService
from .serializers import ResumeDetailSerializer, ResumeListSerializer, ResumeSerializer


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
        queryset = Resume.objects.select_related("template").filter(user=self.request.user).order_by("-created_at")
        if self.action == "list":
            return queryset.only("id", "title", "created_at", "thumbnail", "pdf_file", "template__preview_image", "template__id", "user_id")
        return queryset

    def perform_create(self, serializer):
        serializer.save(user=self.request.user)

    @action(detail=True, methods=["post"], url_path="render")
    def render_preview(self, request, pk=None):
        resume = self.get_object()
        if not resume.template:
            return Response({"detail": "No template associated with this resume."}, status=400)
        html = ResumeRenderService.render_resume(resume.data, resume.template, resume_title=resume.title)
        return Response({"template": resume.template.slug, "template_version": resume.template_version, "html": html})

    @action(detail=True, methods=["get"], url_path="pdf")
    def generate_pdf(self, request, pk=None):
        current = self.get_object()
        validator = (
            f"{current.pk}:{current.updated_at.isoformat()}:"
            f"{current.template_version}"
        )
        etag = '"' + hashlib.sha256(validator.encode("utf-8")).hexdigest() + '"'
        if request.headers.get("If-None-Match") == etag:
            response = HttpResponseNotModified()
            response["ETag"] = etag
            response["Cache-Control"] = "private, no-cache"
            return response
        pdf_bytes, resume = PDFExportService.generate_pdf_bytes(resume_id=pk, user=request.user)
        return HttpResponse(
            pdf_bytes,
            content_type="application/pdf",
            headers={
                "Content-Disposition": f'inline; filename="resume_{resume.pk}.pdf"',
                "ETag": etag,
                "Cache-Control": "private, no-cache",
            },
        )

    @action(detail=True, methods=["get"], url_path="export")
    def export_pdf(self, request, pk=None):
        response = self.generate_pdf(request, pk=pk)
        response['Content-Disposition'] = f'attachment; filename="resume_{pk}.pdf"'
        return response
