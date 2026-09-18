import hashlib
import logging

from django.core.cache import cache
from rest_framework import permissions, status, views
from rest_framework.response import Response
from rest_framework.throttling import ScopedRateThrottle

from .models import CourseProgress
from .serializers import CourseProgressSerializer, ProgressRequestSerializer, RecommendationRequestSerializer
from .services.youtube_service import YouTubeService
from .services.scoring import CourseScorer

logger = logging.getLogger(__name__)


class CourseRecommendationView(views.APIView):
    permission_classes = [permissions.IsAuthenticated]
    throttle_scope = 'course_recommendations'

    def post(self, request):
        serializer = RecommendationRequestSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        skills = serializer.validated_data['skills']
        query = ' '.join(sorted(skills)) + ' full course playlist'
        key = 'courses:v1:' + hashlib.sha256(query.encode()).hexdigest()
        results = cache.get(key)
        if results is not None:
            return Response({'results': results})
        try:
            raw_results = YouTubeService().search_playlists(query)
            scorer = CourseScorer(skills)
            results = sorted(
                [{**item, 'match_score': scorer.compute_score(item)} for item in raw_results],
                key=lambda item: item['match_score'], reverse=True,
            )
            cache.set(key, results, timeout=3600)
            return Response({'results': results})
        except Exception:
            logger.warning('Course provider unavailable')
            return Response({'detail': 'Courses are temporarily unavailable. Please try again later.'}, status=503)


class CourseProgressView(views.APIView):
    permission_classes = [permissions.IsAuthenticated]
    throttle_scope = 'course_progress'
    throttle_classes = [ScopedRateThrottle]

    def get(self, request, video_id=None):
        queryset = CourseProgress.objects.filter(user=request.user).order_by('-last_updated')
        if video_id:
            progress = queryset.filter(video_id=video_id).first()
            if progress is None:
                return Response({'video_id': video_id, 'watched_seconds': 0, 'total_seconds': 0, 'watch_percentage': 0})
            return Response(CourseProgressSerializer(progress).data)
        return Response(CourseProgressSerializer(queryset, many=True).data)

    def post(self, request):
        serializer = ProgressRequestSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        values = dict(serializer.validated_data)
        video_id = values.pop('video_id')
        progress, created = CourseProgress.objects.update_or_create(user=request.user, video_id=video_id, defaults=values)
        return Response(CourseProgressSerializer(progress).data, status=status.HTTP_201_CREATED if created else status.HTTP_200_OK)
