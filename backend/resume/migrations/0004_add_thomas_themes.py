from django.db import migrations


THEMES = (
    ("thomas-slate", "Thomas Slate", "Clean slate single-column layout inspired by the supplied Thomas Davis resume.", "modern"),
    ("thomas-desert-modern", "Thomas Desert Modern", "Warm editorial layout with desert tones and serif typography.", "creative"),
    ("thomas-navy-sidebar", "Thomas Navy Sidebar", "Structured two-column layout with a deep navy information sidebar.", "professional"),
)


def add_themes(apps, schema_editor):
    template_model = apps.get_model("resume", "ResumeTemplate")
    for identifier, name, description, category in THEMES:
        template_model.objects.update_or_create(
            slug=identifier,
            defaults={
                "name": name,
                "description": description,
                "theme_identifier": identifier,
                "version": 1,
                "category": category,
                "html_structure": "",
                "css": "",
                "metadata": {"schema": "jsonresume"},
                "is_active": True,
            },
        )


def remove_themes(apps, schema_editor):
    apps.get_model("resume", "ResumeTemplate").objects.filter(
        slug__in=[item[0] for item in THEMES]
    ).delete()


class Migration(migrations.Migration):
    dependencies = [("resume", "0003_template_theme_fields_resume_version")]
    operations = [migrations.RunPython(add_themes, remove_themes)]
