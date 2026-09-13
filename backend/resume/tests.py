from django.contrib.auth import get_user_model
from django.test import TestCase
from django.template import Context, Template
from pathlib import Path

from resume.models import ResumeTemplate
from resume.rendering import ResumeRenderService
from resume.serializers import ResumeSerializer
from resume.services import ResumeValidationService
from rest_framework.test import APIClient
from resume.json_resume import empty_resume
from resume.models import Resume


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

    def test_normalization_coerces_skill_keywords_and_highlights_to_lists(self):
        normalized = ResumeValidationService.normalize_resume_data(
            {
                "basics": {
                    "name": "Vikash",
                    "email": "v@example.com",
                    "phone": "12345",
                },
                "skills": [
                    {"name": "Python", "keywords": "Django, DRF"},
                    "Testing",
                ],
                "projects": [
                    {
                        "name": "Portal",
                        "description": "Customer portal",
                        "highlights": "Reduced support tickets",
                    }
                ],
                "work": [
                    {
                        "position": "Engineer",
                        "name": "Acme",
                        "highlights": "Shipped a reliable release",
                    }
                ],
                "education": [],
                "experience": [],
            }
        )

        self.assertEqual(normalized["skills"][0]["keywords"], ["Django", "DRF"])
        self.assertEqual(normalized["skills"][1]["keywords"], [])
        self.assertEqual(normalized["projects"][0]["highlights"], ["Reduced support tickets"])
        self.assertEqual(normalized["experience"][0]["highlights"], ["Shipped a reliable release"])

    def test_professional_template_renders_with_normalized_context(self):
        template_path = Path(__file__).resolve().parents[1] / "templates" / "resume" / "professional.html"
        html = template_path.read_text(encoding="utf-8")

        normalized = ResumeValidationService.normalize_resume_data(
            {
                "basics": {
                    "name": "Vikash",
                    "label": "Software Engineer",
                    "email": "v@example.com",
                    "phone": "12345",
                    "location": {"city": "Sydney"},
                    "profiles": [{"network": "github", "username": "vikash", "url": "https://github.com/vikash"}],
                    "summary": "Engineering leader",
                },
                "skills": [
                    {"name": "Python", "keywords": "Django, DRF"},
                ],
                "projects": [
                    {
                        "name": "Portal",
                        "url": "https://example.com",
                        "description": "Customer portal",
                        "highlights": "Reduced support tickets",
                    }
                ],
                "work": [
                    {
                        "position": "Engineer",
                        "name": "Acme",
                        "summary": "Built core APIs",
                        "highlights": "Shipped a reliable release",
                    }
                ],
                "education": [
                    {
                        "institution": "University",
                        "studyType": "BSc",
                        "area": "Computer Science",
                    }
                ],
            }
        )

        rendered = Template(html).render(Context({"resume": normalized}))

        self.assertIn("Shipped a reliable release", rendered)
        self.assertIn("Django, DRF", rendered)
        self.assertIn("Reduced support tickets", rendered)

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


class CanonicalJsonResumeRenderingTests(TestCase):
    def setUp(self):
        self.template = ResumeTemplate.objects.create(
            name="Professional Test",
            slug="professional-test",
            description="Trusted test theme",
            theme_identifier="professional",
            version=1,
            html_structure="",
            is_active=True,
        )

    def test_complete_resume_renders_all_sections_and_formats_dates(self):
        data = {
            "basics": {"name": "José O'Reilly & <Testing>", "label": "C++ Engineer", "email": "j@example.com", "phone": "123", "url": "https://example.com", "summary": "A & B", "location": {"city": "Montréal", "countryCode": "CA"}, "profiles": [{"network": "GitHub", "username": "j", "url": "https://github.com/j"}]},
            "work": [{"name": "AT&T", "position": "Engineer", "startDate": "2019-01-01", "endDate": None, "summary": "中文 भारत", "highlights": ["Built C#"]}],
            "volunteer": [{"organization": "Community", "position": "Mentor", "startDate": "2020", "endDate": "2021"}],
            "education": [{"institution": "University", "studyType": "BSc", "area": "CS", "startDate": "2015-09", "endDate": "2018-06", "courses": ["Algorithms"]}],
            "awards": [{"title": "Award", "date": "2022-02", "awarder": "Org", "summary": "Best"}],
            "certificates": [{"name": "Certificate", "date": "2023", "issuer": "Issuer", "url": "https://example.com/cert"}],
            "publications": [{"name": "Paper", "publisher": "Journal", "releaseDate": "2024-03-01", "url": "https://example.com/paper", "summary": "Research"}],
            "skills": [{"name": "Backend", "level": "Advanced", "keywords": ["Python", "Django"]}],
            "languages": [{"language": "French", "fluency": "Professional"}],
            "interests": [{"name": "Music", "keywords": ["Guitar"]}],
            "references": [{"name": "Ref", "reference": "Recommended"}],
            "projects": [{"name": "Project", "startDate": "2024-01", "endDate": "2024-12", "description": "Useful", "highlights": ["Shipped"], "url": "https://example.com/project"}],
        }
        html = ResumeRenderService.render_resume(data, self.template, resume_title="Complete")
        for text in ("Experience", "Projects", "Education", "Awards", "Volunteer", "Languages", "Skills", "Interests", "References", "Certificates", "Publications", "January 2019", "Present", "中文", "भारत"):
            self.assertIn(text, html)
        self.assertIn("José O&#x27;Reilly &amp; &lt;Testing&gt;", html)
        self.assertNotIn("<Testing>", html)
        self.assertNotIn("Thomas Davis", html)
        self.assertNotIn("thomasalwyndavis@gmail.com", html)
        self.assertNotIn("undefined", html)

    def test_minimal_resume_omits_empty_sections_and_dangerous_urls(self):
        data = empty_resume()
        data["basics"] = {"name": "Minimal", "url": "javascript:alert(1)", "profiles": [{"network": "Bad", "url": "data:text/html,x"}]}
        html = ResumeRenderService.render_resume(data, self.template)
        self.assertIn("Minimal", html)
        for heading in (">Experience<", ">Projects<", ">Education<", ">Skills<"):
            self.assertNotIn(heading, html)
        self.assertNotIn("javascript:", html)
        self.assertNotIn("data:text", html)


class ResumeRenderingApiTests(TestCase):
    def setUp(self):
        self.user = get_user_model().objects.create_user(email="owner@example.com", password="StrongPass123!", is_verified=True)
        self.other = get_user_model().objects.create_user(email="other@example.com", password="StrongPass123!", is_verified=True)
        self.template = ResumeTemplate.objects.create(name="Professional API", slug="professional-api", theme_identifier="professional", version=1, html_structure="", is_active=True)
        self.alternate = ResumeTemplate.objects.create(name="Alternate", slug="alternate", theme_identifier="professional", version=1, html_structure="", is_active=True)
        self.resume = Resume.objects.create(user=self.user, title="Mine", template=self.template, template_version=1, data={**empty_resume(), "basics": {"name": "Owner", "email": "owner@example.com"}})
        self.client = APIClient()

    def test_render_requires_authentication_and_ownership(self):
        url = f"/api/v1/resumes/{self.resume.pk}/render/"
        self.assertEqual(self.client.post(url, {}, format="json").status_code, 401)
        self.client.force_authenticate(self.other)
        self.assertEqual(self.client.post(url, {}, format="json").status_code, 404)
        self.client.force_authenticate(self.user)
        response = self.client.post(url, {}, format="json")
        self.assertEqual(response.status_code, 200, response.data)
        self.assertEqual(response.data["template"], "professional-api")
        self.assertIn("Owner", response.data["html"])

    def test_patch_deep_merges_basics_and_switching_template_preserves_data(self):
        self.client.force_authenticate(self.user)
        url = f"/api/v1/resumes/{self.resume.pk}/"
        response = self.client.patch(url, {"data": {"basics": {"name": "Updated"}}, "template_id": self.alternate.pk}, format="json")
        self.assertEqual(response.status_code, 200, response.data)
        self.resume.refresh_from_db()
        self.assertEqual(self.resume.data["basics"]["name"], "Updated")
        self.assertEqual(self.resume.data["basics"]["email"], "owner@example.com")
        self.assertEqual(self.resume.template, self.alternate)
        self.assertEqual(self.resume.template_version, 1)

    def test_create_initializes_empty_json_resume(self):
        self.client.force_authenticate(self.user)
        response = self.client.post("/api/v1/resumes/", {"title": "Empty", "template_id": self.template.pk}, format="json")
        self.assertEqual(response.status_code, 201, response.data)
        created = Resume.objects.get(pk=response.data["id"])
        self.assertEqual(created.data, empty_resume())

    def test_template_api_exposes_safe_active_metadata_by_slug(self):
        inactive = ResumeTemplate.objects.create(name="Hidden", slug="hidden", theme_identifier="professional", version=1, html_structure="secret", css="secret", is_active=False)
        response = self.client.get("/api/v1/resume-templates/")
        self.assertEqual(response.status_code, 200)
        payload = response.data.get("results", response.data)
        self.assertNotIn(inactive.pk, [item["id"] for item in payload])
        detail = self.client.get(f"/api/v1/resume-templates/{self.template.slug}/")
        self.assertEqual(detail.status_code, 200)
        self.assertEqual(detail.data["slug"], self.template.slug)
        self.assertNotIn("html_structure", detail.data)
        self.assertNotIn("css", detail.data)
