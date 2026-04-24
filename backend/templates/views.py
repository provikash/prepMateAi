from rest_framework.permissions import AllowAny
from rest_framework.viewsets import ReadOnlyModelViewSet

from .models import ResumeTemplate
from .serializers import TemplateSerializer


class TemplateViewSet(ReadOnlyModelViewSet):
    queryset = ResumeTemplate.objects.filter(is_active=True)
    serializer_class = TemplateSerializer
    permission_classes = [AllowAny]
