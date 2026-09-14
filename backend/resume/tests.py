from django.contrib.auth import get_user_model
from django.test import TestCase
from django.template import Context, Template
from pathlib import Path
from io import BytesIO
import pdfplumber

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

    def test_canonical_nested_types_return_field_level_errors(self):
        serializer = ResumeSerializer(
            data={
                "title": "Invalid nested data",
                "template": self.template.id,
                "data": {
                    "basics": {
                        "name": "Alice",
                        "email": "alice@example.com",
                        "location": "Colombo",
                        "profiles": [{"network": "GitHub", "url": 42}],
                    },
                    "work": [{"name": "Acme", "position": "Engineer", "startDate": "January 2024", "highlights": {"value": "Built APIs"}}],
                },
            }
        )

        self.assertFalse(serializer.is_valid())
        errors = serializer.errors["data"]
        self.assertIn("basics", errors)
        self.assertIn("location", errors["basics"])
        self.assertIn("profiles", errors["basics"])

    def test_unknown_nested_fields_are_preserved_instead_of_silently_dropped(self):
        payload = {
            "basics": {"name": "Alice", "customHeadline": "Platform specialist"},
            "references": [],
        }
        serializer = ResumeSerializer(
            data={"title": "Extensible", "template": self.template.id, "data": payload}
        )

        self.assertTrue(serializer.is_valid(), serializer.errors)
        self.assertEqual(
            serializer.validated_data["data"]["basics"]["customHeadline"],
            "Platform specialist",
        )


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

    def test_wholly_empty_optional_rows_are_removed_before_required_validation(self):
        prepared = ResumeRenderService.prepare_resume_context({
            **empty_resume(),
            "basics": {"name": "Minimal"},
            "education": [{"institution": "", "studyType": "", "courses": []}],
            "work": [{"name": "", "position": "", "highlights": []}],
        })
        self.assertEqual(prepared["education"], [])
        self.assertEqual(prepared["work"], [])

    def test_all_thomas_themes_render_normalized_resume_data(self):
        data = {
            **empty_resume(),
            "basics": {"name": "Theme Candidate", "email": "theme@example.com", "summary": "Focused engineer."},
            "work": [{"name": "Acme", "position": "Engineer", "startDate": "2024", "highlights": ["Shipped"]}],
        }
        for identifier in ("thomas-slate", "thomas-desert-modern", "thomas-navy-sidebar"):
            with self.subTest(identifier=identifier):
                template = ResumeTemplate.objects.create(
                    name=identifier, slug=f"{identifier}-test", theme_identifier=identifier,
                    version=1, html_structure="", is_active=True,
                )
                html = ResumeRenderService.render_resume(data, template)
                self.assertIn("Theme Candidate", html)
                self.assertIn("theme@example.com", html)
                self.assertIn("Acme", html)
                self.assertIn("Shipped", html)


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

    def test_incomplete_draft_can_be_saved_but_cannot_be_finalized(self):
        self.client.force_authenticate(self.user)
        payload = {
            "title": "Draft",
            "template_id": self.template.pk,
            "metadata": {"status": "draft"},
            "data": {**empty_resume(), "work": [{"position": "Engineer"}]},
        }
        draft = self.client.post("/api/v1/resumes/", payload, format="json")
        self.assertEqual(draft.status_code, 201, draft.data)
        final = self.client.patch(
            f"/api/v1/resumes/{draft.data['id']}/",
            {"metadata": {"status": "complete"}, "data": payload["data"]},
            format="json",
        )
        self.assertEqual(final.status_code, 400)
        self.assertIn("basics", final.data["data"])

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
        section_keys = [section["key"] for section in detail.data["form_schema"]["sections"]]
        self.assertEqual(
            section_keys,
            ["basics", "work", "education", "skills", "projects", "certificates", "languages", "awards", "volunteer", "publications", "interests", "references"],
        )

    def test_template_detail_accepts_uuid_used_by_flutter_gallery(self):
        response = self.client.get(f"/api/v1/templates/{self.template.pk}/")
        self.assertEqual(response.status_code, 200, response.data)
        self.assertEqual(response.data["id"], str(self.template.pk))
        self.assertEqual(response.data["slug"], self.template.slug)
        self.assertTrue(response.data["form_schema"]["sections"])

    def test_complete_payload_is_preserved_and_every_section_reaches_pdf(self):
        long_summary = "Platform engineer focused on reliable systems. " * 80
        payload = {
            "basics": {
                "name": "Complete Candidate", "label": "Staff Engineer", "email": "complete@example.com",
                "phone": "+1 555 0100", "url": "example.com", "summary": long_summary,
                "location": {"address": "42 Sentinel Road", "city": "Colombo", "region": "Western", "postalCode": "00100", "countryCode": "LK"},
                "profiles": [{"network": "GitHub", "username": "complete", "url": "github.com/complete"}],
            },
            "work": [
                {"name": "Current Corp", "position": "Lead Engineer", "url": "work.example.test", "startDate": "2023-01", "endDate": None, "location": "Remote", "summary": "Leads platform delivery.", "highlights": ["Improved reliability", "Mentored engineers"]},
                {"company": "Legacy Ltd", "title": "Software Engineer", "start_date": "2020-01", "end_date": "2022-12", "responsibilities": ["Built payment services", "Reduced latency"]},
            ],
            "education": [{"institution": "State University", "url": "education.example.test", "studyType": "BSc", "area": "Computer Science", "score": "First Class", "startDate": "2016", "endDate": "2019", "location": "Kandy Campus", "courses": ["Algorithms", "Databases"]}],
            "skills": [{"name": "Backend", "level": "Advanced", "keywords": ["Python", "Django"]}, {"name": "Mobile", "keywords": ["Flutter", "Dart"]}],
            "projects": [{"name": "PrepMate", "description": "Resume platform", "roles": ["Architect"], "highlights": ["Generated accessible PDFs"], "url": "project.example.test", "startDate": "2022-02", "endDate": "2024-04"}, {"name": "Observatory", "description": "Monitoring suite", "roles": ["Maintainer"], "highlights": ["Processed millions of events"]}],
            "certificates": [{"title": "Cloud Professional", "issuer": "Cloud Org", "issue_date": "2024-03", "credential_url": "example.com/cert", "description": "Advanced cloud certification"}],
            "languages": [{"language": "English", "fluency": "Professional"}],
            "awards": [{"title": "Engineering Award", "awarder": "Tech Guild", "date": "2024", "summary": "For technical leadership"}],
            "volunteer": [{"organization": "Code Club", "position": "Mentor", "url": "volunteer.example.test", "startDate": "2021", "endDate": None, "summary": "Taught programming", "highlights": ["Supported 40 students"]}],
            "publications": [{"name": "Reliable PDF Pipelines", "publisher": "Engineering Journal", "releaseDate": "2025-02", "url": "example.com/paper", "summary": "Rendering research"}],
            "interests": [{"name": "Open Source", "keywords": ["Accessibility"]}],
            "references": [{"name": "Reference Person", "reference": "Strongly recommended"}],
        }
        self.client.force_authenticate(self.user)
        response = self.client.post("/api/v1/resumes/", {"title": "Complete", "template_id": self.template.pk, "data": payload}, format="json")
        self.assertEqual(response.status_code, 201, response.data)
        created = Resume.objects.get(pk=response.data["id"])
        self.assertEqual(created.data["work"][0]["endDate"], None)
        self.assertEqual(created.data["work"][1]["name"], "Legacy Ltd")
        self.assertEqual(created.data["work"][1]["position"], "Software Engineer")
        self.assertEqual(created.data["work"][1]["highlights"], ["Built payment services", "Reduced latency"])
        self.assertEqual(created.data["certificates"][0]["issuer"], "Cloud Org")
        self.assertEqual(created.data["certificates"][0]["summary"], "Advanced cloud certification")

        expected = [
            "Complete Candidate", "Staff Engineer", "complete@example.com", "+1 555 0100",
            "example.com", "42 Sentinel Road", "Colombo", "Western", "00100", "LK",
            "GitHub", "complete", "github.com/complete",
            "Current Corp", "Lead Engineer", "work.example.test", "Remote", "Present",
            "Leads platform delivery", "Improved reliability", "Legacy Ltd", "Built payment services",
            "State University", "education.example.test", "BSc", "Computer Science", "First Class",
            "Kandy Campus", "Algorithms", "Backend", "Advanced", "Python", "PrepMate",
            "Resume platform", "project.example.test", "Architect", "Generated accessible PDFs",
            "Cloud Professional", "Cloud Org", "example.com/cert", "Advanced cloud certification", "English", "Professional",
            "Engineering Award", "Tech Guild", "technical leadership", "Code Club", "Mentor",
            "volunteer.example.test", "Taught programming", "Supported 40 students",
            "Reliable PDF Pipelines", "Engineering Journal", "example.com/paper", "Rendering research", "Open Source",
            "Accessibility", "Reference Person", "Strongly recommended",
        ]
        preview = self.client.post(f"/api/v1/resumes/{created.pk}/render/", {}, format="json")
        self.assertEqual(preview.status_code, 200, preview.data)
        for value in expected:
            self.assertIn(value, preview.data["html"])

        pdf = self.client.get(f"/api/v1/resumes/{created.pk}/pdf/")
        self.assertEqual(pdf.status_code, 200)
        with pdfplumber.open(BytesIO(pdf.content)) as document:
            pdf_text = "\n".join(page.extract_text() or "" for page in document.pages)
            self.assertGreaterEqual(len(document.pages), 2)
        for value in expected:
            self.assertIn(value, pdf_text)
