from django.db import migrations, models


class Migration(migrations.Migration):
    dependencies = [("resume", "0006_resumeversion_pdf_state")]

    operations = [
        migrations.AddField(
            model_name="resume",
            name="revision",
            field=models.PositiveIntegerField(default=1),
        ),
    ]
