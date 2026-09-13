#!/usr/bin/env python
import os
import django
import json

os.environ.setdefault("DJANGO_SETTINGS_MODULE", "core.settings")
django.setup()

from templates.models import ResumeTemplate

templates = ResumeTemplate.objects.all()
print("=== All Templates ===")
for t in templates:
    if t.metadata and "form_schema" in t.metadata:
        schema = t.metadata["form_schema"]
        sections = schema.get("sections", [])
        print(f"\n{t.name}")
        print(f"  Sections ({len(sections)}):")
        for section in sections:
            print(f"    - {section.get('title')} (key: {section.get('key')})")
    else:
        print(f"\n{t.name} - NO FORM SCHEMA")
