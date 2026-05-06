from django.core.management.base import BaseCommand
import os
import json


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
