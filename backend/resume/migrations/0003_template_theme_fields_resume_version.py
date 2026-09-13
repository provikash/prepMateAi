from django.db import migrations, models
from django.utils.text import slugify


def populate_slugs(apps, schema_editor):
    Template = apps.get_model("resume", "ResumeTemplate")
    used = set()
    for item in Template.objects.order_by("created_at", "pk"):
        base = slugify(item.name) or f"template-{item.pk}"
        slug = base
        suffix = 2
        while slug in used or Template.objects.exclude(pk=item.pk).filter(slug=slug).exists():
            slug = f"{base}-{suffix}"
            suffix += 1
        item.slug = slug
        item.theme_identifier = "professional"
        item.save(update_fields=["slug", "theme_identifier"])
        used.add(slug)

    if not Template.objects.filter(theme_identifier="professional", version=1).exists():
        Template.objects.create(
            name="Professional",
            slug="professional",
            description="Professional single-column JSON Resume layout.",
            theme_identifier="professional",
            version=1,
            category="professional",
            html_structure="",
            css="",
            metadata={"schema": "jsonresume"},
            is_active=True,
        )

    Resume = apps.get_model("resume", "Resume")
    for resume in Resume.objects.select_related("template"):
        resume.template_version = resume.template.version if resume.template_id else 1
        resume.save(update_fields=["template_version"])


class Migration(migrations.Migration):
    dependencies = [("resume", "0002_resumetemplate_alter_resume_options_and_more")]
    operations = [
        migrations.AddField(model_name="resumetemplate", name="description", field=models.TextField(blank=True, default="")),
        migrations.AddField(model_name="resumetemplate", name="slug", field=models.SlugField(blank=True, max_length=120, null=True)),
        migrations.AddField(model_name="resumetemplate", name="theme_identifier", field=models.SlugField(default="professional", max_length=120)),
        migrations.AddField(model_name="resumetemplate", name="version", field=models.PositiveIntegerField(default=1)),
        migrations.AddField(model_name="resume", name="template_version", field=models.PositiveIntegerField(default=1)),
        migrations.RunPython(populate_slugs, migrations.RunPython.noop),
        migrations.AlterField(model_name="resumetemplate", name="slug", field=models.SlugField(max_length=120, unique=True)),
        migrations.AlterField(model_name="resume", name="data", field=models.JSONField(default=dict)),
    ]
