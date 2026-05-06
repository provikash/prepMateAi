from django.core.management.base import BaseCommand
import os
import json


PROFESSIONAL_FORM_SCHEMA = {
    "sections": [
        {
            "title": "Personal Information",
            "key": "basics",
            "type": "single",
            "ai_actions": ["generate_summary"],
            "fields": [
                {"key": "name",    "label": "Full Name",             "type": "text",     "required": True},
                {"key": "label",   "label": "Professional Title",    "type": "text"},
                {"key": "email",   "label": "Email",                 "type": "email"},
                {"key": "phone",   "label": "Phone",                 "type": "text"},
                {"key": "url",     "label": "Website / Portfolio",   "type": "url"},
                {"key": "location","label": "City / Location",       "type": "text"},
                {
                    "key": "summary", "label": "Professional Summary",
                    "type": "textarea",
                    "ai_actions": ["generate_summary", "improve_section"]
                }
            ]
        },
        {
            "title": "Work Experience",
            "key": "work",
            "type": "repeatable",
            "ai_actions": ["generate_bullets", "improve_section"],
            "fields": [
                {"key": "position",  "label": "Job Title",     "type": "text", "required": True},
                {"key": "name",      "label": "Company Name",  "type": "text", "required": True},
                {"key": "startDate", "label": "Start Date",    "type": "date"},
                {"key": "endDate",   "label": "End Date",      "type": "date"},
                {"key": "location",  "label": "Location",      "type": "text"},
                {"key": "summary",   "label": "Description",   "type": "textarea",
                 "ai_actions": ["improve_section"]},
                {"key": "highlights","label": "Key Achievements (one per line)",
                 "type": "textarea", "ai_actions": ["generate_bullets"]}
            ]
        },
        {
            "title": "Education",
            "key": "education",
            "type": "repeatable",
            "fields": [
                {"key": "institution", "label": "School / University", "type": "text", "required": True},
                {"key": "studyType",   "label": "Degree",              "type": "text"},
                {"key": "area",        "label": "Field of Study",      "type": "text"},
                {"key": "startDate",   "label": "Start Date",          "type": "date"},
                {"key": "endDate",     "label": "End Date",            "type": "date"},
                {"key": "score",       "label": "GPA / Score",         "type": "text"}
            ]
        },
        {
            "title": "Skills",
            "key": "skills",
            "type": "repeatable",
            "ai_actions": ["suggest_skills"],
            "fields": [
                {"key": "name",     "label": "Skill / Category", "type": "text", "required": True},
                {"key": "level",    "label": "Proficiency",      "type": "select",
                 "options": ["Beginner", "Intermediate", "Advanced", "Expert"]},
                {"key": "keywords", "label": "Keywords (comma-separated)", "type": "textarea"}
            ]
        },
        {
            "title": "Projects",
            "key": "projects",
            "type": "repeatable",
            "ai_actions": ["improve_section"],
            "fields": [
                {"key": "name",        "label": "Project Name",  "type": "text", "required": True},
                {"key": "description", "label": "Description",   "type": "textarea"},
                {"key": "url",         "label": "Project URL",   "type": "url"},
                {"key": "startDate",   "label": "Start Date",    "type": "date"},
                {"key": "endDate",     "label": "End Date",      "type": "date"},
                {"key": "highlights",  "label": "Key Points (one per line)", "type": "textarea"}
            ]
        }
    ]
}


class Command(BaseCommand):
    help = "Ensure Thomas JSON Resume template exists and list resume PDFs"

    def handle(self, *args, **options):
        from django.apps import apps
        ResumeTemplate = None
        try:
            ResumeTemplate = apps.get_model('resume', 'ResumeTemplate')
        except LookupError:
            try:
                ResumeTemplate = apps.get_model('templates', 'ResumeTemplate')
            except LookupError:
                self.stdout.write(self.style.WARNING('ResumeTemplate model not found; skipping template creation.'))

        if ResumeTemplate:
            fixtures_dir = os.path.join(os.path.dirname(__file__), '..', 'fixtures')
            fixtures_dir = os.path.normpath(fixtures_dir)
            # JSON Resume standard schema for Flutter form generation
            schema = {
                "sections": [
                    {
                        "title": "Personal Information",
                        "key": "personal_info",
                        "type": "single",
                        "ai_actions": ["generate_summary"],
                        "fields": [
                            {"key": "name", "label": "Full Name", "type": "text", "required": True},
                            {"key": "label", "label": "Professional Title", "type": "text"},
                            {"key": "email", "label": "Email", "type": "email"},
                            {"key": "phone", "label": "Phone", "type": "text"},
                            {"key": "website", "label": "Website/Portfolio URL", "type": "url"},
                            {"key": "location", "label": "Location", "type": "text"},
                            {"key": "summary", "label": "Professional Summary", "type": "textarea", "ai_actions": ["generate_summary", "improve_summary"]}
                        ]
                    },
                    {
                      "title": "Work Experience",
                      "key": "work",
                      "type": "repeatable",
                      "ai_actions": ["suggest_bullets", "improve_description"],
                      "fields": [
                        {"key": "name", "label": "Company Name", "type": "text", "required": True},
                        {"key": "position", "label": "Job Title", "type": "text", "required": True},
                        {"key": "startDate", "label": "Start Date", "type": "date"},
                        {"key": "endDate", "label": "End Date", "type": "date"},
                        {"key": "location", "label": "Location", "type": "text"},
                        {"key": "summary", "label": "Description", "type": "textarea", "ai": ["improve_description"]},
                        {"key": "website", "label": "Company Website", "type": "url"},
                        {"key": "highlights", "label": "Key Achievements", "type": "textarea", "help": "Enter each achievement on a new line", "ai": ["suggest_bullets"]}
                      ]
                    },
                    {
                        "title": "Education",
                        "key": "education",
                        "type": "repeatable",
                        "fields": [
                            {"key": "institution", "label": "School/University", "type": "text", "required": True},
                            {"key": "studyType", "label": "Degree", "type": "text"},
                            {"key": "area", "label": "Field of Study", "type": "text"},
                            {"key": "startDate", "label": "Start Date", "type": "date"},
                            {"key": "endDate", "label": "End Date", "type": "date"},
                            {"key": "score", "label": "GPA/Score", "type": "text"}
                        ]
                    },
                    {
                        "title": "Skills",
                        "key": "skills",
                        "type": "repeatable",
                        "ai_actions": ["suggest_skills"],
                        "fields": [
                            {"key": "name", "label": "Skill Name", "type": "text", "required": True},
                            {"key": "level", "label": "Proficiency Level", "type": "select", "options": ["Beginner", "Intermediate", "Advanced", "Expert"]},
                            {"key": "keywords", "label": "Keywords/Technologies", "type": "textarea", "help": "Comma-separated or one per line"}
                        ]
                    },
                    {
                        "title": "Projects",
                        "key": "projects",
                        "type": "repeatable",
                        "ai_actions": ["improve_description"],
                        "fields": [
                            {"key": "name", "label": "Project Name", "type": "text", "required": True},
                            {"key": "description", "label": "Description", "type": "textarea"},
                            {"key": "startDate", "label": "Start Date", "type": "date"},
                            {"key": "endDate", "label": "End Date", "type": "date"},
                            {"key": "website", "label": "Project URL", "type": "url"},
                            {"key": "highlights", "label": "Key Points", "type": "textarea", "help": "Enter each point on a new line"}
                        ]
                    },
                    {
                        "title": "Certifications & Awards",
                        "key": "awards",
                        "type": "repeatable",
                        "fields": [
                            {"key": "title", "label": "Award/Certification Name", "type": "text", "required": True},
                            {"key": "awarder", "label": "Issuing Organization", "type": "text"},
                            {"key": "date", "label": "Date Received", "type": "date"},
                            {"key": "summary", "label": "Description", "type": "textarea"}
                        ]
                    },
                    {
                        "title": "Languages",
                        "key": "languages",
                        "type": "repeatable",
                        "fields": [
                            {"key": "language", "label": "Language", "type": "text", "required": True},
                            {"key": "fluency", "label": "Proficiency", "type": "select", "options": ["Elementary", "Limited Working", "Professional Working", "Full Professional", "Native Speaker"]}
                        ]
                    },
                    {
                        "title": "Volunteer & References",
                        "key": "references",
                        "type": "repeatable",
                        "fields": [
                            {"key": "name", "label": "Person Name", "type": "text", "required": True},
                            {"key": "reference", "label": "Reference/Recommendation", "type": "textarea"}
                        ]
                    }
                ]
            }

            # Complete HTML template supporting all JSON Resume sections
            html_structure = '''
{% load static %}
<div class="resume-root">
  <header>
    <h1>{{ resume.personal_info.name }}</h1>
    {% if resume.personal_info.label %}<p class="title">{{ resume.personal_info.label }}</p>{% endif %}
    <p class="contact">
      {% if resume.personal_info.email %}{{ resume.personal_info.email }}{% endif %}
      {% if resume.personal_info.phone %}{% if resume.personal_info.email %} • {% endif %}{{ resume.personal_info.phone }}{% endif %}
      {% if resume.personal_info.website %}{% if resume.personal_info.email or resume.personal_info.phone %} • {% endif %}<a href="{{ resume.personal_info.website }}">{{ resume.personal_info.website }}</a>{% endif %}
    </p>
  </header>

  {% if resume.personal_info.summary %}
  <section class="summary">
    <h2>Professional Summary</h2>
    <p>{{ resume.personal_info.summary }}</p>
  </section>
  {% endif %}

  {% if resume.experience %}
  <section class="experience">
    <h2>Professional Experience</h2>
    {% for job in resume.experience %}
    <div class="job">
      <div class="job-header">
        <h3>{{ job.position }}</h3>
        <span class="company">{{ job.name }}</span>
        {% if job.startDate or job.endDate %}
        <span class="dates">{{ job.startDate }}{% if job.endDate %} — {{ job.endDate }}{% endif %}</span>
        {% endif %}
      </div>
      {% if job.location %}<p class="location">{{ job.location }}</p>{% endif %}
      {% if job.summary %}<p class="summary">{{ job.summary }}</p>{% endif %}
      {% if job.highlights %}
      <ul class="highlights">
        {% for highlight in job.highlights %}
        <li>{{ highlight }}</li>
        {% endfor %}
      </ul>
      {% endif %}
    </div>
    {% endfor %}
  </section>
  {% endif %}

  {% if resume.education %}
  <section class="education">
    <h2>Education</h2>
    {% for edu in resume.education %}
    <div class="education-item">
      <h3>{{ edu.institution }}</h3>
      <div class="degree-info">
        {% if edu.studyType %}{{ edu.studyType }}{% if edu.area %} in {{ edu.area }}{% endif %}{% endif %}
        {% if edu.startDate or edu.endDate %}
        <span class="dates">{{ edu.startDate }}{% if edu.endDate %} — {{ edu.endDate }}{% endif %}</span>
        {% endif %}
      </div>
      {% if edu.score %}<p class="score">GPA: {{ edu.score }}</p>{% endif %}
    </div>
    {% endfor %}
  </section>
  {% endif %}

  {% if resume.skills %}
  <section class="skills">
    <h2>Skills</h2>
    {% for skill in resume.skills %}
    <div class="skill-group">
      <h3>{{ skill.name }}</h3>
      {% if skill.level %}<span class="level">{{ skill.level }}</span>{% endif %}
      {% if skill.keywords %}<p class="keywords">{{ skill.keywords }}</p>{% endif %}
    </div>
    {% endfor %}
  </section>
  {% endif %}

  {% if resume.projects %}
  <section class="projects">
    <h2>Projects</h2>
    {% for project in resume.projects %}
    <div class="project">
      <h3>
        {% if project.website %}<a href="{{ project.website }}">{{ project.name }}</a>{% else %}{{ project.name }}{% endif %}
      </h3>
      {% if project.startDate or project.endDate %}
      <span class="dates">{{ project.startDate }}{% if project.endDate %} — {{ project.endDate }}{% endif %}</span>
      {% endif %}
      {% if project.description %}<p class="description">{{ project.description }}</p>{% endif %}
      {% if project.highlights %}
      <ul class="highlights">
        {% for highlight in project.highlights %}
        <li>{{ highlight }}</li>
        {% endfor %}
      </ul>
      {% endif %}
    </div>
    {% endfor %}
  </section>
  {% endif %}

  {% if resume.awards %}
  <section class="awards">
    <h2>Certifications & Awards</h2>
    {% for award in resume.awards %}
    <div class="award">
      <h3>{{ award.title }}</h3>
      {% if award.awarder %}<p class="awarder">{{ award.awarder }}</p>{% endif %}
      {% if award.date %}<span class="date">{{ award.date }}</span>{% endif %}
      {% if award.summary %}<p class="summary">{{ award.summary }}</p>{% endif %}
    </div>
    {% endfor %}
  </section>
  {% endif %}

  {% if resume.languages %}
  <section class="languages">
    <h2>Languages</h2>
    <ul>
      {% for lang in resume.languages %}
      <li>
        <strong>{{ lang.language }}</strong>
        {% if lang.fluency %}<span class="fluency">— {{ lang.fluency }}</span>{% endif %}
      </li>
      {% endfor %}
    </ul>
  </section>
  {% endif %}

  {% if resume.references %}
  <section class="references">
    <h2>References</h2>
    {% for ref in resume.references %}
    <div class="reference">
      <p class="name"><strong>{{ ref.name }}</strong></p>
      <p class="quote">{{ ref.reference }}</p>
    </div>
    {% endfor %}
  </section>
  {% endif %}
</div>
'''

            template_names = [
              'Thomas Davis (JSON Resume)',
              'Thomas Davis 2 (imported)',
            ]

            for template_name in template_names:
              obj, created = ResumeTemplate.objects.update_or_create(
                name=template_name,
                defaults={
                  'category': 'imported',
                  'html_structure': html_structure,
                  'metadata': {'form_schema': schema},
                  'is_active': True,
                },
              )

              try:
                if obj.html_structure and '__TEMPLATE_ID__' in obj.html_structure:
                  obj.html_structure = (
                    obj.html_structure.replace('__TEMPLATE_ID__', str(obj.id))
                    .replace('__TID__', str(obj.id))
                    .replace('__RESUME_JSON__', json.dumps(schema))
                  )
                  obj.save(update_fields=['html_structure'])
              except Exception:
                pass

              if created:
                self.stdout.write(self.style.SUCCESS(f'Created Template: {template_name}'))
              else:
                self.stdout.write(self.style.NOTICE(f'Template already exists or updated: {template_name}'))

            # ── NEW: Professional (Academic CV Lite) template ──────────────────
            self._ensure_professional_template(ResumeTemplate)

        # List resumes with pdf files
        try:
            Resume = apps.get_model('resume', 'Resume')
            resumes = Resume.objects.all()
            if not resumes.exists():
                self.stdout.write('No Resume records found.')
                return

            self.stdout.write('\nResumes with PDF info:')
            for r in resumes:
                pdf_field = getattr(r, 'pdf_file', None)
                pdf_path = pdf_field.path if pdf_field and hasattr(pdf_field, 'path') else None
                exists = os.path.exists(pdf_path) if pdf_path else False
                self.stdout.write(f'- {r.id} | {r.title} | pdf: {pdf_path} | exists: {exists}')
        except LookupError:
            self.stdout.write(self.style.WARNING('Resume model not found; cannot list resumes.'))

    # ──────────────────────────────────────────────────────────────────────────
    def _ensure_professional_template(self, ResumeTemplate):
        """
        Load the Professional (Academic CV Lite) HTML template from disk and
        upsert it into the ResumeTemplate table.

        The HTML file lives at:
            backend/templates/resume/professional.html

        This method is idempotent — running the command multiple times is safe.
        """
        # Resolve path relative to this management command file.
        # __file__ = backend/templates/management/commands/ensure_thomas_template.py
        # We go up 3 levels to reach backend/templates/, then into resume/.
        base_dir = os.path.normpath(
            os.path.join(os.path.dirname(__file__), '..', '..', 'resume')
        )
        html_path = os.path.join(base_dir, 'professional.html')

        if not os.path.exists(html_path):
            self.stdout.write(
                self.style.WARNING(
                    f'Professional template file not found at {html_path}. '
                    'Skipping Professional template creation.'
                )
            )
            return

        with open(html_path, 'r', encoding='utf-8') as f:
            html_content = f.read()

        professional_css = """
/* ── Professional Resume CSS (injected by management command) ── */
* { box-sizing: border-box; margin: 0; padding: 0; }
body { font-family: Georgia, 'Times New Roman', serif; font-size: 11pt;
       color: #111827; line-height: 1.6; background: #ffffff; }
.resume-wrapper { max-width: 800px; margin: 0 auto; padding: 40px; background: #ffffff; }
.header { text-align: center; padding-bottom: 20px; margin-bottom: 32px;
          border-bottom: 1px solid #6b7280; }
.header-name { font-size: 26pt; font-weight: 700; color: #111827;
               margin-bottom: 6px; letter-spacing: 0.5px; }
.header-label { font-size: 13pt; color: #1f2937; font-style: italic;
                margin-bottom: 14px; }
.header-contact { font-size: 10pt; color: #1f2937; }
.header-contact a { color: #1f2937; text-decoration: underline; }
.contact-sep { color: #9ca3af; margin: 0 6px; }
.header-summary { font-size: 11pt; line-height: 1.6; color: #1f2937;
                  margin-top: 16px; text-align: left; }
.section { margin-bottom: 28px; page-break-inside: avoid; }
.section-title { font-size: 14pt; font-weight: 700; color: #111827;
                 margin-bottom: 14px; padding-bottom: 5px;
                 border-bottom: 2px solid #111827;
                 text-transform: uppercase; letter-spacing: 1px; }
.work-item { margin-bottom: 20px; }
.work-item:last-child { margin-bottom: 0; }
.work-position { font-size: 12pt; font-weight: 700; color: #111827; margin-bottom: 2px; }
.work-company { font-size: 11pt; color: #1f2937; font-style: italic; margin-bottom: 2px; }
.work-date { font-size: 10pt; color: #6b7280; margin-bottom: 6px; }
.work-summary { font-size: 11pt; color: #1f2937; line-height: 1.5; margin-bottom: 6px; }
.work-highlights { margin: 6px 0 0 18px; padding: 0; list-style-type: disc; }
.work-highlights li { font-size: 11pt; color: #1f2937; line-height: 1.5; margin-bottom: 3px; }
.edu-item { margin-bottom: 16px; }
.edu-institution { font-size: 12pt; font-weight: 700; color: #111827; margin-bottom: 2px; }
.edu-degree { font-size: 11pt; color: #1f2937; margin-bottom: 2px; }
.edu-date { font-size: 10pt; color: #6b7280; }
.project-item { margin-bottom: 20px; padding-left: 18px; border-left: 3px solid #9ca3af; }
.project-item:last-child { margin-bottom: 0; }
.project-name { font-size: 12pt; font-weight: 700; color: #111827; margin-bottom: 2px; }
.project-description { font-size: 11pt; color: #1f2937; line-height: 1.5; margin-bottom: 6px; }
.project-highlights { margin: 4px 0 0 16px; padding: 0; list-style-type: disc; }
.project-highlights li { font-size: 11pt; color: #1f2937; line-height: 1.5; margin-bottom: 3px; }
.project-url { font-size: 10pt; color: #1f2937; text-decoration: underline; }
.skills-grid { display: table; width: 100%; border-collapse: collapse; }
.skill-row { display: table-row; }
.skill-name { display: table-cell; font-weight: 700; color: #111827; font-size: 11pt;
              padding: 3px 12px 3px 0; width: 130px; vertical-align: top; white-space: nowrap; }
.skill-keywords { display: table-cell; color: #1f2937; font-size: 11pt;
                  padding: 3px 0; vertical-align: top; }
@media print { .section { page-break-inside: avoid; } .work-item { page-break-inside: avoid; } }
"""

        obj, created = ResumeTemplate.objects.update_or_create(
            name='Professional (Academic CV Lite)',
            defaults={
                'category': 'professional',
                'html_structure': html_content,
                'css': professional_css,
                'metadata': {'form_schema': PROFESSIONAL_FORM_SCHEMA},
                'is_active': True,
            },
        )

        action = 'Created' if created else 'Updated'
        self.stdout.write(
            self.style.SUCCESS(f'{action} Template: Professional (Academic CV Lite)')
        )


        if ResumeTemplate:
            fixtures_dir = os.path.join(os.path.dirname(__file__), '..', 'fixtures')
            fixtures_dir = os.path.normpath(fixtures_dir)
            # JSON Resume standard schema for Flutter form generation
            schema = {
                "sections": [
                    {
                        "title": "Personal Information",
                        "key": "personal_info",
                        "type": "single",
                        "ai_actions": ["generate_summary"],
                        "fields": [
                            {"key": "name", "label": "Full Name", "type": "text", "required": True},
                            {"key": "label", "label": "Professional Title", "type": "text"},
                            {"key": "email", "label": "Email", "type": "email"},
                            {"key": "phone", "label": "Phone", "type": "text"},
                            {"key": "website", "label": "Website/Portfolio URL", "type": "url"},
                            {"key": "location", "label": "Location", "type": "text"},
                            {"key": "summary", "label": "Professional Summary", "type": "textarea", "ai_actions": ["generate_summary", "improve_summary"]}
                        ]
                    },
                    {
                      "title": "Work Experience",
                      "key": "work",
                      "type": "repeatable",
                      "ai_actions": ["suggest_bullets", "improve_description"],
                      "fields": [
                        {"key": "name", "label": "Company Name", "type": "text", "required": True},
                        {"key": "position", "label": "Job Title", "type": "text", "required": True},
                        {"key": "startDate", "label": "Start Date", "type": "date"},
                        {"key": "endDate", "label": "End Date", "type": "date"},
                        {"key": "location", "label": "Location", "type": "text"},
                        {"key": "summary", "label": "Description", "type": "textarea", "ai": ["improve_description"]},
                        {"key": "website", "label": "Company Website", "type": "url"},
                        {"key": "highlights", "label": "Key Achievements", "type": "textarea", "help": "Enter each achievement on a new line", "ai": ["suggest_bullets"]}
                      ]
                    },
                    {
                        "title": "Education",
                        "key": "education",
                        "type": "repeatable",
                        "fields": [
                            {"key": "institution", "label": "School/University", "type": "text", "required": True},
                            {"key": "studyType", "label": "Degree", "type": "text"},
                            {"key": "area", "label": "Field of Study", "type": "text"},
                            {"key": "startDate", "label": "Start Date", "type": "date"},
                            {"key": "endDate", "label": "End Date", "type": "date"},
                            {"key": "score", "label": "GPA/Score", "type": "text"}
                        ]
                    },
                    {
                        "title": "Skills",
                        "key": "skills",
                        "type": "repeatable",
                        "ai_actions": ["suggest_skills"],
                        "fields": [
                            {"key": "name", "label": "Skill Name", "type": "text", "required": True},
                            {"key": "level", "label": "Proficiency Level", "type": "select", "options": ["Beginner", "Intermediate", "Advanced", "Expert"]},
                            {"key": "keywords", "label": "Keywords/Technologies", "type": "textarea", "help": "Comma-separated or one per line"}
                        ]
                    },
                    {
                        "title": "Projects",
                        "key": "projects",
                        "type": "repeatable",
                        "ai_actions": ["improve_description"],
                        "fields": [
                            {"key": "name", "label": "Project Name", "type": "text", "required": True},
                            {"key": "description", "label": "Description", "type": "textarea"},
                            {"key": "startDate", "label": "Start Date", "type": "date"},
                            {"key": "endDate", "label": "End Date", "type": "date"},
                            {"key": "website", "label": "Project URL", "type": "url"},
                            {"key": "highlights", "label": "Key Points", "type": "textarea", "help": "Enter each point on a new line"}
                        ]
                    },
                    {
                        "title": "Certifications & Awards",
                        "key": "awards",
                        "type": "repeatable",
                        "fields": [
                            {"key": "title", "label": "Award/Certification Name", "type": "text", "required": True},
                            {"key": "awarder", "label": "Issuing Organization", "type": "text"},
                            {"key": "date", "label": "Date Received", "type": "date"},
                            {"key": "summary", "label": "Description", "type": "textarea"}
                        ]
                    },
                    {
                        "title": "Languages",
                        "key": "languages",
                        "type": "repeatable",
                        "fields": [
                            {"key": "language", "label": "Language", "type": "text", "required": True},
                            {"key": "fluency", "label": "Proficiency", "type": "select", "options": ["Elementary", "Limited Working", "Professional Working", "Full Professional", "Native Speaker"]}
                        ]
                    },
                    {
                        "title": "Volunteer & References",
                        "key": "references",
                        "type": "repeatable",
                        "fields": [
                            {"key": "name", "label": "Person Name", "type": "text", "required": True},
                            {"key": "reference", "label": "Reference/Recommendation", "type": "textarea"}
                        ]
                    }
                ]
            }

            # Complete HTML template supporting all JSON Resume sections
            html_structure = '''
{% load static %}
<div class="resume-root">
  <header>
    <h1>{{ resume.personal_info.name }}</h1>
    {% if resume.personal_info.label %}<p class="title">{{ resume.personal_info.label }}</p>{% endif %}
    <p class="contact">
      {% if resume.personal_info.email %}{{ resume.personal_info.email }}{% endif %}
      {% if resume.personal_info.phone %}{% if resume.personal_info.email %} • {% endif %}{{ resume.personal_info.phone }}{% endif %}
      {% if resume.personal_info.website %}{% if resume.personal_info.email or resume.personal_info.phone %} • {% endif %}<a href="{{ resume.personal_info.website }}">{{ resume.personal_info.website }}</a>{% endif %}
    </p>
  </header>

  {% if resume.personal_info.summary %}
  <section class="summary">
    <h2>Professional Summary</h2>
    <p>{{ resume.personal_info.summary }}</p>
  </section>
  {% endif %}

  {% if resume.experience %}
  <section class="experience">
    <h2>Professional Experience</h2>
    {% for job in resume.experience %}
    <div class="job">
      <div class="job-header">
        <h3>{{ job.position }}</h3>
        <span class="company">{{ job.name }}</span>
        {% if job.startDate or job.endDate %}
        <span class="dates">{{ job.startDate }}{% if job.endDate %} — {{ job.endDate }}{% endif %}</span>
        {% endif %}
      </div>
      {% if job.location %}<p class="location">{{ job.location }}</p>{% endif %}
      {% if job.summary %}<p class="summary">{{ job.summary }}</p>{% endif %}
      {% if job.highlights %}
      <ul class="highlights">
        {% for highlight in job.highlights %}
        <li>{{ highlight }}</li>
        {% endfor %}
      </ul>
      {% endif %}
    </div>
    {% endfor %}
  </section>
  {% endif %}

  {% if resume.education %}
  <section class="education">
    <h2>Education</h2>
    {% for edu in resume.education %}
    <div class="education-item">
      <h3>{{ edu.institution }}</h3>
      <div class="degree-info">
        {% if edu.studyType %}{{ edu.studyType }}{% if edu.area %} in {{ edu.area }}{% endif %}{% endif %}
        {% if edu.startDate or edu.endDate %}
        <span class="dates">{{ edu.startDate }}{% if edu.endDate %} — {{ edu.endDate }}{% endif %}</span>
        {% endif %}
      </div>
      {% if edu.score %}<p class="score">GPA: {{ edu.score }}</p>{% endif %}
    </div>
    {% endfor %}
  </section>
  {% endif %}

  {% if resume.skills %}
  <section class="skills">
    <h2>Skills</h2>
    {% for skill in resume.skills %}
    <div class="skill-group">
      <h3>{{ skill.name }}</h3>
      {% if skill.level %}<span class="level">{{ skill.level }}</span>{% endif %}
      {% if skill.keywords %}<p class="keywords">{{ skill.keywords }}</p>{% endif %}
    </div>
    {% endfor %}
  </section>
  {% endif %}

  {% if resume.projects %}
  <section class="projects">
    <h2>Projects</h2>
    {% for project in resume.projects %}
    <div class="project">
      <h3>
        {% if project.website %}<a href="{{ project.website }}">{{ project.name }}</a>{% else %}{{ project.name }}{% endif %}
      </h3>
      {% if project.startDate or project.endDate %}
      <span class="dates">{{ project.startDate }}{% if project.endDate %} — {{ project.endDate }}{% endif %}</span>
      {% endif %}
      {% if project.description %}<p class="description">{{ project.description }}</p>{% endif %}
      {% if project.highlights %}
      <ul class="highlights">
        {% for highlight in project.highlights %}
        <li>{{ highlight }}</li>
        {% endfor %}
      </ul>
      {% endif %}
    </div>
    {% endfor %}
  </section>
  {% endif %}

  {% if resume.awards %}
  <section class="awards">
    <h2>Certifications & Awards</h2>
    {% for award in resume.awards %}
    <div class="award">
      <h3>{{ award.title }}</h3>
      {% if award.awarder %}<p class="awarder">{{ award.awarder }}</p>{% endif %}
      {% if award.date %}<span class="date">{{ award.date }}</span>{% endif %}
      {% if award.summary %}<p class="summary">{{ award.summary }}</p>{% endif %}
    </div>
    {% endfor %}
  </section>
  {% endif %}

  {% if resume.languages %}
  <section class="languages">
    <h2>Languages</h2>
    <ul>
      {% for lang in resume.languages %}
      <li>
        <strong>{{ lang.language }}</strong>
        {% if lang.fluency %}<span class="fluency">— {{ lang.fluency }}</span>{% endif %}
      </li>
      {% endfor %}
    </ul>
  </section>
  {% endif %}

  {% if resume.references %}
  <section class="references">
    <h2>References</h2>
    {% for ref in resume.references %}
    <div class="reference">
      <p class="name"><strong>{{ ref.name }}</strong></p>
      <p class="quote">{{ ref.reference }}</p>
    </div>
    {% endfor %}
  </section>
  {% endif %}
</div>
'''

            template_names = [
              'Thomas Davis (JSON Resume)',
              'Thomas Davis 2 (imported)',
            ]

            for template_name in template_names:
              obj, created = ResumeTemplate.objects.update_or_create(
                name=template_name,
                defaults={
                  'category': 'imported',
                  'html_structure': html_structure,
                  'metadata': {'form_schema': schema},
                  'is_active': True,
                },
              )

              try:
                if obj.html_structure and '__TEMPLATE_ID__' in obj.html_structure:
                  obj.html_structure = (
                    obj.html_structure.replace('__TEMPLATE_ID__', str(obj.id))
                    .replace('__TID__', str(obj.id))
                    .replace('__RESUME_JSON__', json.dumps(schema))
                  )
                  obj.save(update_fields=['html_structure'])
              except Exception:
                pass

              if created:
                self.stdout.write(self.style.SUCCESS(f'Created Template: {template_name}'))
              else:
                self.stdout.write(self.style.NOTICE(f'Template already exists or updated: {template_name}'))

        # List resumes with pdf files
        try:
            Resume = apps.get_model('resume', 'Resume')
            resumes = Resume.objects.all()
            if not resumes.exists():
                self.stdout.write('No Resume records found.')
                return

            self.stdout.write('\nResumes with PDF info:')
            for r in resumes:
                pdf_field = getattr(r, 'pdf_file', None)
                pdf_path = pdf_field.path if pdf_field and hasattr(pdf_field, 'path') else None
                exists = os.path.exists(pdf_path) if pdf_path else False
                self.stdout.write(f'- {r.id} | {r.title} | pdf: {pdf_path} | exists: {exists}')
        except LookupError:
            self.stdout.write(self.style.WARNING('Resume model not found; cannot list resumes.'))
