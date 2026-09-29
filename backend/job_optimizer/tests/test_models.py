from datetime import timedelta

from django.contrib.auth import get_user_model
from django.core.cache import cache
from django.core.management import call_command
from django.core.management.base import CommandError
from django.test import TestCase
from django.utils import timezone

from job_optimizer.models import JobDescription, OptimizationSession, OptimizationSuggestion
from resume.models import Resume

User = get_user_model()


class JobOptimizerModelsTest(TestCase):
    def setUp(self):
        self.user = User.objects.create_user(
            email="developer@example.com",
            password="securePassword123!",
            name="Alex Developer",
        )
        self.resume = Resume.objects.create(
            user=self.user,
            title="Master Resume",
            data={
                "basics": {"name": "Alex Developer", "label": "Flutter Developer"},
                "skills": [{"name": "Mobile", "keywords": ["Flutter", "Dart"]}],
            },
        )

    def test_create_job_description(self):
        jd = JobDescription.objects.create(
            user=self.user,
            title="Flutter Engineer",
            company="Acme Corp",
            description="Looking for an experienced Flutter engineer with Dart knowledge.",
        )
        self.assertIsNotNone(jd.id)
        self.assertEqual(jd.user, self.user)
        self.assertEqual(str(jd), "Flutter Engineer at Acme Corp (developer@example.com)")

    def test_create_optimization_session(self):
        jd = JobDescription.objects.create(
            user=self.user,
            title="Flutter Engineer",
            description="We need Flutter and Dart developers.",
        )
        session = OptimizationSession.objects.create(
            user=self.user,
            source_resume=self.resume,
            source_resume_version=1,
            job_description=jd,
        )
        self.assertEqual(session.status, OptimizationSession.Status.DRAFT)
        self.assertEqual(session.source_resume, self.resume)
        self.assertIn("DRAFT", str(session))

    def test_create_optimization_suggestion(self):
        jd = JobDescription.objects.create(
            user=self.user,
            title="Flutter Engineer",
            description="We need Flutter developers.",
        )
        session = OptimizationSession.objects.create(
            user=self.user,
            source_resume=self.resume,
            job_description=jd,
        )
        suggestion = OptimizationSuggestion.objects.create(
            optimization_session=session,
            suggestion_type=OptimizationSuggestion.SuggestionType.SUMMARY_REWRITE,
            resume_path="basics.summary",
            original_value="Experienced mobile engineer.",
            ai_suggestion="Experienced Flutter mobile engineer.",
            reason="Aligns with Flutter requirement in JD.",
            keywords=["Flutter"],
        )
        self.assertEqual(suggestion.status, OptimizationSuggestion.Status.PENDING)
        self.assertEqual(suggestion.optimization_session, session)

    def test_monitor_marks_stuck_session_failed_and_alerts_once(self):
        cache.clear()
        jd = JobDescription.objects.create(
            user=self.user,
            title="Flutter Engineer",
            description="We need Flutter developers.",
        )
        session = OptimizationSession.objects.create(
            user=self.user,
            source_resume=self.resume,
            job_description=jd,
            status=OptimizationSession.Status.ANALYZING,
        )
        OptimizationSession.objects.filter(pk=session.pk).update(
            updated_at=timezone.now() - timedelta(hours=2)
        )

        with self.assertRaises(CommandError):
            call_command(
                "monitor_optimization_sessions",
                stale_minutes=30,
                failure_lookback_minutes=20,
                apply=True,
            )

        session.refresh_from_db()
        self.assertEqual(session.status, OptimizationSession.Status.FAILED)
        self.assertEqual(session.failure_code, "operation_timed_out")
        call_command(
            "monitor_optimization_sessions",
            stale_minutes=30,
            failure_lookback_minutes=20,
            apply=True,
        )
