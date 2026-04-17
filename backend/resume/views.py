from rest_framework import viewsets
from rest_framework.permissions import IsAuthenticated

from core.permissions import IsOwner

from .models import Resume
from .serializers import ResumeSerializer


class ResumeViewSet(viewsets.ModelViewSet):
    serializer_class = ResumeSerializer
    permission_classes = [IsAuthenticated, IsOwner]

    def get_queryset(self):
        return Resume.objects.select_related("template").filter(user=self.request.user)

    def perform_create(self, serializer):
        serializer.save(user=self.request.user)
