from django.urls import path

from .views import ResumeExportViewSet


urlpatterns = [
    path(
        "templates/<uuid:template_id>/preview/",
        ResumeExportViewSet.as_view({"post": "preview_template"}),
        name="template-preview",
    ),
]
