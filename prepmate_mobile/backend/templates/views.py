from rest_framework.permissions import AllowAny
from rest_framework.viewsets import ModelViewSet

from .models import ResumeTemplate
from .serializers import TemplateDetailSerializer, TemplateListSerializer


class TemplateViewSet(ModelViewSet):
    serializer_class = TemplateDetailSerializer
    permission_classes = [AllowAny]
    http_method_names = ["get", "head", "options"]

    def get_serializer_class(self):
        if self.action == "list":
            return TemplateListSerializer
        return TemplateDetailSerializer

    def get_queryset(self):
        base_qs = ResumeTemplate.objects.filter(is_active=True).order_by("name")
        if self.action == "list":
            return base_qs.only("id", "name", "category", "preview_image")
        return base_qs
