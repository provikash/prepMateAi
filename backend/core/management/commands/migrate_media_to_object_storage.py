import hashlib
from pathlib import Path, PurePosixPath

from django.conf import settings
from django.core.files import File
from django.core.files.storage import storages
from django.core.management.base import BaseCommand, CommandError


def _sha256(stream):
    digest = hashlib.sha256()
    for chunk in iter(lambda: stream.read(1024 * 1024), b""):
        digest.update(chunk)
    return digest.hexdigest()


class Command(BaseCommand):
    help = (
        "Copy local media files to the configured private object storage. "
        "The command is a dry run unless --apply is supplied and never deletes local files."
    )

    def add_arguments(self, parser):
        parser.add_argument(
            "--source-root",
            default=str(settings.MEDIA_ROOT),
            help="Local media directory to copy (defaults to MEDIA_ROOT).",
        )
        parser.add_argument(
            "--prefix",
            default="",
            help="Optional object-key prefix, for example legacy-media.",
        )
        parser.add_argument(
            "--apply",
            action="store_true",
            help="Upload files that do not already exist.",
        )
        parser.add_argument(
            "--verify",
            action="store_true",
            help="Compare source and destination size and SHA-256 after upload.",
        )

    def handle(self, *args, **options):
        if getattr(settings, "MEDIA_STORAGE_BACKEND", "local") != "r2":
            raise CommandError("MEDIA_STORAGE_BACKEND must be r2 for this command.")

        source_root = Path(options["source_root"]).expanduser().resolve()
        if not source_root.is_dir():
            raise CommandError(f"Source media directory does not exist: {source_root}")

        prefix = options["prefix"].strip().strip("/")
        if prefix and (".." in PurePosixPath(prefix).parts or "\\" in prefix):
            raise CommandError("--prefix must be a safe object-key prefix.")

        apply_changes = options["apply"]
        verify = options["verify"]
        storage = storages["default"]
        files = sorted(path for path in source_root.rglob("*") if path.is_file())
        uploaded = skipped = verified = failed = 0

        for source in files:
            relative = source.relative_to(source_root).as_posix()
            key = str(PurePosixPath(prefix, relative)) if prefix else relative
            try:
                exists = storage.exists(key)
                if not exists and apply_changes:
                    with source.open("rb") as source_stream:
                        saved_key = storage.save(key, File(source_stream, name=key))
                    if saved_key != key:
                        storage.delete(saved_key)
                        raise RuntimeError(
                            f"storage changed object key from {key!r} to {saved_key!r}"
                        )
                    uploaded += 1
                    exists = True
                elif exists:
                    skipped += 1

                if verify and exists:
                    if storage.size(key) != source.stat().st_size:
                        raise RuntimeError("size mismatch")
                    with source.open("rb") as local_stream, storage.open(key, "rb") as remote_stream:
                        if _sha256(local_stream) != _sha256(remote_stream):
                            raise RuntimeError("SHA-256 mismatch")
                    verified += 1

                action = "exists" if exists else "would upload"
                self.stdout.write(f"{action}: {key}")
            except Exception as exc:
                failed += 1
                self.stderr.write(self.style.ERROR(f"failed: {key}: {exc}"))

        mode = "applied" if apply_changes else "dry run"
        self.stdout.write(
            self.style.SUCCESS(
                f"Media migration {mode}: total={len(files)} uploaded={uploaded} "
                f"existing={skipped} verified={verified} failed={failed}"
            )
        )
        if failed:
            raise CommandError(f"Media migration completed with {failed} failure(s).")
