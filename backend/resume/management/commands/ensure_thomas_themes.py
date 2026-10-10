from django.core.management.base import BaseCommand

from resume.json_resume import canonical_form_schema
from resume.models import ResumeTemplate


THEMES = (
    ("thomas-slate", "Thomas Slate", "Clean slate single-column layout inspired by the supplied Thomas Davis resume.", "modern"),
    ("thomas-desert-modern", "Thomas Desert Modern", "Warm editorial layout with desert tones and serif typography.", "creative"),
    ("thomas-navy-sidebar", "Thomas Navy Sidebar", "Structured two-column layout with a deep navy information sidebar.", "professional"),
)


class Command(BaseCommand):
    help = "Create or update the three trusted Thomas resume themes."

    def handle(self, *args, **options):
        for identifier, name, description, category in THEMES:
            template, created = ResumeTemplate.objects.update_or_create(
                slug=identifier,
                defaults={
                    "name": name,
                    "description": description,
                    "theme_identifier": identifier,
                    "version": 1,
                    "category": category,
                    "metadata": {"schema": "jsonresume", "form_schema": canonical_form_schema()},
                    "is_active": True,
                },
            )
            action = "Created" if created else "Updated"
            self.stdout.write(self.style.SUCCESS(f"{action} template {template.slug} v{template.version}."))
