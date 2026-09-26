from django.db import migrations, models


class Migration(migrations.Migration):
    dependencies = [("resume", "0005_resumeversion")]

    operations = [
        migrations.AddField(model_name="resumeversion", name="pdf_error_code", field=models.CharField(blank=True, default="", max_length=60)),
        migrations.AddField(model_name="resumeversion", name="pdf_generated_at", field=models.DateTimeField(blank=True, null=True)),
        migrations.AddField(model_name="resumeversion", name="pdf_status", field=models.CharField(default="NOT_REQUESTED", max_length=20)),
    ]
