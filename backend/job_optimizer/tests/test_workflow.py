from copy import deepcopy
from unittest.mock import Mock, patch

from django.contrib.auth import get_user_model
from django.core.cache import cache
from django.test import SimpleTestCase, TestCase, override_settings
from rest_framework.test import APIClient

from ai.models import AICreditAccount, AICreditTransaction, AIUsage
from ai.services.exceptions import AIServiceTimeoutError
from ai.services.credits import CreditService
from ai.services.openrouter import AIResult, OpenRouterProvider
from job_optimizer.models import JobDescription, OptimizationSession, OptimizationSuggestion
from job_optimizer.services.suggestions import SuggestionValidator
from resume.models import Resume, ResumeTemplate, ResumeVersion
from exports.services.pdf_validation import PDFValidationError, validate_optimized_pdf


class SuggestionValidationTest(SimpleTestCase):
    def setUp(self):
        self.resume = {"projects": [{"highlights": ["Built Flutter app with Dio."]}]}
        self.candidate = {
            "resume_path": "projects[0].highlights[0]",
            "original_value": "Built Flutter app with Dio.",
            "evidence_paths": ["projects[0].highlights[0]"],
            "evidence_texts": ["Built Flutter app with Dio."],
        }
        self.proposal = {
            "should_suggest": True, "suggestion_type": "PROJECT_BULLET_IMPROVEMENT",
            "resume_path": "projects[0].highlights[0]",
            "original_value": "Built Flutter app with Dio.",
            "suggested_value": "Built a Flutter app using Dio.",
            "reason": "Clarifies the documented work.",
            "keywords": ["Flutter"],
            "evidence_paths": ["projects[0].highlights[0]"],
        }

    def test_valid_and_rejects_unsupported_claims(self):
        validator = SuggestionValidator()
        self.assertEqual(validator.validate(self.proposal, candidate=self.candidate, resume_data=self.resume)["resume_path"],
                         "projects[0].highlights[0]")
        for value in ("Built Flutter app and increased performance by 40%.",
                      "Built Flutter app with AWS.", "Led a team building Flutter app."):
            with self.subTest(value=value), self.assertRaises(Exception):
                validator.validate({**self.proposal, "suggested_value": value},
                                   candidate=self.candidate, resume_data=self.resume)

    def test_rejects_invalid_path_and_evidence(self):
        for patch_data in ({"resume_path": "projects[1].highlights[0]"},
                           {"evidence_paths": ["work[0].summary"]},
                           {"original_value": "Other text"}):
            with self.subTest(patch_data=patch_data), self.assertRaises(Exception):
                SuggestionValidator().validate({**self.proposal, **patch_data},
                                               candidate=self.candidate, resume_data=self.resume)


class OptimizedPDFValidationTest(SimpleTestCase):
    def test_requires_pages_identity_and_applied_content(self):
        import fitz

        document = fitz.open()
        page = document.new_page()
        page.insert_text((72, 72), "Alex Developer\nBuilt a Flutter app using Dio.")
        pdf = document.tobytes()
        document.close()
        version = Mock(data={"basics": {"name": "Alex Developer"}})
        result = validate_optimized_pdf(
            pdf,
            version=version,
            applied_values=["Built a Flutter app using Dio."],
        )
        self.assertEqual(result.page_count, 1)
        with self.assertRaises(PDFValidationError):
            validate_optimized_pdf(pdf, version=version, applied_values=["Missing accepted text"])


@override_settings(OPENROUTER_API_KEY="test-key", OPENROUTER_MODEL_NAME="test/model")
class OpenRouterProviderTest(SimpleTestCase):
    @patch("ai.services.openrouter.requests.post")
    def test_success_and_usage(self, post):
        post.return_value.status_code = 200
        post.return_value.json.return_value = {
            "id": "req-1", "model": "test/model",
            "choices": [{"message": {"content": '{"suggestions": []}'}}],
            "usage": {"prompt_tokens": 12, "completion_tokens": 3, "total_tokens": 15},
        }
        result = OpenRouterProvider().generate([{"role": "user", "content": "test"}])
        self.assertEqual(result.total_tokens, 15)
        self.assertEqual(result.content, {"suggestions": []})

    @patch("ai.services.openrouter.requests.post")
    def test_timeout(self, post):
        import requests
        post.side_effect = requests.Timeout()
        with self.assertRaises(AIServiceTimeoutError):
            OpenRouterProvider().generate([{"role": "user", "content": "test"}])

    @patch("ai.services.openrouter.requests.post")
    def test_authentication_failure_and_invalid_json(self, post):
        post.return_value.status_code = 401
        with self.assertRaises(Exception):
            OpenRouterProvider().generate([{"role": "user", "content": "test"}])
        post.return_value.status_code = 200
        post.return_value.json.return_value = {"choices": [{"message": {"content": "not json"}}]}
        with self.assertRaises(Exception):
            OpenRouterProvider().generate([{"role": "user", "content": "test"}])


class OptimizationWorkflowTest(TestCase):
    def setUp(self):
        cache.clear()
        user_model = get_user_model()
        self.user = user_model.objects.create_user(email="optimizer@example.com", password="TestPass123!", name="Optimizer")
        self.other = user_model.objects.create_user(email="otheropt@example.com", password="TestPass123!", name="Other")
        self.master_data = {"basics": {"summary": "Flutter developer."},
                            "projects": [{"highlights": ["Built Flutter app with Dio."]}]}
        self.resume = Resume.objects.create(user=self.user, title="Master", data=deepcopy(self.master_data))
        self.jd = JobDescription.objects.create(user=self.user, description="Flutter and Dio experience required.")
        self.session = OptimizationSession.objects.create(
            user=self.user, source_resume=self.resume, job_description=self.jd,
            source_data_snapshot=deepcopy(self.master_data), status=OptimizationSession.Status.READY_FOR_REVIEW,
            analysis_json={"requirements": [{"id": "r1", "name": "Flutter", "importance": "REQUIRED", "category": "TECHNICAL_SKILL"}]},
            match_results_json={"summary": {"alignment_score": 50}, "results": [{
                "id": "r1", "name": "Flutter", "status": "MATCHED",
                "evidence": [{"path": "projects[0].highlights[0]", "text": "Built Flutter app with Dio."}],
            }]},
        )
        self.account = AICreditAccount.objects.create(user=self.user, balance=20)
        self.client = APIClient()
        self.client.force_authenticate(user=self.user)
        self.root = "/api/v1/job-optimizer/"

    def _ai_result(self, value="Built a Flutter app using Dio."):
        return AIResult(content={"suggestions": [{
            "should_suggest": True, "suggestion_type": "PROJECT_BULLET_IMPROVEMENT",
            "resume_path": "projects[0].highlights[0]", "original_value": "Built Flutter app with Dio.",
            "suggested_value": value, "reason": "Clearer wording.", "keywords": ["Flutter"],
            "evidence_paths": ["projects[0].highlights[0]"],
        }]}, model="test/model", input_tokens=20, output_tokens=15,
            total_tokens=35, request_id="test-request", latency_ms=30)

    @patch("ai.services.openrouter.AIService.generate_json")
    def test_generation_review_finalize_preserves_master(self, generate):
        generate.return_value = self._ai_result()
        path = f"{self.root}sessions/{self.session.pk}/suggestions/generate/"
        response = self.client.post(path)
        self.assertEqual(response.status_code, 200)
        self.assertEqual(len(response.data), 1)
        self.assertEqual(self.client.post(path).status_code, 200)
        self.assertEqual(AIUsage.objects.count(), 1)
        self.account.refresh_from_db()
        self.assertEqual(self.account.balance, 10)
        suggestion_id = response.data[0]["id"]
        accepted = self.client.post(f"{self.root}suggestions/{suggestion_id}/accept/")
        self.assertEqual(accepted.status_code, 200)
        self.assertEqual(self.client.post(f"{self.root}suggestions/{suggestion_id}/reject/").status_code, 200)
        self.assertEqual(self.client.post(f"{self.root}suggestions/{suggestion_id}/accept/").status_code, 200)
        finalized = self.client.post(f"{self.root}sessions/{self.session.pk}/finalize/")
        self.assertEqual(finalized.status_code, 200)
        version = ResumeVersion.objects.get(id=finalized.data["resume_version_id"])
        self.assertEqual(version.data["projects"][0]["highlights"][0], "Built a Flutter app using Dio.")
        self.resume.refresh_from_db()
        self.assertEqual(self.resume.data, self.master_data)
        self.assertEqual(self.client.post(f"{self.root}sessions/{self.session.pk}/finalize/").status_code, 200)
        self.assertEqual(ResumeVersion.objects.count(), 1)

    @patch("ai.services.openrouter.AIService.generate_json")
    def test_invalid_ai_output_releases_credit(self, generate):
        generate.return_value = self._ai_result("Built Flutter app with AWS and 40% growth.")
        response = self.client.post(f"{self.root}sessions/{self.session.pk}/suggestions/generate/")
        self.assertEqual(response.status_code, 422)
        self.account.refresh_from_db()
        self.assertEqual((self.account.balance, self.account.reserved_credits), (20, 0))
        self.assertEqual(OptimizationSuggestion.objects.count(), 0)

    def test_manual_edit_is_free_and_ownership_enforced(self):
        suggestion = OptimizationSuggestion.objects.create(
            optimization_session=self.session, suggestion_type="PROJECT_BULLET_IMPROVEMENT",
            resume_path="projects[0].highlights[0]", original_value="Built Flutter app with Dio.",
            ai_suggestion="Built a Flutter app using Dio.",
        )
        self.client.force_authenticate(user=self.other)
        self.assertEqual(self.client.post(f"{self.root}suggestions/{suggestion.pk}/accept/").status_code, 404)
        self.client.force_authenticate(user=self.user)
        edited = self.client.post(f"{self.root}suggestions/{suggestion.pk}/edit/",
                                  {"value": "Built Flutter app with Dio and REST APIs."})
        self.assertEqual(edited.status_code, 200)
        self.assertEqual(edited.data["status"], "EDITED")
        self.account.refresh_from_db()
        self.assertEqual(self.account.balance, 20)
        self.assertEqual(AICreditTransaction.objects.count(), 0)

    def test_reviewed_suggestion_can_be_revised_before_finalization(self):
        suggestion = OptimizationSuggestion.objects.create(
            optimization_session=self.session, suggestion_type="PROJECT_BULLET_IMPROVEMENT",
            resume_path="projects[0].highlights[0]", original_value="Built Flutter app with Dio.",
            ai_suggestion="Built a Flutter app using Dio.",
        )
        root = f"{self.root}suggestions/{suggestion.pk}"

        accepted = self.client.post(f"{root}/accept/")
        self.assertEqual(accepted.status_code, 200)
        edited = self.client.post(
            f"{root}/edit/", {"value": "Developed a Flutter app using Dio."}
        )
        self.assertEqual(edited.status_code, 200)
        self.assertEqual(edited.data["status"], "EDITED")
        self.assertEqual(edited.data["final_value"], "Developed a Flutter app using Dio.")

        rejected = self.client.post(f"{root}/reject/")
        self.assertEqual(rejected.status_code, 200)
        self.assertEqual(rejected.data["status"], "REJECTED")
        restored = self.client.post(f"{root}/accept/")
        self.assertEqual(restored.status_code, 200)
        self.assertEqual(restored.data["final_value"], "Built a Flutter app using Dio.")

    @patch("ai.services.openrouter.AIService.generate_json")
    def test_regeneration_uses_one_credit_and_keeps_revision(self, generate):
        suggestion = OptimizationSuggestion.objects.create(
            optimization_session=self.session, suggestion_type="PROJECT_BULLET_IMPROVEMENT",
            resume_path="projects[0].highlights[0]", original_value="Built Flutter app with Dio.",
            ai_suggestion="Built a Flutter app using Dio.",
            evidence_reference=["projects[0].highlights[0]"],
        )
        generate.return_value = self._ai_result("Developed a Flutter app with Dio.")
        path = f"{self.root}suggestions/{suggestion.pk}/regenerate/"
        response = self.client.post(path, {"instruction": "Make concise"}, HTTP_IDEMPOTENCY_KEY="regen-test-123")
        self.assertEqual(response.status_code, 200)
        self.assertEqual(len(response.data["revision_history"]), 1)
        self.assertEqual(self.client.post(path, {"instruction": "Make concise"}, HTTP_IDEMPOTENCY_KEY="regen-test-123").status_code, 200)
        self.account.refresh_from_db()
        self.assertEqual(self.account.balance, 19)

    def test_credit_api_and_insufficient_balance(self):
        self.account.balance = 0
        self.account.save()
        response = self.client.get("/api/v1/ai/credits/")
        self.assertEqual(response.data["available_credits"], 0)
        response = self.client.post(f"{self.root}sessions/{self.session.pk}/suggestions/generate/")
        self.assertEqual(response.status_code, 402)

    @patch("ai.services.openrouter.AIService.generate_json")
    def test_provider_timeout_releases_reservation(self, generate):
        generate.side_effect = AIServiceTimeoutError("timed out")
        response = self.client.post(f"{self.root}sessions/{self.session.pk}/suggestions/generate/")
        self.assertEqual(response.status_code, 503)
        self.account.refresh_from_db()
        self.assertEqual((self.account.balance, self.account.reserved_credits), (20, 0))
        self.assertEqual(AIUsage.objects.get().status, AIUsage.Status.FAILED)

    def test_credit_reservation_is_idempotent(self):
        first, created = CreditService.reserve(
            user=self.user, operation="suggestion_regeneration",
            idempotency_key="credit-test-123", reference_id=self.session.pk,
        )
        second, again = CreditService.reserve(
            user=self.user, operation="suggestion_regeneration",
            idempotency_key="credit-test-123", reference_id=self.session.pk,
        )
        self.assertTrue(created)
        self.assertFalse(again)
        self.assertEqual(first.pk, second.pk)
        self.account.refresh_from_db()
        self.assertEqual(self.account.reserved_credits, 1)
        CreditService.release(first)
        self.account.refresh_from_db()
        self.assertEqual(self.account.available, 20)

    def test_successful_usage_can_be_refunded_once(self):
        self.assertTrue(CreditService.check_balance(self.user, "suggestion_regeneration"))
        usage, _ = CreditService.reserve(
            user=self.user, operation="suggestion_regeneration",
            idempotency_key="refund-test-123", reference_id=self.session.pk,
        )
        CreditService.commit(usage, self._ai_result())
        self.account.refresh_from_db()
        self.assertEqual(self.account.balance, 19)
        CreditService.refund(usage)
        CreditService.refund(usage)
        self.account.refresh_from_db()
        self.assertEqual(self.account.balance, 20)
        self.assertEqual(AICreditTransaction.objects.filter(
            transaction_type=AICreditTransaction.Type.REFUND
        ).count(), 1)

    @patch("ai.services.openrouter.AIService.generate_json")
    def test_version_pdf_uses_snapshot_not_master(self, generate):
        from tempfile import TemporaryDirectory
        generate.return_value = self._ai_result()
        response = self.client.post(f"{self.root}sessions/{self.session.pk}/suggestions/generate/")
        self.client.post(f"{self.root}suggestions/{response.data[0]['id']}/accept/")
        finalized = self.client.post(f"{self.root}sessions/{self.session.pk}/finalize/")
        version = ResumeVersion.objects.get(pk=finalized.data["resume_version_id"])
        template = ResumeTemplate.objects.bulk_create([
            ResumeTemplate(name="Test", slug="optimizer-test", html_structure="<p>Resume</p>")
        ])[0]
        version.template = template
        version.save(update_fields=["template"])
        with TemporaryDirectory() as media_root, override_settings(MEDIA_ROOT=media_root), \
             patch("job_optimizer.workflow_views.ResumeRenderService.render_resume", return_value="<p>Optimized</p>") as render, \
             patch("job_optimizer.workflow_views.validate_optimized_pdf"), \
             patch("weasyprint.HTML") as html:
            html.return_value.write_pdf.return_value = b"%PDF-1.4 optimized"
            pdf = self.client.get(f"{self.root}versions/{version.pk}/pdf/")
            self.assertEqual(pdf.status_code, 200)
            self.assertEqual(pdf.content, b"%PDF-1.4 optimized")
            self.assertEqual(render.call_args.args[0], version.data)
        self.resume.refresh_from_db()
        self.assertEqual(self.resume.data, self.master_data)

    def test_missing_skill_never_generates_or_charges(self):
        self.session.match_results_json = {"results": [{
            "name": "AWS", "status": "MISSING", "evidence": [],
        }]}
        self.session.save(update_fields=["match_results_json"])
        response = self.client.post(f"{self.root}sessions/{self.session.pk}/suggestions/generate/")
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.data, [])
        self.assertFalse(AIUsage.objects.exists())

    def test_mixed_review_changes_only_approved_snapshot_fields(self):
        source = {"projects": [{"highlights": [
            "Built Flutter app with Dio.", "Integrated REST API with Dio.",
            "Created Dart UI widgets.",
        ]}]}
        self.resume.data = deepcopy(source)
        self.resume.save(update_fields=["data"])
        self.session.source_data_snapshot = deepcopy(source)
        self.session.save(update_fields=["source_data_snapshot"])
        proposals = [
            (0, "Built a Flutter app using Dio."),
            (1, "Integrated a REST API with Dio."),
            (2, "Developed Dart UI widgets."),
        ]
        ids = []
        for index, value in proposals:
            item = OptimizationSuggestion.objects.create(
                optimization_session=self.session,
                suggestion_type="PROJECT_BULLET_IMPROVEMENT",
                resume_path=f"projects[0].highlights[{index}]",
                original_value=source["projects"][0]["highlights"][index],
                ai_suggestion=value,
            )
            ids.append(item.pk)
        self.assertEqual(self.client.post(f"{self.root}suggestions/{ids[0]}/accept/").status_code, 200)
        self.assertEqual(self.client.post(f"{self.root}suggestions/{ids[1]}/reject/").status_code, 200)
        self.assertEqual(self.client.post(f"{self.root}suggestions/{ids[2]}/edit/",
                                          {"value": "Created Dart UI components."}).status_code, 200)
        result = self.client.post(f"{self.root}sessions/{self.session.pk}/finalize/")
        self.assertEqual(result.status_code, 200)
        version = ResumeVersion.objects.get(pk=result.data["resume_version_id"])
        self.assertEqual(version.data["projects"][0]["highlights"], [
            "Built a Flutter app using Dio.",
            "Integrated REST API with Dio.",
            "Created Dart UI components.",
        ])
        self.resume.refresh_from_db()
        self.assertEqual(self.resume.data, source)

    def test_invalid_approved_path_cannot_finalize(self):
        OptimizationSuggestion.objects.create(
            optimization_session=self.session, suggestion_type="PROJECT_BULLET_IMPROVEMENT",
            resume_path="projects[99].highlights[0]", original_value="Other",
            ai_suggestion="Changed", final_value="Changed",
            status=OptimizationSuggestion.Status.ACCEPTED,
        )
        response = self.client.post(f"{self.root}sessions/{self.session.pk}/finalize/")
        self.assertEqual(response.status_code, 400)
        self.assertFalse(ResumeVersion.objects.exists())

    def test_suggestion_patch_uses_optimistic_concurrency_and_bulk_is_atomic(self):
        first = OptimizationSuggestion.objects.create(
            optimization_session=self.session,
            suggestion_type="PROJECT_BULLET_IMPROVEMENT",
            resume_path="projects[0].highlights[0]",
            original_value="Built Flutter app with Dio.",
            ai_suggestion="Built a Flutter app using Dio.",
        )
        url = f"{self.root}sessions/{self.session.pk}/suggestions/{first.pk}/"
        accepted = self.client.patch(url, {"status": "accepted", "decision_version": 1}, format="json")
        self.assertEqual(accepted.status_code, 200)
        self.assertEqual(accepted.data["decision_version"], 2)
        stale = self.client.patch(url, {"status": "rejected", "decision_version": 1}, format="json")
        self.assertEqual(stale.status_code, 400)
        first.refresh_from_db()
        self.assertEqual(first.status, OptimizationSuggestion.Status.ACCEPTED)

        bulk = self.client.patch(
            f"{self.root}sessions/{self.session.pk}/suggestions/",
            {"updates": [
                {"id": str(first.pk), "status": "rejected", "decision_version": 2},
                {"id": "00000000-0000-0000-0000-000000000001", "status": "accepted"},
            ]},
            format="json",
        )
        self.assertEqual(bulk.status_code, 400)
        first.refresh_from_db()
        self.assertEqual(first.status, OptimizationSuggestion.Status.ACCEPTED)

    def test_apply_idempotency_and_source_conflict(self):
        suggestion = OptimizationSuggestion.objects.create(
            optimization_session=self.session,
            suggestion_type="PROJECT_BULLET_IMPROVEMENT",
            resume_path="projects[0].highlights[0]",
            original_value="Built Flutter app with Dio.",
            ai_suggestion="Built a Flutter app using Dio.",
            final_value="Built a Flutter app using Dio.",
            status=OptimizationSuggestion.Status.ACCEPTED,
        )
        apply_url = f"{self.root}sessions/{self.session.pk}/apply/"
        payload = {"idempotency_key": "apply-same-123", "expected_source_version": 1}
        first = self.client.post(apply_url, payload, format="json")
        second = self.client.post(apply_url, payload, format="json")
        self.assertEqual((first.status_code, second.status_code), (200, 200))
        self.assertEqual(first.data["resume_version_id"], second.data["resume_version_id"])
        self.assertEqual(ResumeVersion.objects.count(), 1)
        suggestion.refresh_from_db()
        self.assertEqual(suggestion.status, OptimizationSuggestion.Status.APPLIED)

        other_session = OptimizationSession.objects.create(
            user=self.user, source_resume=self.resume, job_description=self.jd,
            source_data_snapshot=deepcopy(self.resume.data),
            status=OptimizationSession.Status.READY_FOR_REVIEW,
        )
        OptimizationSuggestion.objects.create(
            optimization_session=other_session,
            suggestion_type="PROJECT_BULLET_IMPROVEMENT",
            resume_path="projects[0].highlights[0]",
            original_value="Built Flutter app with Dio.",
            ai_suggestion="Built a Flutter app using Dio.",
            final_value="Built a Flutter app using Dio.",
            status=OptimizationSuggestion.Status.ACCEPTED,
        )
        self.resume.data["projects"][0]["highlights"][0] = "Changed after analysis."
        self.resume.save(update_fields=["data"])
        conflict = self.client.post(
            f"{self.root}sessions/{other_session.pk}/apply/",
            {"idempotency_key": "apply-conflict-123", "expected_source_version": 1},
            format="json",
        )
        self.assertEqual(conflict.status_code, 400)
        self.assertEqual(ResumeVersion.objects.count(), 1)

    def test_contract_creation_entitlements_and_request_idempotency(self):
        payload = {
            "resume_id": str(self.resume.pk),
            "job_description": "Build Flutter applications using Dio and REST APIs.",
            "job_title": "Flutter Developer",
            "company_name": "Example",
            "optimization_mode": "balanced",
            "idempotency_key": "analysis-request-123",
        }
        first = self.client.post("/api/v1/resume-optimizations/", payload, format="json")
        second = self.client.post("/api/v1/resume-optimizations/", payload, format="json")
        self.assertEqual((first.status_code, second.status_code), (201, 200))
        self.assertEqual(first.data["id"], second.data["id"])
        entitlements = self.client.get("/api/v1/billing/entitlements/")
        self.assertEqual(entitlements.status_code, 200)
        self.assertEqual(entitlements.data["ai_credits"]["available"], 20)
