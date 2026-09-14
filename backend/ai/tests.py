from unittest.mock import patch

from django.contrib.auth import get_user_model
from rest_framework.test import APITestCase


class ResumeAIEndpointTests(APITestCase):
    def setUp(self):
        self.user = get_user_model().objects.create_user(
            email="ai-test@example.com",
            password="test-password",
        )

    def test_improve_section_requires_authentication(self):
        response = self.client.post(
            "/api/v1/ai/improve-section/",
            {"section_name": "basics.summary", "text": "Original"},
            format="json",
        )
        self.assertEqual(response.status_code, 401)

    @patch("ai.views.improve_section")
    def test_improve_section_returns_existing_contract(self, improve):
        improve.return_value = {"improved_text": "Clearer summary"}
        self.client.force_authenticate(self.user)

        response = self.client.post(
            "/api/v1/ai/improve-section/",
            {"section_name": "basics.summary", "text": "Original"},
            format="json",
        )

        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.data, {"improved_text": "Clearer summary"})
        improve.assert_called_once_with(
            text="Original",
            section_name="basics.summary",
        )

    def test_improve_section_rejects_blank_and_oversized_text(self):
        self.client.force_authenticate(self.user)
        blank = self.client.post(
            "/api/v1/ai/improve-section/",
            {"section_name": "basics.summary", "text": "   "},
            format="json",
        )
        oversized = self.client.post(
            "/api/v1/ai/improve-section/",
            {"section_name": "basics.summary", "text": "x" * 4001},
            format="json",
        )
        self.assertEqual(blank.status_code, 400)
        self.assertEqual(oversized.status_code, 400)

    @patch("ai.views.generate_bullets")
    def test_generate_bullets_returns_list_contract(self, generate):
        generate.return_value = {"bullets": ["Built feature", "Reduced latency"]}
        self.client.force_authenticate(self.user)
        payload = {
            "experience": [
                {
                    "job_title": "Engineer",
                    "company": "Example Co",
                    "responsibilities": ["Built feature"],
                }
            ]
        }

        response = self.client.post(
            "/api/v1/ai/generate-bullets/",
            payload,
            format="json",
        )

        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.data["bullets"], ["Built feature", "Reduced latency"])
        generate.assert_called_once_with(experience=payload["experience"])

    @patch("ai.views.improve_section")
    def test_provider_failure_has_useful_status_code(self, improve):
        improve.return_value = {"status": "error", "message": "AI is busy."}
        self.client.force_authenticate(self.user)

        response = self.client.post(
            "/api/v1/ai/improve-section/",
            {"section_name": "basics.summary", "text": "Original"},
            format="json",
        )

        self.assertEqual(response.status_code, 503)
        self.assertEqual(response.data["message"], "AI is busy.")
