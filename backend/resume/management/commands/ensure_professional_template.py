from django.core.management.base import BaseCommand

from resume.models import ResumeTemplate
from resume.json_resume import canonical_form_schema


class Command(BaseCommand):
    help = "Create or update the trusted Professional JSON Resume template metadata."

    def handle(self, *args, **options):
        template, created = ResumeTemplate.objects.update_or_create(
            slug="professional",
            defaults={
                "name": "Professional",
                "description": "Professional single-column JSON Resume layout.",
                "theme_identifier": "professional",
                "version": 1,
                "category": "professional",
                "metadata": {"schema": "jsonresume", "form_schema": canonical_form_schema()},
                "is_active": True,
            },
        )
        self.stdout.write(self.style.SUCCESS(f"{'Created' if created else 'Updated'} template {template.slug} v{template.version}."))
