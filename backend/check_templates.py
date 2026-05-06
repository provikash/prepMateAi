#!/usr/bin/env python
import os
import django

os.environ.setdefault("DJANGO_SETTINGS_MODULE", "core.settings")
django.setup()

from templates.models import ResumeTemplate

templates = ResumeTemplate.objects.all()
for t in templates:
    has_form_schema = "form_schema" in (t.metadata or {})
    print(f"{t.id} | {t.name} | has_form_schema: {has_form_schema}")
