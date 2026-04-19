from django.contrib.auth import get_user_model
from django.test import TestCase
from django.template import Context, Template

from resume.models import ResumeTemplate
from resume.rendering import ResumeRenderService
from resume.serializers import ResumeSerializer
from resume.services import ResumeValidationService


class ResumeSerializerValidationTests(TestCase):
    def setUp(self):
        self.user = get_user_model().objects.create_user(
            email="test@example.com",
            password="password123",
            name="Test User",
        )
        self.template = ResumeTemplate.objects.create(
            name="Modern",
            html_structure="""
                <h1>{{ resume.personal_info.name }}</h1>
                <p>{{ resume.personal_info.email }}</p>
                <p>{{ resume.personal_info.phone }}</p>
                {% for item in resume.experience %}{{ item.role }}{% endfor %}
            """,
            is_active=True,
        )
        self.valid_data = {
            "personal_info": {
                "name": "Alice",
                "email": "alice@example.com",
                "phone": "1234567890",
            },
            "education": [],
            "experience": [],
            "skills": [],
            "projects": [],
        }

    def test_template_is_required_when_creating_resume(self):
        serializer = ResumeSerializer(
            data={
                "title": "My Resume",
                "data": self.valid_data,
            }
        )

        self.assertFalse(serializer.is_valid())
        self.assertIn("template", serializer.errors)

    def test_resume_data_must_follow_selected_template_structure(self):
        invalid_data = {
            "personal_info": {
                "name": "Alice",
                "phone": "1234567890",
            },
            "education": [],
            "experience": [],
            "skills": [],
            "projects": [],
        }
        serializer = ResumeSerializer(
            data={
                "title": "My Resume",
                "template": self.template.id,
                "data": invalid_data,
            }
        )

        self.assertFalse(serializer.is_valid())
        self.assertIn("data", serializer.errors)

    def test_resume_creation_is_valid_when_template_and_data_match(self):
        serializer = ResumeSerializer(
            data={
                "title": "My Resume",
                "template": self.template.id,
                "data": self.valid_data,
            }
        )

        self.assertTrue(serializer.is_valid(), serializer.errors)

    def test_resume_creation_accepts_skill_groups_instead_of_skills(self):
        payload = {
            "title": "My Resume",
            "template": self.template.id,
            "data": {
                "personal_info": {
                    "name": "Alice",
                    "email": "alice@example.com",
                    "phone": "1234567890",
                },
                "skill_groups": {
                    "programming_languages": "Dart, JavaScript",
                    "mobile_framework": "Flutter",
                    "architecture": "BLoC",
                    "ui_ux": "Responsive Design",
                    "tools": "Firebase, Git",
                },
                "education": [],
                "experience": [],
                "projects": [],
            },
        }

        serializer = ResumeSerializer(data=payload)

        self.assertTrue(serializer.is_valid(), serializer.errors)
        self.assertIn("skills", serializer.validated_data["data"])
        self.assertGreater(len(serializer.validated_data["data"]["skills"]), 0)


class ResumeNormalizationAndRenderTests(TestCase):
    def test_normalization_stringifies_skill_groups_and_backfills_profile_urls(self):
        normalized = ResumeValidationService.normalize_resume_data(
            {
                "personal_info": {
                    "name": "Vikash",
                    "email": "v@example.com",
                    "phone": "12345",
                    "linkedin": "https://linkedin.com/in/vikash",
                    "github": "https://github.com/vikash",
                },
                "skill_groups": {
                    "programming_languages": ["Dart", "Java"],
                    "mobile_framework": ["Flutter"],
                },
                "education": [],
                "experience": [],
                "projects": [],
            }
        )

        self.assertEqual(normalized["skill_groups"]["programming_languages"], "Dart, Java")
        self.assertEqual(normalized["skill_groups"]["mobile_framework"], "Flutter")
        self.assertEqual(
            normalized["personal_info"]["linkedin_url"],
            "https://linkedin.com/in/vikash",
        )
        self.assertEqual(
            normalized["personal_info"]["github_url"],
            "https://github.com/vikash",
        )

    def test_render_fallbacks_for_project_description_and_certification_punctuation(self):
        html = """
        {% for project in resume.projects %}
            {% if project.bullets %}
                {% for bullet in project.bullets %}{{ bullet }}{% endfor %}
            {% elif project.description %}
                {{ project.description }}
            {% endif %}
        {% endfor %}

        {% for cert in resume.certifications %}
            {{ cert.title }}{% if cert.description %}: {{ cert.description }}{% endif %}
        {% endfor %}
        """

        normalized = ResumeValidationService.normalize_resume_data(
            {
                "personal_info": {"name": "Vikash", "email": "v@example.com", "phone": "12345"},
                "education": [],
                "experience": [],
                "skills": [],
                "projects": [
                    {
                        "title": "PrepMate",
                        "description": "Resume builder app",
                    }
                ],
                "certifications": [
                    {"title": "AI Internship", "description": ""},
                ],
            }
        )

        rendered = Template(html).render(Context({"resume": normalized}))

        self.assertIn("Resume builder app", rendered)
        self.assertIn("AI Internship", rendered)
        self.assertNotIn("AI Internship:", rendered)

    def test_render_service_builds_section_flags_and_filters_empty_section_items(self):
        prepared = ResumeRenderService.prepare_resume_context(
            {
                "personal_info": {
                    "name": "Vikash",
                    "email": "v@example.com",
                    "phone": "12345",
                },
                "skill_groups": {
                    "programming_languages": ["Dart"],
                    "mobile_framework": [],
                },
                "projects": [{"title": "", "description": "", "bullets": []}],
                "certifications": [{"title": "", "description": ""}],
                "education": [{"degree": "", "institution": "", "year": "", "location": ""}],
                "experience": [],
            }
        )

        self.assertTrue(prepared["has_skills"])
        self.assertFalse(prepared["has_projects"])
        self.assertFalse(prepared["has_certifications"])
        self.assertFalse(prepared["has_education"])

    def test_render_service_normalizes_urls_without_scheme(self):
        prepared = ResumeRenderService.prepare_resume_context(
            {
                "personal_info": {
                    "name": "Vikash",
                    "email": "v@example.com",
                    "phone": "12345",
                    "linkedin": "linkedin.com/in/vikash",
                    "github": "github.com/vikash",
                },
                "education": [],
                "experience": [],
                "skills": [],
                "projects": [],
            }
        )

        self.assertEqual(
            prepared["personal_info"]["linkedin_url"], "https://linkedin.com/in/vikash"
        )
        self.assertEqual(
            prepared["personal_info"]["github_url"], "https://github.com/vikash"
        )
