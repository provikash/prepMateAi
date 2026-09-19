from django.contrib.auth import get_user_model
from django.test import TestCase
from rest_framework import status
from rest_framework.test import APIClient

from job_optimizer.models import JobDescription, OptimizationSession
from resume.models import Resume

User = get_user_model()


class JobOptimizerAPITest(TestCase):
    def setUp(self):
        self.client = APIClient()

        self.user_a = User.objects.create_user(
            email="user_a@example.com",
            password="passwordA123!",
            name="User A",
        )
        self.user_b = User.objects.create_user(
            email="user_b@example.com",
            password="passwordB123!",
            name="User B",
        )

        self.resume_a = Resume.objects.create(
            user=self.user_a,
            title="User A Resume",
            data={
                "basics": {"name": "User A", "label": "Flutter Developer", "summary": "Experienced Flutter mobile engineer."},
                "skills": [{"name": "Tech", "keywords": ["Flutter", "Dart", "Firebase"]}],
                "projects": [
                    {
                        "name": "App Alpha",
                        "description": "Cross platform app.",
                        "technologies": ["Flutter", "Dart", "REST APIs"],
                    }
                ],
            },
        )

        self.resume_b = Resume.objects.create(
            user=self.user_b,
            title="User B Resume",
            data={"basics": {"name": "User B"}},
        )

    def test_unauthenticated_requests_are_rejected(self):
        resp = self.client.get("/api/v1/job-optimizer/sessions/")
        self.assertEqual(resp.status_code, status.HTTP_401_UNAUTHORIZED)

    def test_user_cannot_create_session_with_another_users_resume(self):
        self.client.force_authenticate(user=self.user_a)

        # Attempt to create session using User B's resume
        payload = {
            "resume_id": str(self.resume_b.id),
            "job_description": {
                "title": "Flutter Dev",
                "description": "We need Flutter and Dart engineers.",
            },
        }
        resp = self.client.post("/api/v1/job-optimizer/sessions/", payload, format="json")
        self.assertEqual(resp.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertIn("resume_id", resp.data)

    def test_create_jd_and_optimization_session(self):
        self.client.force_authenticate(user=self.user_a)

        # 1. Create JD
        jd_payload = {
            "title": "Junior Flutter Developer",
            "company": "TechNova",
            "description": "Looking for Flutter, Dart, REST APIs, and Firebase experience. Git is required.",
        }
        jd_resp = self.client.post("/api/v1/job-optimizer/job-descriptions/", jd_payload, format="json")
        self.assertEqual(jd_resp.status_code, status.HTTP_201_CREATED)
        jd_id = jd_resp.data["id"]

        # 2. Create Session
        session_payload = {
            "resume_id": str(self.resume_a.id),
            "job_description_id": jd_id,
        }
        session_resp = self.client.post("/api/v1/job-optimizer/sessions/", session_payload, format="json")
        self.assertEqual(session_resp.status_code, status.HTTP_201_CREATED)
        session_id = session_resp.data["id"]
        self.assertEqual(session_resp.data["status"], "DRAFT")

        # 3. User B cannot access User A's session
        self.client.force_authenticate(user=self.user_b)
        get_resp = self.client.get(f"/api/v1/job-optimizer/sessions/{session_id}/")
        self.assertEqual(get_resp.status_code, status.HTTP_404_NOT_FOUND)

        # 4. User A analyzes job description
        self.client.force_authenticate(user=self.user_a)
        analyze_resp = self.client.post(f"/api/v1/job-optimizer/sessions/{session_id}/analyze/")
        self.assertEqual(analyze_resp.status_code, status.HTTP_200_OK)
        self.assertEqual(analyze_resp.data["status"], "ANALYZED")
        analysis_json = analyze_resp.data["analysis_json"]
        self.assertIn("Flutter", analysis_json["required_skills"])

        # 5. User A runs evidence matching
        match_resp = self.client.post(f"/api/v1/job-optimizer/sessions/{session_id}/match/")
        self.assertEqual(match_resp.status_code, status.HTTP_200_OK)
        self.assertEqual(match_resp.data["status"], "READY_FOR_REVIEW")
        match_results = match_resp.data["match_results_json"]
        self.assertTrue(match_results["summary"]["matched"] > 0)
        self.assertTrue(len(match_results["matched_requirements"]) > 0)

        self.resume_a.refresh_from_db()
        self.assertEqual(self.resume_a.data["skills"][0]["keywords"], ["Flutter", "Dart", "Firebase"])

    def test_match_requires_analysis(self):
        self.client.force_authenticate(user=self.user_a)
        jd = JobDescription.objects.create(user=self.user_a, description="Flutter required")
        session = OptimizationSession.objects.create(
            user=self.user_a, source_resume=self.resume_a, job_description=jd,
        )
        response = self.client.post(f"/api/v1/job-optimizer/sessions/{session.id}/match/")
        self.assertEqual(response.status_code, status.HTTP_409_CONFLICT)

    def test_cannot_use_another_users_job_description(self):
        jd = JobDescription.objects.create(user=self.user_b, description="Flutter required")
        self.client.force_authenticate(user=self.user_a)
        response = self.client.post(
            "/api/v1/job-optimizer/sessions/",
            {"resume_id": str(self.resume_a.id), "job_description_id": str(jd.id)},
            format="json",
        )
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertFalse(OptimizationSession.objects.exists())

    def test_job_description_requires_nonempty_description(self):
        self.client.force_authenticate(user=self.user_a)
        for payload in ({}, {"description": ""}):
            with self.subTest(payload=payload):
                response = self.client.post(
                    "/api/v1/job-optimizer/job-descriptions/", payload, format="json",
                )
                self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)

    def test_raw_job_description_is_preserved(self):
        self.client.force_authenticate(user=self.user_a)
        raw = "  Flutter and Dart experience required.\n\n"
        response = self.client.post(
            "/api/v1/job-optimizer/job-descriptions/",
            {"description": raw}, format="json",
        )
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        self.assertEqual(JobDescription.objects.get(id=response.data["id"]).description, raw)
