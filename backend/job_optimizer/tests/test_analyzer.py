from django.test import TestCase

from job_optimizer.services.jd_analyzer import JDAnalyzer


class JDAnalyzerTest(TestCase):
    def setUp(self):
        self.analyzer = JDAnalyzer()

    def test_analyze_flutter_jd(self):
        jd_text = """
        Job Title: Junior Flutter Developer
        Company: TechNova

        Responsibilities:
        - Build and maintain Flutter applications for Android and iOS
        - Integrate REST APIs and collaborate with backend developers
        - Participate in Agile ceremonies and Scrum sprints

        Requirements:
        - Strong knowledge of Flutter and Dart
        - Experience with REST APIs and Git
        - Bachelor's degree in Computer Science or related field
        - 1+ years of experience in mobile development

        Preferred:
        - Experience with Firebase
        - Familiarity with Clean Architecture
        """
        analysis = self.analyzer.analyze(jd_text, job_title="Junior Flutter Developer", company="TechNova")

        self.assertEqual(analysis["job_title"], "Junior Flutter Developer")
        self.assertEqual(analysis["seniority"], "Junior")
        self.assertIn("Flutter", analysis["required_skills"])
        self.assertIn("Dart", analysis["required_skills"])
        self.assertIn("REST APIs", analysis["required_skills"])
        self.assertIn("Git", analysis["required_skills"])
        self.assertIn("Firebase", analysis["preferred_skills"])

        # Check requirements list structure
        requirements = analysis["requirements"]
        self.assertTrue(len(requirements) > 0)
        flutter_req = next((r for r in requirements if r["normalized_name"] == "Flutter"), None)
        self.assertIsNotNone(flutter_req)
        self.assertEqual(flutter_req["importance"], "REQUIRED")
        self.assertEqual(flutter_req["category"], "TECHNICAL_SKILL")

        firebase_req = next((r for r in requirements if r["normalized_name"] == "Firebase"), None)
        self.assertIsNotNone(firebase_req)
        self.assertEqual(firebase_req["importance"], "PREFERRED")

    def test_analyze_backend_django_jd(self):
        jd_text = """
        We are seeking a Senior Backend Engineer to build robust Python services.

        What you need:
        - Expert in Python and Django REST Framework
        - PostgreSQL and Redis experience
        - Docker and CI/CD pipelines
        - 5+ years of experience in backend development
        """
        analysis = self.analyzer.analyze(jd_text)
        self.assertEqual(analysis["seniority"], "Senior")
        self.assertIn("Python", analysis["required_skills"])
        self.assertIn("Django REST Framework", analysis["required_skills"])
        self.assertIn("PostgreSQL", analysis["technologies"])

    def test_empty_or_short_jd_graceful_handling(self):
        analysis = self.analyzer.analyze("Short JD")
        self.assertIn("job_title", analysis)
        self.assertIsInstance(analysis["requirements"], list)

    def test_unknown_title_and_seniority_are_not_invented(self):
        analysis = self.analyzer.analyze("Experience with Flutter and Dart is required.")
        self.assertIsNone(analysis["job_title"])
        self.assertIsNone(analysis["seniority"])
