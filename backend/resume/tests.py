from django.contrib.auth import get_user_model
from django.test import TestCase

from resume.models import ResumeTemplate
from resume.serializers import ResumeSerializer


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
