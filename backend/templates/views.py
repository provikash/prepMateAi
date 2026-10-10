import hashlib
import json
from uuid import UUID

from django.core.cache import cache
from django.db.models import Count, Max
from django.http import HttpResponseNotModified
from django.shortcuts import get_object_or_404
from rest_framework.permissions import AllowAny
from rest_framework.response import Response
from rest_framework.viewsets import ModelViewSet

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
            return base_qs.only(
                "id",
                "name",
                "slug",
                "description",
                "category",
                "version",
                "preview_image",
                "is_active",
                "updated_at",
            )
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

    def list(self, request, *args, **kwargs):
        version = self.get_queryset().aggregate(
            count=Count("id"), updated=Max("updated_at")
        )
        version_token = f"{version['count']}:{version['updated']}"
        page = request.query_params.get("page", "1")
        cache_key = f"v3:templates:list:{version_token}:{page}"
        payload = cache.get(cache_key)
        if payload is None:
            response = super().list(request, *args, **kwargs)
            payload = response.data
            cache.set(cache_key, payload, timeout=60 * 60 * 12)
        return self._conditional_response(request, payload, public_max_age=300)

    def retrieve(self, request, *args, **kwargs):
        instance = self.get_object()
        cache_key = (
            f"v3:template:{instance.pk}:{instance.version}:"
            f"{instance.updated_at.isoformat()}"
        )
        payload = cache.get(cache_key)
        if payload is None:
            payload = self.get_serializer(instance).data
            cache.set(cache_key, payload, timeout=60 * 60 * 24)
        return self._conditional_response(request, payload, public_max_age=3600)

    @staticmethod
    def _conditional_response(request, payload, *, public_max_age):
        encoded = json.dumps(
            payload, sort_keys=True, default=str, separators=(",", ":")
        )
        etag = '"' + hashlib.sha256(encoded.encode("utf-8")).hexdigest() + '"'
        if request.headers.get("If-None-Match") == etag:
            response = HttpResponseNotModified()
        else:
            response = Response(payload)
        response["ETag"] = etag
        response["Cache-Control"] = (
            f"public, max-age={public_max_age}, stale-while-revalidate=86400"
        )
        return response
