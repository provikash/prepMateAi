from django.db import migrations


TEMPLATE_NAME = "Professional Simple"
TEMPLATE_HTML = """<!DOCTYPE html>
<html>
<head>
    <meta charset=\"UTF-8\">
    <style>
        body {
            font-family: Arial, sans-serif;
            margin: 40px;
            color: #222;
        }

        h1 {
            font-size: 28px;
            margin-bottom: 2px;
        }

        h2 {
            font-size: 18px;
            border-bottom: 1px solid #000;
            margin-top: 20px;
            padding-bottom: 4px;
        }

        .subheading {
            font-size: 14px;
            margin-bottom: 10px;
        }

        p {
            margin: 4px 0;
        }

        .section {
            margin-bottom: 12px;
        }

        .item {
            margin-bottom: 8px;
        }

        .bold {
            font-weight: bold;
        }

        ul {
            padding-left: 18px;
        }

        .header {
            margin-bottom: 10px;
        }
    </style>
</head>

<body>

    <div class=\"header\">
        <h1>{{ resume.personal_info.name }}</h1>
        <p class=\"subheading\">{{ resume.personal_info.role }}</p>
        <p>{{ resume.personal_info.phone }} | {{ resume.personal_info.email }} | {{ resume.personal_info.linkedin }} | {{ resume.personal_info.github }}</p>
    </div>

    <div class=\"section\">
        <h2>Summary</h2>
        <p>{{ resume.personal_info.summary }}</p>
    </div>

    <div class=\"section\">
        <h2>Skills</h2>
        <ul>
            {% for skill in resume.skills %}
                <li>{{ skill }}</li>
            {% endfor %}
        </ul>
    </div>

    <div class=\"section\">
        <h2>Projects</h2>
        {% for project in resume.projects %}
            <div class=\"item\">
                <p class=\"bold\">{{ project.title }}</p>
                <p>{{ project.description }}</p>
            </div>
        {% endfor %}
    </div>

    <div class=\"section\">
        <h2>Certifications & Achievements</h2>
        <ul>
            {% for certification in resume.certifications %}
                <li>{{ certification }}</li>
            {% endfor %}
        </ul>
    </div>

    <div class=\"section\">
        <h2>Education</h2>
        {% for edu in resume.education %}
            <div class=\"item\">
                <p class=\"bold\">{{ edu.degree }}</p>
                <p>{{ edu.institution }}{% if edu.year %} | {{ edu.year }}{% endif %}</p>
            </div>
        {% endfor %}
    </div>

</body>
</html>
"""


def add_template(apps, schema_editor):
    ResumeTemplate = apps.get_model("resume", "ResumeTemplate")
    ResumeTemplate.objects.get_or_create(
        name=TEMPLATE_NAME,
        defaults={
            "html_structure": TEMPLATE_HTML,
            "is_active": True,
        },
    )


def remove_template(apps, schema_editor):
    ResumeTemplate = apps.get_model("resume", "ResumeTemplate")
    ResumeTemplate.objects.filter(name=TEMPLATE_NAME).delete()


class Migration(migrations.Migration):

    dependencies = [
        ("resume", "0009_fix_legacy_resume_uuid_values"),
    ]

    operations = [
        migrations.RunPython(add_template, remove_template),
    ]
