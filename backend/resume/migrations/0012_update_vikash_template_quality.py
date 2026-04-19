from django.db import migrations


TEMPLATE_NAME = "Vikash Flutter Professional"
UPDATED_TEMPLATE_HTML = """<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8" />
    <style>
        @page {
            size: A4;
            margin: 26px 34px;
        }

        body {
            font-family: "Times New Roman", Times, serif;
            color: #111;
            line-height: 1.25;
            font-size: 15px;
        }

        .header {
            text-align: center;
            margin-bottom: 12px;
        }

        .name {
            margin: 0;
            font-size: 40px;
            line-height: 1;
            letter-spacing: 1px;
            text-transform: uppercase;
            font-weight: 400;
        }

        .role {
            margin: 2px 0 8px;
            font-size: 24px;
            line-height: 1;
            font-weight: 700;
        }

        .contact-line {
            font-size: 14px;
            margin: 0;
        }

        .contact-line a {
            color: #111;
            text-decoration: underline;
        }

        .section {
            margin-top: 14px;
        }

        .section-title {
            margin: 0;
            font-size: 28px;
            line-height: 1.05;
            font-weight: 700;
        }

        .section-rule {
            border: none;
            border-top: 1px solid #555;
            margin: 2px 0 6px;
        }

        .summary-text {
            margin: 0;
            line-height: 1.35;
            text-align: justify;
        }

        .skill-line {
            margin: 0;
        }

        .skill-label {
            font-weight: 700;
        }

        .project-item {
            margin-bottom: 10px;
        }

        .project-head {
            display: table;
            width: 100%;
            margin-bottom: 2px;
        }

        .project-title-wrap,
        .project-date {
            display: table-cell;
            vertical-align: top;
        }

        .project-title-wrap {
            width: 72%;
            padding-right: 10px;
        }

        .project-title {
            font-weight: 700;
        }

        .project-stack {
            font-style: italic;
            color: #222;
        }

        .project-date {
            width: 28%;
            text-align: right;
            font-weight: 700;
        }

        .project-bullets {
            margin: 0 0 0 18px;
            padding: 0;
            list-style: none;
        }

        .project-bullets li {
            margin: 1px 0;
            position: relative;
            padding-left: 14px;
            text-align: justify;
        }

        .project-bullets li:before {
            content: "-";
            position: absolute;
            left: 0;
        }

        .project-description {
            margin: 2px 0 0 18px;
            text-align: justify;
        }

        .source-line {
            margin-left: 18px;
            margin-top: 2px;
        }

        .source-line a {
            color: #111;
            text-decoration: underline;
        }

        .cert-list {
            margin: 0 0 0 22px;
            padding: 0;
        }

        .cert-list li {
            margin: 5px 0;
            text-align: justify;
        }

        .cert-title {
            font-weight: 700;
        }

        .edu-item {
            margin-bottom: 5px;
        }

        .edu-head {
            display: table;
            width: 100%;
        }

        .edu-degree,
        .edu-year {
            display: table-cell;
            vertical-align: top;
        }

        .edu-degree {
            width: 70%;
            font-weight: 700;
        }

        .edu-year {
            width: 30%;
            text-align: right;
            font-weight: 700;
        }

        .edu-subhead {
            display: table;
            width: 100%;
            font-style: italic;
            color: #222;
        }

        .edu-school,
        .edu-location {
            display: table-cell;
            vertical-align: top;
        }

        .edu-school {
            width: 70%;
        }

        .edu-location {
            width: 30%;
            text-align: right;
        }
    </style>
</head>
<body>
    <div class="header">
        <h1 class="name">{{ resume.personal_info.name }}</h1>
        {% if resume.personal_info.role %}<p class="role">{{ resume.personal_info.role }}</p>{% endif %}
        <p class="contact-line">
            {{ resume.personal_info.phone }}
            {% if resume.personal_info.email %} | <a href="mailto:{{ resume.personal_info.email }}">{{ resume.personal_info.email }}</a>{% endif %}
            {% if resume.personal_info.linkedin_url %} | LinkedIn: <a href="{{ resume.personal_info.linkedin_url }}">{{ resume.personal_info.linkedin|default:resume.personal_info.linkedin_url }}</a>{% endif %}
            {% if resume.personal_info.github_url %} | GitHub: <a href="{{ resume.personal_info.github_url }}">{{ resume.personal_info.github|default:resume.personal_info.github_url }}</a>{% endif %}
        </p>
    </div>

    <div class="section">
        <h2 class="section-title">Summary</h2>
        <hr class="section-rule" />
        <p class="summary-text">{{ resume.personal_info.summary }}</p>
    </div>

    <div class="section">
        <h2 class="section-title">Skills</h2>
        <hr class="section-rule" />
        <p class="skill-line"><span class="skill-label">Programming Languages:</span> {{ resume.skill_groups.programming_languages }}</p>
        <p class="skill-line"><span class="skill-label">Mobile Framework:</span> {{ resume.skill_groups.mobile_framework }}</p>
        <p class="skill-line"><span class="skill-label">State Management & Architecture:</span> {{ resume.skill_groups.architecture }}</p>
        <p class="skill-line"><span class="skill-label">UI/UX & Frontend Capabilities:</span> {{ resume.skill_groups.ui_ux }}</p>
        <p class="skill-line"><span class="skill-label">Tools & Infrastructure:</span> {{ resume.skill_groups.tools }}</p>
    </div>

    <div class="section">
        <h2 class="section-title">Projects</h2>
        <hr class="section-rule" />
        {% for project in resume.projects %}
            <div class="project-item">
                <div class="project-head">
                    <div class="project-title-wrap">
                        <span class="project-title">{{ project.title }}</span>
                        {% if project.stack %}<span> | </span><span class="project-stack">{{ project.stack }}</span>{% endif %}
                    </div>
                    <div class="project-date">{{ project.date_range }}</div>
                </div>

                {% if project.bullets %}
                    <ul class="project-bullets">
                        {% for bullet in project.bullets %}
                            <li>{{ bullet }}</li>
                        {% endfor %}
                    </ul>
                {% elif project.description %}
                    <p class="project-description">{{ project.description }}</p>
                {% endif %}

                {% if project.source_code %}
                    <p class="source-line">Source Code: <a href="{{ project.source_code }}">{{ project.source_code }}</a></p>
                {% endif %}
            </div>
        {% endfor %}
    </div>

    <div class="section">
        <h2 class="section-title">Certifications & Achievements</h2>
        <hr class="section-rule" />
        <ul class="cert-list">
            {% for cert in resume.certifications %}
                <li>
                    <span class="cert-title">{{ cert.title }}</span>
                    {% if cert.description %}: {{ cert.description }}{% endif %}
                </li>
            {% endfor %}
        </ul>
    </div>

    <div class="section">
        <h2 class="section-title">Education</h2>
        <hr class="section-rule" />
        {% for edu in resume.education %}
            <div class="edu-item">
                <div class="edu-head">
                    <div class="edu-degree">{{ edu.degree }}</div>
                    <div class="edu-year">{{ edu.year }}</div>
                </div>
                {% if edu.institution or edu.location %}
                    <div class="edu-subhead">
                        <div class="edu-school">{{ edu.institution }}</div>
                        <div class="edu-location">{{ edu.location }}</div>
                    </div>
                {% endif %}
            </div>
        {% endfor %}
    </div>
</body>
</html>
"""


def set_updated_template(apps, schema_editor):
    ResumeTemplate = apps.get_model("resume", "ResumeTemplate")
    ResumeTemplate.objects.filter(name=TEMPLATE_NAME).update(html_structure=UPDATED_TEMPLATE_HTML)


class Migration(migrations.Migration):
    dependencies = [
        ("resume", "0011_add_vikash_flutter_template"),
    ]

    operations = [
        migrations.RunPython(set_updated_template, migrations.RunPython.noop),
    ]
