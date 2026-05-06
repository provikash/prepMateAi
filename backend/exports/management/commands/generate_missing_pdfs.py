from django.core.management.base import BaseCommand
from django.db.models import Q

from resume.models import Resume
from exports.services.pdf_service import PDFExportService


class Command(BaseCommand):
    help = "Generate and save PDFs for resumes that don't have one yet."

    def handle(self, *args, **options):
        qs = Resume.objects.filter(Q(pdf_file__isnull=True) | Q(pdf_file=''))
        total = qs.count()
        self.stdout.write(f"Found {total} resumes without PDFs.")

        done = 0
        for resume in qs.select_related('user', 'template'):
            if not resume.template:
                self.stdout.write(f"Skipping {resume.id} (no template assigned)")
                continue

            try:
                pdf_bytes, updated_resume = PDFExportService.generate_pdf_bytes(resume.id, resume.user)
                # PDFExportService saves the file to resume.pdf_file when possible
                saved = bool(updated_resume.pdf_file and updated_resume.pdf_file.name)
                self.stdout.write(f"Processed {resume.id} | title: {resume.title} | saved: {saved}")
                done += 1
            except Exception as exc:
                self.stderr.write(f"Failed to generate for {resume.id}: {exc}")

        self.stdout.write(f"Done. Generated PDFs for {done} resumes.")
