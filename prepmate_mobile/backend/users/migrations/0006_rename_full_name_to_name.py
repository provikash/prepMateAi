from django.db import migrations


class Migration(migrations.Migration):

    dependencies = [
        ("users", "0005_alter_user_full_name"),
    ]

    operations = [
        migrations.RenameField(
            model_name="user",
            old_name="full_name",
            new_name="name",
        ),
    ]