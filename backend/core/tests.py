import os
import tempfile
from io import StringIO
from pathlib import Path
from types import SimpleNamespace
from unittest.mock import patch
from django.core import signing
from django.core.management import call_command
from django.core.management.base import CommandError
from django.test import TestCase, override_settings
from django.core.files.storage import storages
from .media import media_url


class MediaAndHealthTests(TestCase):
    def test_health_checks_database(self):
        response = self.client.get('/health/')
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.json()["checks"], {"database": "ok", "cache": "ok"})
        with patch('core.health.connection.cursor', side_effect=RuntimeError('database-secret')):
            response = self.client.get('/health/')
        self.assertEqual(response.status_code, 503)
        self.assertNotIn('database-secret', response.content.decode())

    def test_health_checks_cache_and_exposes_separate_liveness(self):
        with patch("core.health.cache.set", side_effect=RuntimeError("cache-secret")):
            response = self.client.get("/health/")
        self.assertEqual(response.status_code, 503)
        self.assertEqual(response.json()["checks"]["cache"], "unavailable")
        self.assertNotIn("cache-secret", response.content.decode())
        self.assertEqual(response["Cache-Control"], "no-store")

        with patch("core.health.connection.cursor", side_effect=RuntimeError):
            self.assertEqual(self.client.get("/health/live/").status_code, 200)

    def test_database_backup_requires_destination(self):
        with self.assertRaises(CommandError):
            call_command("backup_database", bucket="")

    @patch("boto3.client")
    @patch("core.management.commands.backup_database.subprocess.run")
    def test_database_backup_is_verified_and_encrypted_before_upload(
        self, run, boto_client
    ):
        def execute(command, **kwargs):
            if command[0] == "pg_dump":
                output = Path(command[command.index("--file") + 1])
                output.write_bytes(b"verified-backup")

        run.side_effect = execute
        s3 = boto_client.return_value
        environment = {
            "DATABASE_URL": "postgresql://backup:secret@db.internal:5432/prepmate?sslmode=require",
            "BACKUP_S3_BUCKET": "private-backups",
            "BACKUP_S3_PREFIX": "prepmate",
        }
        with patch.dict(os.environ, environment, clear=False):
            call_command("backup_database")

        self.assertEqual(run.call_count, 2)
        pg_dump_environment = run.call_args_list[0].kwargs["env"]
        self.assertEqual(pg_dump_environment["PGHOST"], "db.internal")
        self.assertEqual(pg_dump_environment["PGPASSWORD"], "secret")
        self.assertEqual(pg_dump_environment["PGSSLMODE"], "require")
        upload = s3.upload_file.call_args
        self.assertEqual(upload.args[1], "private-backups")
        self.assertTrue(upload.args[2].startswith("prepmate/"))
        self.assertEqual(upload.kwargs["ExtraArgs"], {"ServerSideEncryption": "AES256"})

    def test_private_media_requires_valid_unexpired_path_bound_link(self):
        with tempfile.TemporaryDirectory() as directory, override_settings(MEDIA_ROOT=directory):
            Path(directory, 'resume.pdf').write_bytes(b'%PDF-test')
            url = media_url(None, SimpleNamespace(name='resume.pdf'))
            response = self.client.get(url)
            self.assertEqual(response.status_code, 200)
            response.close()
            self.assertEqual(self.client.get('/media/resume.pdf').status_code, 404)
            self.assertEqual(self.client.get(url.replace('resume.pdf?', 'other.pdf?')).status_code, 404)
            with patch('django.core.signing.time.time', return_value=1):
                expired = media_url(None, SimpleNamespace(name='resume.pdf'))
            self.assertEqual(self.client.get(expired).status_code, 404)

    def test_signed_traversal_is_rejected(self):
        token = signing.dumps('../manage.py', salt='prepmate.media')
        self.assertEqual(self.client.get('/media/../manage.py', {'token': token}).status_code, 404)

    def test_remote_private_media_url_is_returned_unchanged(self):
        signed_url = "https://example.r2.cloudflarestorage.com/media/resume.pdf?X-Amz-Signature=test"
        file_field = SimpleNamespace(name="resume.pdf", url=signed_url)
        self.assertEqual(media_url(None, file_field), signed_url)

    @override_settings(
        MEDIA_STORAGE_BACKEND="r2",
        STORAGES={
            "default": {"BACKEND": "django.core.files.storage.InMemoryStorage"},
            "staticfiles": {
                "BACKEND": "django.contrib.staticfiles.storage.StaticFilesStorage"
            },
        },
    )
    def test_media_migration_uploads_and_verifies_without_deleting_source(self):
        with tempfile.TemporaryDirectory() as directory:
            source = Path(directory, "resumes", "resume.pdf")
            source.parent.mkdir(parents=True)
            source.write_bytes(b"%PDF-private-media")
            output = StringIO()

            call_command(
                "migrate_media_to_object_storage",
                source_root=directory,
                apply=True,
                verify=True,
                stdout=output,
            )

            self.assertTrue(source.exists())
            self.assertTrue(storages["default"].exists("resumes/resume.pdf"))
            self.assertIn("uploaded=1", output.getvalue())
            self.assertIn("verified=1", output.getvalue())
