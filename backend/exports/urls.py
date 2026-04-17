from django.urls import path

from .views import ResumeExportViewSet


urlpatterns = [
    path(
        "resumes/<uuid:resume_id>/export/",
        ResumeExportViewSet.as_view({"get": "export"}),
        name="resume-export",
    ),
]