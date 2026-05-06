from django.db import migrations
import json
import os


def create_thomas_template(apps, schema_editor):
    # ✅ FIXED MODEL LOADING
    ResumeTemplate = None
    try:
        ResumeTemplate = apps.get_model('resume', 'ResumeTemplate')
    except LookupError:
        try:
            ResumeTemplate = apps.get_model('templates', 'ResumeTemplate')
        except LookupError:
            return  # exit if model not found

    # ✅ FIXED PATH
    base_dir = os.path.dirname(__file__)
    fixtures_dir = os.path.join(os.path.dirname(base_dir), 'fixtures')
    schema_path = os.path.join(fixtures_dir, 'thomas_resume_schema.json')

    try:
        with open(schema_path, 'r', encoding='utf-8') as f:
            schema = json.load(f)
    except FileNotFoundError:
        schema = {}

    # ✅ CLEAN + PRODUCTION READY HTML
    html_structure = """
<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8" />
<style>
body { font-family: Arial, sans-serif; margin: 30px; color: #111; }
h1 { font-size: 28px; margin-bottom: 5px; }
h2 { margin-top: 25px; border-bottom: 1px solid #ccc; padding-bottom: 5px; }
.contact { font-size: 14px; margin-bottom: 15px; }
.section { margin-bottom: 15px; }
.item { margin-bottom: 10px; }
.title { font-weight: bold; }
.date { float: right; font-size: 12px; }
ul { margin: 5px 0 0 20px; }
</style>
</head>

<body>

<h1>{{ resume.basics.name }}</h1>

<div class="contact">
  {% if resume.basics.location.city %}
    {{ resume.basics.location.city }}
  {% endif %}

  {% if resume.basics.email %}
    | {{ resume.basics.email }}
  {% endif %}

  {% if resume.basics.phone %}
    | {{ resume.basics.phone }}
  {% endif %}

  <br>

  {% if resume.basics.website %}
    <a href="{{ resume.basics.website }}">{{ resume.basics.website }}</a>
  {% endif %}

  {% if resume.basics.profiles %}
    |
    {% for p in resume.basics.profiles %}
      <a href="{{ p.url }}">{{ p.network }}</a>{% if not forloop.last %} | {% endif %}
    {% endfor %}
  {% endif %}
</div>


<!-- SUMMARY -->
{% if resume.basics.summary %}
<div class="section">
  <h2>Summary</h2>
  <p>{{ resume.basics.summary }}</p>
</div>
{% endif %}


<!-- EXPERIENCE -->
{% if resume.work %}
<div class="section">
  <h2>Experience</h2>
  {% for w in resume.work %}
    <div class="item">
      <div class="title">
        {{ w.position }} - {{ w.name }}
        <span class="date">{{ w.startDate }} - {{ w.endDate }}</span>
      </div>

      {% if w.summary %}
        <p>{{ w.summary }}</p>
      {% endif %}

      {% if w.highlights %}
        <ul>
          {% for h in w.highlights %}
            <li>{{ h }}</li>
          {% endfor %}
        </ul>
      {% endif %}
    </div>
  {% endfor %}
</div>
{% endif %}


<!-- PROJECTS -->
{% if resume.projects %}
<div class="section">
  <h2>Projects</h2>
  {% for p in resume.projects %}
    <div class="item">
      <div class="title">
        {{ p.name }}
        <span class="date">{{ p.startDate }}</span>
      </div>

      {% if p.description %}
        <p>{{ p.description }}</p>
      {% endif %}
    </div>
  {% endfor %}
</div>
{% endif %}


<!-- EDUCATION -->
{% if resume.education %}
<div class="section">
  <h2>Education</h2>
  {% for e in resume.education %}
    <div class="item">
      <div class="title">
        {{ e.studyType }} - {{ e.institution }}
        <span class="date">{{ e.endDate }}</span>
      </div>
    </div>
  {% endfor %}
</div>
{% endif %}


<!-- SKILLS -->
{% if resume.skills %}
<div class="section">
  <h2>Skills</h2>
  {% for s in resume.skills %}
    <p>
      <strong>{{ s.name }}:</strong>
      {% for k in s.keywords %}
        {{ k }}{% if not forloop.last %}, {% endif %}
      {% endfor %}
    </p>
  {% endfor %}
</div>
{% endif %}

</body>
</html>
"""

    # ✅ FIXED STORAGE FORMAT
    obj, created = ResumeTemplate.objects.update_or_create(
        name='Thomas Davis (JSON Resume)',
        defaults={
            'description': 'JSON Resume Template',
            'html_structure': html_structure,
            'form_schema': schema,  # ✅ DIRECT (IMPORTANT)
            'is_active': True,
        },
    )


def delete_thomas_template(apps, schema_editor):
    ResumeTemplate = apps.get_model('resume', 'ResumeTemplate')
    ResumeTemplate.objects.filter(name='Thomas Davis (JSON Resume)').delete()


class Migration(migrations.Migration):

    dependencies = [
        ("resume", "0001_initial"),
    ]

    operations = [
        migrations.RunPython(create_thomas_template, delete_thomas_template),
    ]