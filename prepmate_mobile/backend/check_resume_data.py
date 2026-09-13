#!/usr/bin/env python
import os
import django
import json

os.environ.setdefault("DJANGO_SETTINGS_MODULE", "core.settings")
django.setup()

from resume.models import Resume

resumes = Resume.objects.filter(data__isnull=False).exclude(data={})[:3]
for r in resumes:
    print(f"\n=== Resume: {r.title} ===")
    print(f"ID: {r.id}")
    print(f"Template: {r.template}")
    if isinstance(r.data, dict):
        print(f"Data keys: {list(r.data.keys())}")
        personal_info = r.data.get("personal_info", {})
        print(f"Personal Info: {personal_info}")
    else:
        print(f"Data is not a dict: {type(r.data)}")
