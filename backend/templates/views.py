from rest_framework.permissions import AllowAny
from rest_framework.viewsets import ModelViewSet
from django.shortcuts import get_object_or_404
from uuid import UUID

from .models import ResumeTemplate
from .serializers import TemplateDetailSerializer, TemplateListSerializer


class TemplateViewSet(ModelViewSet):
    serializer_class = TemplateDetailSerializer
    permission_classes = [AllowAny]
    http_method_names = ["get", "head", "options"]
    lookup_field = "slug"

    def get_serializer_class(self):
        if self.action == "list":
            return TemplateListSerializer
        return TemplateDetailSerializer

    def get_queryset(self):
        base_qs = ResumeTemplate.objects.filter(is_active=True).order_by("name")
        if self.action == "list":
            return base_qs.only("id", "name", "slug", "description", "category", "version", "preview_image", "is_active")
        return base_qs

    def get_object(self):
        value = self.kwargs[self.lookup_field]
        queryset = self.filter_queryset(self.get_queryset())
        try:
            UUID(str(value))
        except (TypeError, ValueError, AttributeError):
            obj = get_object_or_404(queryset, slug=value)
        else:
            obj = get_object_or_404(queryset, pk=value)
        self.check_object_permissions(self.request, obj)
        return obj
