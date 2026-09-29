import os
import subprocess
import tempfile
from pathlib import Path
from urllib.parse import unquote, urlparse

from django.core.management.base import BaseCommand, CommandError
from django.utils import timezone

from core.monitoring import report_operational_failure


class Command(BaseCommand):
    help = "Create, verify, and upload an encrypted PostgreSQL backup to S3."

    def add_arguments(self, parser):
        parser.add_argument("--bucket", default=os.getenv("BACKUP_S3_BUCKET", ""))
        parser.add_argument("--prefix", default=os.getenv("BACKUP_S3_PREFIX", "prepmate"))

    def handle(self, *args, **options):
        database_url = os.getenv("DATABASE_URL", "").strip()
        bucket = options["bucket"].strip()
        if not database_url or not bucket:
            raise CommandError("DATABASE_URL and BACKUP_S3_BUCKET are required.")
        parsed = urlparse(database_url)
        if parsed.scheme not in {"postgres", "postgresql"}:
            raise CommandError("backup_database supports PostgreSQL only.")

        stamp = timezone.now().strftime("%Y/%m/%d/prepmate-%Y%m%dT%H%M%SZ.dump")
        object_key = f"{options['prefix'].strip('/')}/{stamp}".lstrip("/")
        process_env = os.environ.copy()
        process_env.update({
            "PGHOST": parsed.hostname or "",
            "PGPORT": str(parsed.port or 5432),
            "PGUSER": unquote(parsed.username or ""),
            "PGPASSWORD": unquote(parsed.password or ""),
            "PGDATABASE": unquote(parsed.path.lstrip("/")),
        })
        if "sslmode=" in parsed.query:
            for item in parsed.query.split("&"):
                if item.startswith("sslmode="):
                    process_env["PGSSLMODE"] = item.partition("=")[2]

        try:
            with tempfile.TemporaryDirectory() as directory:
                backup_path = Path(directory) / "database.dump"
                subprocess.run(
                    [
                        "pg_dump", "--format=custom", "--compress=9",
                        "--no-owner", "--no-privileges", "--file", str(backup_path),
                    ],
                    env=process_env,
                    check=True,
                    capture_output=True,
                    text=True,
                )
                subprocess.run(
                    ["pg_restore", "--list", str(backup_path)],
                    check=True,
                    capture_output=True,
                    text=True,
                )
                import boto3

                client = boto3.client(
                    "s3",
                    region_name=os.getenv("BACKUP_S3_REGION") or None,
                    endpoint_url=os.getenv("BACKUP_S3_ENDPOINT") or None,
                )
                client.upload_file(
                    str(backup_path),
                    bucket,
                    object_key,
                    ExtraArgs={
                        "ServerSideEncryption": os.getenv(
                            "BACKUP_S3_ENCRYPTION", "AES256"
                        )
                    },
                )
                size = backup_path.stat().st_size
        except Exception as exc:
            report_operational_failure(
                "database_backup_failed", exception=exc, bucket=bucket,
            )
            raise CommandError("Database backup failed; see monitoring logs.") from exc

        self.stdout.write(self.style.SUCCESS(
            f"Verified database backup uploaded: s3://{bucket}/{object_key} ({size} bytes)"
        ))
