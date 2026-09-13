import logging
from rest_framework import status
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework.views import APIView
from rest_framework.generics import ListAPIView

from .models import CourseRecommendation, CourseProgress
from .serializers import (
    CourseRecommendationSerializer,
    CourseProgressSerializer,
    CourseProgressUpdateSerializer,
    CourseRecommendationRequestSerializer,
)
from .services.youtube_service import get_youtube_service
from .services.scoring import get_scoring_engine

logger = logging.getLogger(__name__)


class CourseRecommendationAPIView(APIView):
    """
    POST /api/v1/course-recommendations/
    
    Recommend courses based on skills.
    Request: { "skills": ["react", "state management"] }
    Response: { "results": [...] }
    """
    permission_classes = [IsAuthenticated]

    def post(self, request):
        serializer = CourseRecommendationRequestSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        skills = serializer.validated_data["skills"]

        # Build search query
        query = self._build_query(skills)
        logger.info(f"Built search query: {query}")

        # Get YouTube service and search
        yt_service = get_youtube_service()
        results = yt_service.search_videos(query, max_results=20)

        if not results:
            return Response(
                {"results": [], "message": "No courses found"},
                status=status.HTTP_200_OK,
            )

        # Get video details for scoring (view counts, duration, etc.)
        video_details_map = {}
        for video in results:
            details = yt_service.get_video_details(video["video_id"])
            if details:
                video_details_map[video["video_id"]] = details

        # Score and rank results
        scoring_engine = get_scoring_engine()
        ranked_results = scoring_engine.rank_results(results, query, video_details_map)

        # Take top 12 results
        top_results = ranked_results[:12]

        # Cache top results in database
        self._cache_recommendations(top_results)

        # Serialize response
        serialized = CourseRecommendationSerializer(
            [self._video_to_course_rec(v) for v in top_results],
            many=True,
        )

        return Response(
            {"results": serialized.data},
            status=status.HTTP_200_OK,
        )

    @staticmethod
    def _build_query(skills: list) -> str:
        """Build YouTube search query from skills."""
        skill_str = " ".join(skills)
        return f"{skill_str} full course playlist tutorial"

    @staticmethod
    def _video_to_course_rec(video_data: dict) -> CourseRecommendation:
        """Convert video data to CourseRecommendation instance (unsaved)."""
        return CourseRecommendation(
            title=video_data.get("title"),
            channel=video_data.get("channel"),
            video_id=video_data.get("video_id"),
            thumbnail=video_data.get("thumbnail"),
            match_score=video_data.get("match_score", 0),
        )

    @staticmethod
    def _cache_recommendations(results: list):
        """Cache recommendations in database."""
        for video in results:
            CourseRecommendation.objects.update_or_create(
                video_id=video["video_id"],
                defaults={
                    "title": video.get("title"),
                    "channel": video.get("channel"),
                    "thumbnail": video.get("thumbnail"),
                    "match_score": video.get("match_score", 0),
                },
            )


class CourseProgressCreateUpdateAPIView(APIView):
    """
    POST /api/v1/course-progress/
    
    Create or update course progress.
    Request: {
        "video_id": "abc123",
        "watched_seconds": 320,
        "total_seconds": 1200
    }
    """
    permission_classes = [IsAuthenticated]

    def post(self, request):
        serializer = CourseProgressUpdateSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        video_id = serializer.validated_data["video_id"]
        watched_seconds = serializer.validated_data["watched_seconds"]
        total_seconds = serializer.validated_data["total_seconds"]

        # Update or create progress
        progress, created = CourseProgress.objects.update_or_create(
            user=request.user,
            video_id=video_id,
            defaults={
                "watched_seconds": watched_seconds,
                "total_seconds": total_seconds,
            },
        )

        serializer = CourseProgressSerializer(progress)
        return Response(serializer.data, status=status.HTTP_201_CREATED if created else status.HTTP_200_OK)


class CourseProgressDetailAPIView(APIView):
    """
    GET /api/v1/course-progress/{video_id}/
    
    Get progress for a specific video.
    Response: {
        "watched_seconds": 320,
        "total_seconds": 1200,
        "watch_percentage": 26.67
    }
    """
    permission_classes = [IsAuthenticated]

    def get(self, request, video_id):
        try:
            progress = CourseProgress.objects.get(
                user=request.user,
                video_id=video_id,
            )
            serializer = CourseProgressSerializer(progress)
            return Response(serializer.data, status=status.HTTP_200_OK)
        except CourseProgress.DoesNotExist:
            # Return zero progress if not found
            return Response(
                {
                    "video_id": video_id,
                    "watched_seconds": 0,
                    "total_seconds": 0,
                    "watch_percentage": 0.0,
                },
                status=status.HTTP_200_OK,
            )


class CourseProgressListAPIView(ListAPIView):
    """
    GET /api/v1/course-progress/
    
    Get all course progress for current user.
    """
    permission_classes = [IsAuthenticated]
    serializer_class = CourseProgressSerializer

    def get_queryset(self):
        return CourseProgress.objects.filter(user=self.request.user).order_by("-last_updated")
