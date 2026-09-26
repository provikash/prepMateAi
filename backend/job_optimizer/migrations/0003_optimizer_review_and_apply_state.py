from django.db import migrations, models


class Migration(migrations.Migration):
    dependencies = [("job_optimizer", "0002_optimizationsession_final_analysis_json_and_more")]

    operations = [
        migrations.AddField(model_name="optimizationsession", name="apply_idempotency_key", field=models.CharField(blank=True, default="", max_length=100)),
        migrations.AddField(model_name="optimizationsession", name="failed_at", field=models.DateTimeField(blank=True, null=True)),
        migrations.AddField(model_name="optimizationsession", name="failure_code", field=models.CharField(blank=True, default="", max_length=60)),
        migrations.AddField(model_name="optimizationsession", name="failure_message", field=models.CharField(blank=True, default="", max_length=255)),
        migrations.AddField(model_name="optimizationsession", name="request_id", field=models.CharField(blank=True, default="", max_length=100)),
        migrations.AddField(model_name="optimizationsession", name="source_resume_updated_at", field=models.DateTimeField(blank=True, null=True)),
        migrations.AlterField(model_name="optimizationsession", name="status", field=models.CharField(choices=[("DRAFT", "Draft"), ("ANALYZING", "Analyzing"), ("ANALYZED", "Analyzed"), ("MATCHING", "Matching"), ("READY_FOR_REVIEW", "Ready for Review"), ("APPLYING", "Applying"), ("GENERATING_PDF", "Generating PDF"), ("COMPLETED", "Completed"), ("FAILED", "Failed"), ("CANCELLED", "Cancelled")], db_index=True, default="DRAFT", max_length=30)),
        migrations.AddField(model_name="optimizationsuggestion", name="applied_at", field=models.DateTimeField(blank=True, null=True)),
        migrations.AddField(model_name="optimizationsuggestion", name="decision_version", field=models.PositiveIntegerField(default=1)),
        migrations.AddField(model_name="optimizationsuggestion", name="requires_confirmation", field=models.BooleanField(default=False)),
        migrations.AddField(model_name="optimizationsuggestion", name="severity", field=models.CharField(default="MEDIUM", max_length=20)),
        migrations.AddField(model_name="optimizationsuggestion", name="target_child_id", field=models.UUIDField(blank=True, null=True)),
        migrations.AddField(model_name="optimizationsuggestion", name="target_field", field=models.CharField(blank=True, default="", max_length=80)),
        migrations.AddField(model_name="optimizationsuggestion", name="target_item_id", field=models.UUIDField(blank=True, null=True)),
        migrations.AddField(model_name="optimizationsuggestion", name="target_section", field=models.CharField(blank=True, default="", max_length=40)),
        migrations.AlterField(model_name="optimizationsuggestion", name="status", field=models.CharField(choices=[("PENDING", "Pending"), ("ACCEPTED", "Accepted"), ("REJECTED", "Rejected"), ("EDITED", "Edited"), ("APPLIED", "Applied"), ("STALE", "Stale")], db_index=True, default="PENDING", max_length=20)),
        migrations.AddConstraint(model_name="optimizationsession", constraint=models.UniqueConstraint(condition=~models.Q(("request_id", "")), fields=("user", "request_id"), name="unique_user_optimizer_request_id")),
    ]
