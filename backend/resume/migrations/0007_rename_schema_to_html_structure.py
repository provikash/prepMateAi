import django.db.models.fields.files
from django.db import migrations


class Migration(migrations.Migration):

    dependencies = [
        ("resume", "0006_resumetemplate_alter_resume_options_and_more"),
    ]

    operations = [
        migrations.RenameField(
            model_name="resumetemplate",
            old_name="schema",
            new_name="html_structure",
        ),
        migrations.AlterField(
            model_name="resumetemplate",
            name="preview_image",
            field=django.db.models.fields.files.ImageField(
                blank=True,
                null=True,
                upload_to="templates/previews/",
            ),
        ),
    ]
