from django.db import migrations


TEMPLATE_NAME = "Vikash Flutter Professional"
UPDATED_TEMPLATE_HTML = """<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8" />
    <style>
        @page {
            size: A4;
            margin: 24px 30px;
        }

        body {
            font-family: "Times New Roman", Times, serif;
            color: #111;
            line-height: 1.35;
            font-size: 13px;
        }

        .header {
            text-align: center;
            margin-bottom: 12px;
        }

        .name {
            margin: 0;
            font-size: 34px;
            line-height: 1;
            letter-spacing: 1px;
            text-transform: uppercase;
            font-weight: 700;
        }

        .role {
            margin: 4px 0 8px;
            font-size: 18px;
            line-height: 1;
            font-weight: 600;
        }

        .contact-line {
            margin: 0;
            font-size: 12px;
            line-height: 1.4;
            word-break: break-word;
        }

        .contact-line a {
            color: #111;
            text-decoration: underline;
        }

        .section {
            margin-top: 12px;
        }

        .section-title {
            margin: 0;
            font-size: 20px;
            line-height: 1.1;
            font-weight: 700;
        }

        .section-rule {
            border: none;
            border-top: 1px solid #555;
            margin: 2px 0 6px;
        }

        .summary-text {
            margin: 0;
            text-align: justify;
        }

        .skill-list {
            margin: 0;
            padding-left: 18px;
        }

        .skill-list li {
            margin: 1px 0;
        }

        .project-item {
            margin-bottom: 10px;
        }

        .project-head {
            display: table;
            width: 100%;
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
            margin: 2px 0 0 18px;
            padding: 0;
            list-style: none;
        }

        .project-bullets li {
            margin: 1px 0;
            position: relative;
            padding-left: 12px;
            text-align: justify;
        }

        .project-bullets li:before {
            content: "-";
            position: absolute;
            left: 0;
        }

        .project-description {
            margin: 3px 0 0 18px;
            text-align: justify;
        }

        .source-line {
            margin: 2px 0 0 18px;
        }

        .source-line a {
            color: #111;
            text-decoration: underline;
        }

        .cert-list {
            margin: 0;
            padding-left: 18px;
        }

        .cert-list li {
            margin: 2px 0;
            text-align: justify;
        }

        .cert-title {
            font-weight: 700;
        }

        .edu-item {
            margin-bottom: 6px;
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
            {% if resume.personal_info.phone %}<span>{{ resume.personal_info.phone }}</span>{% endif %}
            {% if resume.personal_info.email %}<span> | <a href="mailto:{{ resume.personal_info.email }}">{{ resume.personal_info.email }}</a></span>{% endif %}
            {% if resume.personal_info.linkedin_url %}<span> | LinkedIn: <a href="{{ resume.personal_info.linkedin_url }}">{{ resume.personal_info.linkedin|default:resume.personal_info.linkedin_url }}</a></span>{% endif %}
            {% if resume.personal_info.github_url %}<span> | GitHub: <a href="{{ resume.personal_info.github_url }}">{{ resume.personal_info.github|default:resume.personal_info.github_url }}</a></span>{% endif %}
        </p>
    </div>

    {% if resume.has_summary %}
        <div class="section">
            <h2 class="section-title">Summary</h2>
            <hr class="section-rule" />
            <p class="summary-text">{{ resume.personal_info.summary }}</p>
        </div>
    {% endif %}

    {% if resume.has_skills %}
        <div class="section">
            <h2 class="section-title">Skills</h2>
            <hr class="section-rule" />
            <ul class="skill-list">
                {% if resume.skill_groups.programming_languages %}<li><strong>Programming Languages:</strong> {{ resume.skill_groups.programming_languages }}</li>{% endif %}
                {% if resume.skill_groups.mobile_framework %}<li><strong>Mobile Framework:</strong> {{ resume.skill_groups.mobile_framework }}</li>{% endif %}
                {% if resume.skill_groups.architecture %}<li><strong>State Management & Architecture:</strong> {{ resume.skill_groups.architecture }}</li>{% endif %}
                {% if resume.skill_groups.ui_ux %}<li><strong>UI/UX & Frontend Capabilities:</strong> {{ resume.skill_groups.ui_ux }}</li>{% endif %}
                {% if resume.skill_groups.tools %}<li><strong>Tools & Infrastructure:</strong> {{ resume.skill_groups.tools }}</li>{% endif %}
                {% if resume.skills and not resume.skill_groups.programming_languages and not resume.skill_groups.mobile_framework and not resume.skill_groups.architecture and not resume.skill_groups.ui_ux and not resume.skill_groups.tools %}
                    <li>{{ resume.skills|join:", " }}</li>
                {% endif %}
            </ul>
        </div>
    {% endif %}

    {% if resume.has_projects %}
        <div class="section">
            <h2 class="section-title">Projects</h2>
            <hr class="section-rule" />
            {% for project in resume.projects %}
                <div class="project-item">
                    <div class="project-head">
                        <div class="project-title-wrap">
                            {% if project.title %}<span class="project-title">{{ project.title }}</span>{% endif %}
                            {% if project.stack %}<span> | </span><span class="project-stack">{{ project.stack }}</span>{% endif %}
                        </div>
                        {% if project.date_range %}<div class="project-date">{{ project.date_range }}</div>{% endif %}
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
    {% endif %}

    {% if resume.has_certifications %}
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
    {% endif %}

    {% if resume.has_education %}
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
    {% endif %}
</body>
</html>
"""


def set_updated_template(apps, schema_editor):
    ResumeTemplate = apps.get_model("resume", "ResumeTemplate")
    ResumeTemplate.objects.filter(name=TEMPLATE_NAME).update(html_structure=UPDATED_TEMPLATE_HTML)


class Migration(migrations.Migration):
    dependencies = [
        ("resume", "0012_update_vikash_template_quality"),
    ]

    operations = [
        migrations.RunPython(set_updated_template, migrations.RunPython.noop),
    ]
