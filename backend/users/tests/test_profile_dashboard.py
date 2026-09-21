from django.contrib.auth import get_user_model
from rest_framework.test import APITestCase

from resume.models import Resume
from users.models import UserProfile


class ProfileAndDashboardApiTests(APITestCase):
    def setUp(self):
        self.user = get_user_model().objects.create_user(
            email="profile-owner@example.com",
            password="StrongPass123!",
            is_verified=True,
        )
        self.client.force_authenticate(self.user)

    def test_profile_patch_preserves_unspecified_fields(self):
        profile = UserProfile.objects.get(user=self.user)
        profile.bio = "Existing biography"
        profile.location = "Existing city"
        profile.save(update_fields=["bio", "location"])

        response = self.client.patch(
            "/api/v1/profile/",
            {"full_name": "Updated Name", "phone": "123456"},
            format="json",
        )

        self.assertEqual(response.status_code, 200, response.data)
        profile.refresh_from_db()
        self.assertEqual(profile.full_name, "Updated Name")
        self.assertEqual(profile.phone, "123456")
        self.assertEqual(profile.bio, "Existing biography")
        self.assertEqual(profile.location, "Existing city")
        self.assertIn("profile_image_url", response.data)

    def test_profile_rejects_unsupported_fields(self):
        response = self.client.patch(
            "/api/v1/profile/",
            {"skills": ["Flutter"]},
            format="json",
        )

        self.assertEqual(response.status_code, 400)
        self.assertIn("skills", response.data)

    def test_dashboard_requires_authentication(self):
        self.client.force_authenticate(user=None)
        response = self.client.get("/api/v1/dashboard/")
        self.assertEqual(response.status_code, 401)

    def test_empty_dashboard_has_stable_shape(self):
        response = self.client.get("/api/v1/dashboard/")

        self.assertEqual(response.status_code, 200, response.data)
        self.assertIsNone(response.data["latest_resume"])
        self.assertIn("message", response.data)

    def test_dashboard_with_resume_but_no_analysis(self):
        """After removing resume_analyzer, dashboard returns resume info
        without analysis data and analysis_available is False."""
        Resume.objects.create(
            user=self.user,
            title="Backend Resume",
            data={"basics": {"name": "Owner"}},
        )

        response = self.client.get("/api/v1/dashboard/")

        self.assertEqual(response.status_code, 200, response.data)
        self.assertIsNotNone(response.data["latest_resume"])
        self.assertEqual(response.data["latest_resume"]["title"], "Backend Resume")
        self.assertFalse(response.data.get("analysis_available", True))
        self.assertIn("message", response.data)
