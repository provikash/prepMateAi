import uuid

from django.db import migrations


def _to_uuid_hex(value):
    try:
        return uuid.UUID(str(value)).hex
    except (ValueError, TypeError, AttributeError):
        return None


def fix_legacy_resume_uuid_values(apps, schema_editor):
    connection = schema_editor.connection

    with connection.cursor() as cursor:
        cursor.execute("SELECT id FROM resume_resumetemplate")
        raw_template_ids = [row[0] for row in cursor.fetchall()]

        template_ids = set()
        for template_id in raw_template_ids:
            normalized = _to_uuid_hex(template_id)
            if normalized:
                template_ids.add(normalized)

        cursor.execute("SELECT id, template_id FROM resume_resume")
        resume_rows = cursor.fetchall()

        used_resume_ids = set()
        for row_id, _ in resume_rows:
            normalized = _to_uuid_hex(row_id)
            if normalized:
                used_resume_ids.add(normalized)

        for row_id, template_id in resume_rows:
            current_row_id_hex = _to_uuid_hex(row_id)
            new_row_id_hex = current_row_id_hex

            if not current_row_id_hex:
                candidate = uuid.uuid4().hex
                while candidate in used_resume_ids:
                    candidate = uuid.uuid4().hex
                new_row_id_hex = candidate
                used_resume_ids.add(new_row_id_hex)

            new_template_id_hex = None
            if template_id is not None:
                normalized_template = _to_uuid_hex(template_id)
                if normalized_template and normalized_template in template_ids:
                    new_template_id_hex = normalized_template

            if new_row_id_hex != row_id or new_template_id_hex != template_id:
                cursor.execute(
                    "UPDATE resume_resume SET id = %s, template_id = %s WHERE id = %s",
                    [new_row_id_hex, new_template_id_hex, row_id],
                )


class Migration(migrations.Migration):

    dependencies = [
        ("resume", "0008_alter_resumetemplate_html_structure"),
    ]

    operations = [
        migrations.RunPython(fix_legacy_resume_uuid_values, migrations.RunPython.noop),
    ]
