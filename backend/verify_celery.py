#!/usr/bin/env python
"""
Verify Celery configuration and task registration.
Run from backend directory: python verify_celery.py
"""

import os
import django

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'core.settings')
django.setup()

from core.celery import app as celery_app
from ai.tasks import (
    generate_summary_task,
    improve_section_task,
    suggest_skills_task,
    generate_bullets_task,
)

def check_celery_status():
    """Check if Celery is properly configured."""
    print("\n" + "="*60)
    print("CELERY CONFIGURATION CHECK")
    print("="*60)
    
    # Check broker
    print(f"\n✓ Celery App: {celery_app}")
    print(f"✓ Broker URL: {celery_app.conf.broker_url}")
    print(f"✓ Backend: {celery_app.conf.result_backend}")
    
    # Check task registration
    print("\n" + "-"*60)
    print("REGISTERED TASKS:")
    print("-"*60)
    
    tasks = [
        ('generate_summary_task', generate_summary_task),
        ('improve_section_task', improve_section_task),
        ('suggest_skills_task', suggest_skills_task),
        ('generate_bullets_task', generate_bullets_task),
    ]
    
    for name, task in tasks:
        has_delay = hasattr(task, 'delay')
        status = "✓ OK (Celery)" if has_delay else "⚠ WARN (Sync)"
        print(f"{status}: {name}")
        print(f"  Type: {type(task)}")
        print(f"  Has .delay(): {has_delay}")
        if hasattr(task, 'name'):
            print(f"  Task name: {task.name}")
    
    # Check if all tasks are in registered tasks
    print("\n" + "-"*60)
    print("ALL REGISTERED TASKS IN CELERY:")
    print("-"*60)
    for task_name in sorted(celery_app.tasks.keys()):
        if task_name.startswith('ai.'):
            print(f"  ✓ {task_name}")
    
    print("\n" + "="*60)
    print("✓ CELERY VERIFICATION COMPLETE")
    print("="*60 + "\n")

if __name__ == '__main__':
    check_celery_status()
