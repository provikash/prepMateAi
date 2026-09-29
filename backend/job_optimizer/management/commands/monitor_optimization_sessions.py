from datetime import timedelta

from django.conf import settings
from django.core.cache import cache
from django.core.management.base import BaseCommand, CommandError
from django.utils import timezone

from core.monitoring import report_operational_failure
from job_optimizer.models import OptimizationSession


ACTIVE_STATUSES = (
    OptimizationSession.Status.ANALYZING,
    OptimizationSession.Status.MATCHING,
    OptimizationSession.Status.APPLYING,
    OptimizationSession.Status.GENERATING_PDF,
)


class Command(BaseCommand):
    help = "Mark stuck optimization sessions failed and alert on newly detected failures."

    def add_arguments(self, parser):
        parser.add_argument(
            "--stale-minutes", type=int,
            default=settings.OPTIMIZATION_STALE_MINUTES,
        )
        parser.add_argument("--failure-lookback-minutes", type=int, default=20)
        parser.add_argument("--apply", action="store_true")

    def handle(self, *args, **options):
        if options["stale_minutes"] < 1 or options["failure_lookback_minutes"] < 1:
            raise ValueError("monitoring time windows must be greater than zero")

        now = timezone.now()
        stale_cutoff = now - timedelta(minutes=options["stale_minutes"])
        stale = OptimizationSession.objects.filter(
            status__in=ACTIVE_STATUSES,
            updated_at__lt=stale_cutoff,
        )
        stale_ids = list(stale.values_list("pk", flat=True))
        if stale_ids and options["apply"]:
            stale.update(
                status=OptimizationSession.Status.FAILED,
                failed_at=now,
                failure_code="operation_timed_out",
                failure_message="The optimization operation exceeded its processing window.",
                updated_at=now,
            )

        failure_cutoff = now - timedelta(minutes=options["failure_lookback_minutes"])
        recent_failures = OptimizationSession.objects.filter(
            status=OptimizationSession.Status.FAILED,
            updated_at__gte=failure_cutoff,
        ).values_list("pk", "failure_code")
        newly_detected = []
        for session_id, failure_code in recent_failures:
            alert_key = f"ops:optimizer-failure:{session_id}"
            if cache.add(alert_key, "reported", timeout=86400):
                newly_detected.append((str(session_id), failure_code or "unknown"))

        if stale_ids or newly_detected:
            report_operational_failure(
                "optimization_sessions_failed",
                stale_count=len(stale_ids),
                newly_failed_count=len(newly_detected),
            )
        self.stdout.write(
            f"Optimization monitor; stale={len(stale_ids)} newly_failed={len(newly_detected)} "
            f"apply={options['apply']}"
        )
        if stale_ids or newly_detected:
            raise CommandError("Failed or stuck optimization sessions require attention.")
