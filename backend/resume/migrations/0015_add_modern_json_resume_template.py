from django.db import migrations


TEMPLATE_NAME = "Modern JSON Resume"
TEMPLATE_CATEGORY = "general"
TEMPLATE_HTML = """<!DOCTYPE html>
<html>
<head>
    <meta charset=\"UTF-8\" />
    <style>
        @page {
            size: A4;
            margin: 24px;
        }

        body {
            font-family: Arial, sans-serif;
            color: #1f2937;
            font-size: 12px;
            line-height: 1.4;
        }

        .header {
            border-bottom: 2px solid #e5e7eb;
            margin-bottom: 12px;
            padding-bottom: 10px;
        }

        h1 {
            margin: 0;
            font-size: 28px;
        }

        .tagline {
            margin: 2px 0 8px;
            font-size: 14px;
            color: #374151;
        }

        .contact {
            margin: 0;
            word-break: break-word;
        }

        h2 {
            margin: 14px 0 6px;
            font-size: 15px;
            border-bottom: 1px solid #e5e7eb;
            padding-bottom: 3px;
            color: #111827;
        }

        .item {
            margin-bottom: 8px;
        }

        .title-row {
            display: table;
            width: 100%;
        }

        .left,
        .right {
            display: table-cell;
            vertical-align: top;
        }

        .right {
            text-align: right;
            color: #4b5563;
        }

        ul {
            margin: 4px 0 0 16px;
            padding: 0;
        }

        li {
            margin: 2px 0;
        }

        .muted {
            color: #4b5563;
        }
    </style>
</head>
<body>
    <div class=\"header\">
        <h1>{{ personal_info.name }}</h1>
        {% if personal_info.tagline %}<p class=\"tagline\">{{ personal_info.tagline }}</p>{% endif %}
        <p class=\"contact\">
            {% if personal_info.email %}{{ personal_info.email }}{% endif %}
            {% if personal_info.phone %} | {{ personal_info.phone }}{% endif %}
            {% if personal_info.linkedin %} | {{ personal_info.linkedin }}{% endif %}
            {% if personal_info.github %} | {{ personal_info.github }}{% endif %}
        </p>
    </div>

    {% if personal_info.summary %}
    <h2>Summary</h2>
    <p>{{ personal_info.summary }}</p>
    {% endif %}

    {% if skills %}
    <h2>Skills</h2>
    <ul>
        {% for skill in skills %}
            <li>{{ skill }}</li>
        {% endfor %}
    </ul>
    {% endif %}

    {% if experience %}
    <h2>Experience</h2>
    {% for item in experience %}
        <div class=\"item\">
            <div class=\"title-row\">
                <div class=\"left\"><strong>{{ item.role }}</strong> at {{ item.company }}</div>
                <div class=\"right\">{{ item.duration }}</div>
            </div>
            {% if item.location %}<div class=\"muted\">{{ item.location }}</div>{% endif %}
            {% if item.details %}
                <ul>
                    {% for detail in item.details %}
                        <li>{{ detail }}</li>
                    {% endfor %}
                </ul>
            {% endif %}
        </div>
    {% endfor %}
    {% endif %}

    {% if projects %}
    <h2>Projects</h2>
    <ul>
        {% for project in projects %}
            <li>{{ project.title|default:project }}</li>
        {% endfor %}
    </ul>
    {% endif %}

    {% if education %}
    <h2>Education</h2>
    {% for item in education %}
        <div class=\"item\">
            <div class=\"title-row\">
                <div class=\"left\"><strong>{{ item.degree }}</strong>, {{ item.institution }}</div>
                <div class=\"right\">{{ item.duration|default:item.year }}</div>
            </div>
            {% if item.details %}
                <ul>
                    {% for detail in item.details %}
                        <li>{{ detail }}</li>
                    {% endfor %}
                </ul>
            {% endif %}
        </div>
    {% endfor %}
    {% endif %}

    {% if awards %}
    <h2>Awards</h2>
    <ul>
        {% for award in awards %}
            <li>{{ award }}</li>
        {% endfor %}
    </ul>
    {% endif %}

    {% if languages %}
    <h2>Languages</h2>
    <ul>
        {% for language in languages %}
            <li>{{ language.name }}{% if language.level %} - {{ language.level }}{% endif %}</li>
        {% endfor %}
    </ul>
    {% endif %}
</body>
</html>
"""


FORM_SCHEMA = {
    "sections": [
        {
            "title": "Personal Information",
            "fields": [
                {"key": "personal_info.name", "label": "Full Name", "type": "text"},
                {"key": "personal_info.tagline", "label": "Tagline", "type": "text"},
                {"key": "personal_info.email", "label": "Email", "type": "text"},
                {"key": "personal_info.phone", "label": "Phone", "type": "text"},
                {"key": "personal_info.linkedin", "label": "LinkedIn", "type": "text"},
                {"key": "personal_info.github", "label": "GitHub", "type": "text"},
                {"key": "personal_info.summary", "label": "Summary", "type": "text"},
            ],
        },
        {
            "title": "Skills",
            "fields": [
                {"key": "skills", "label": "Skills", "type": "list"},
            ],
        },
        {
            "title": "Experience",
            "fields": [
                {
                    "key": "experience",
                    "label": "Experience",
                    "type": "list_object",
                    "item_fields": [
                        {"key": "role", "label": "Role"},
                        {"key": "company", "label": "Company"},
                        {"key": "duration", "label": "Duration"},
                        {"key": "location", "label": "Location"},
                        {"key": "details", "label": "Details (one per line)"},
                    ],
                },
            ],
        },
        {
            "title": "Projects",
            "fields": [
                {"key": "projects", "label": "Projects", "type": "list"},
            ],
        },
        {
            "title": "Education",
            "fields": [
                {
                    "key": "education",
                    "label": "Education",
                    "type": "list_object",
                    "item_fields": [
                        {"key": "degree", "label": "Degree"},
                        {"key": "institution", "label": "Institution"},
                        {"key": "duration", "label": "Duration"},
                        {"key": "details", "label": "Details (one per line)"},
                    ],
                },
            ],
        },
        {
            "title": "Awards",
            "fields": [
                {"key": "awards", "label": "Awards", "type": "list"},
            ],
        },
        {
            "title": "Languages",
            "fields": [
                {
                    "key": "languages",
                    "label": "Languages",
                    "type": "list_object",
                    "item_fields": [
                        {"key": "name", "label": "Language"},
                        {"key": "level", "label": "Level"},
                    ],
                },
            ],
        },
    ]
}


def add_template(apps, schema_editor):
    ResumeTemplate = apps.get_model("resume", "ResumeTemplate")
    ResumeTemplate.objects.update_or_create(
        name=TEMPLATE_NAME,
        defaults={
            "category": TEMPLATE_CATEGORY,
            "html_structure": TEMPLATE_HTML,
            "css": "",
            "metadata": {"form_schema": FORM_SCHEMA},
            "is_active": True,
        },
    )


def remove_template(apps, schema_editor):
    ResumeTemplate = apps.get_model("resume", "ResumeTemplate")
    ResumeTemplate.objects.filter(name=TEMPLATE_NAME).delete()


class Migration(migrations.Migration):

    dependencies = [
        ("resume", "0014_resume_metadata_resume_pdf_file_resume_thumbnail_and_more"),
    ]

    operations = [
        migrations.RunPython(add_template, remove_template),
    ]
