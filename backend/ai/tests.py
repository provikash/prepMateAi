import uuid
from unittest.mock import Mock, patch

from django.contrib.auth import get_user_model
from django.test import SimpleTestCase, TestCase, override_settings
from django.urls import reverse
from rest_framework.test import APITestCase

from .models import AICreditAccount, AICreditTransaction
from .services.credits import CreditService, InvalidCreditAdjustment
from .services.openrouter import AIResult, AIService
from .services.resume_service import ResumeAIService


class ResumeAIServiceTests(SimpleTestCase):
    def test_generate_summary_parses_openrouter_result(self):
        mock_provider = Mock()
        mock_provider.generate.return_value = AIResult(
            content={"summary": "Experienced engineer."},
            model="openai/gpt-4o-mini",
            input_tokens=10,
            output_tokens=5,
            total_tokens=15,
            request_id="req-1",
            latency_ms=100,
        )
        service = ResumeAIService(ai_service=AIService(provider=mock_provider))
        result = service.generate_summary({"basics": {"name": "Test"}})
        self.assertEqual(result, {"summary": "Experienced engineer."})

    def test_suggest_skills_cleans_list(self):
        mock_provider = Mock()
        mock_provider.generate.return_value = AIResult(
            content={"skills": [" Python ", "Django", "", 123]},
            model="openai/gpt-4o-mini",
            input_tokens=10,
            output_tokens=5,
            total_tokens=15,
            request_id="req-2",
            latency_ms=100,
        )
        service = ResumeAIService(ai_service=AIService(provider=mock_provider))
        result = service.suggest_skills("Backend Developer")
        self.assertEqual(result, {"skills": ["Python", "Django"]})


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


@override_settings(
    STORAGES={
        "default": {"BACKEND": "django.core.files.storage.FileSystemStorage"},
        "staticfiles": {
            "BACKEND": "django.contrib.staticfiles.storage.StaticFilesStorage"
        },
    }
)
class CreditAdministrationTests(TestCase):
    def setUp(self):
        user_model = get_user_model()
        self.staff = user_model.objects.create_superuser(
            username="credit-admin",
            email="credit-admin@example.com",
            password="StrongAdminPassword123!",
        )
        self.user = user_model.objects.create_mobile_user("+919876543210")
        self.account = AICreditAccount.objects.get(user=self.user)

    def test_every_new_user_has_a_credit_account(self):
        self.assertEqual(self.account.balance, 0)
        self.assertEqual(self.account.available, 0)

    def test_adjustment_updates_balance_and_writes_staff_audit_entry(self):
        account, entry, created = CreditService.adjust(
            account=self.account,
            delta=25,
            reason="Customer support goodwill credit",
            performed_by=self.staff,
            idempotency_key="support-case-123",
        )
        self.assertTrue(created)
        self.assertEqual(account.balance, 25)
        self.assertEqual(account.lifetime_earned, 25)
        self.assertEqual(entry.transaction_type, AICreditTransaction.Type.GRANT)
        self.assertEqual(entry.performed_by, self.staff)
        self.assertEqual(entry.balance_before, 0)
        self.assertEqual(entry.balance_after, 25)

        account, duplicate, created = CreditService.adjust(
            account=self.account,
            delta=25,
            reason="Customer support goodwill credit",
            performed_by=self.staff,
            idempotency_key="support-case-123",
        )
        self.assertFalse(created)
        self.assertEqual(duplicate.pk, entry.pk)
        self.assertEqual(account.balance, 25)

    def test_deduction_cannot_consume_reserved_credits(self):
        self.account.balance = 20
        self.account.reserved_credits = 8
        self.account.save(update_fields=["balance", "reserved_credits"])
        with self.assertRaises(InvalidCreditAdjustment):
            CreditService.adjust(
                account=self.account,
                delta=-13,
                reason="Invalid correction",
                performed_by=self.staff,
            )
        self.account.refresh_from_db()
        self.assertEqual(self.account.balance, 20)
        self.assertFalse(
            AICreditTransaction.objects.filter(operation="admin_adjustment").exists()
        )

    def test_admin_can_adjust_but_cannot_directly_edit_or_delete_ledger(self):
        self.client.force_login(self.staff)
        response = self.client.post(
            reverse("admin:ai_aicreditaccount_change", args=[self.account.pk]),
            {
                "adjustment": "40",
                "reason": "Manual launch allocation",
                "adjustment_id": str(uuid.uuid4()),
                "_save": "Save",
            },
        )
        self.assertEqual(response.status_code, 302, response.context)
        self.account.refresh_from_db()
        self.assertEqual(self.account.balance, 40)
        entry = AICreditTransaction.objects.get(operation="admin_adjustment")
        self.assertEqual(entry.performed_by, self.staff)
        self.assertEqual(entry.description, "Manual launch allocation")

        users = self.client.get(reverse("admin:users_user_changelist"))
        self.assertEqual(users.status_code, 200)
        self.assertContains(users, "40 available")

        transaction_url = reverse(
            "admin:ai_aicredittransaction_change", args=[entry.pk]
        )
        detail = self.client.get(transaction_url)
        self.assertEqual(detail.status_code, 200)
        delete = self.client.get(
            reverse("admin:ai_aicredittransaction_delete", args=[entry.pk])
        )
        self.assertEqual(delete.status_code, 403)
