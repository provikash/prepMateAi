from rest_framework import viewsets
from rest_framework.permissions import IsAuthenticated

from core.permissions import IsOwner

from .models import Resume
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
