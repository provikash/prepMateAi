from django.core.cache import cache
from django.test import TestCase
from rest_framework.test import APIClient

from resume.models import ResumeTemplate

class TemplateHttpCacheTests(TestCase):
    def setUp(self):
        cache.clear()
        self.client = APIClient()
        self.template = ResumeTemplate.objects.create(
            name="Professional",
            slug="professional-cache-test",
            html_structure="<p>{{ basics.name }}</p>",
            metadata={"form_schema": {"sections": []}},
        )

    def test_list_supports_etag_validation(self):
        first = self.client.get("/api/v1/templates/")
        self.assertEqual(first.status_code, 200)
        self.assertIn("public", first["Cache-Control"])
        second = self.client.get(
            "/api/v1/templates/", HTTP_IF_NONE_MATCH=first["ETag"]
        )
        self.assertEqual(second.status_code, 304)

    def test_detail_etag_changes_after_template_update(self):
        url = f"/api/v1/templates/{self.template.slug}/"
        first = self.client.get(url)
        self.template.name = "Updated Professional"
        self.template.version += 1
        self.template.save()
        second = self.client.get(url, HTTP_IF_NONE_MATCH=first["ETag"])
        self.assertEqual(second.status_code, 200)
        self.assertNotEqual(first["ETag"], second["ETag"])
