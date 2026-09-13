from rest_framework import status, views, permissions
from rest_framework.response import Response
from .models import CourseRecommendation, CourseProgress
from .serializers import CourseRecommendationSerializer, CourseProgressSerializer
from .services.youtube_service import YouTubeService
from .services.scoring import CourseScorer
import logging

logger = logging.getLogger(__name__)

class CourseRecommendationView(views.APIView):
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request):
        skills = request.data.get('skills', [])
        if not skills:
            return Response({"error": "Skills are required"}, status=status.HTTP_400_BAD_REQUEST)

        query = " ".join(skills) + " full course playlist"

        try:
            yt_service = YouTubeService()
            raw_results = yt_service.search_playlists(query)

            scorer = CourseScorer(skills)
            scored_results = []

            for item in raw_results:
                match_score = scorer.compute_score(item)
                item['match_score'] = match_score
                scored_results.append(item)

            # Sort by match score
            scored_results.sort(key=lambda x: x['match_score'], reverse=True)

            # Save/Update in DB for caching if needed (Optional)
            # For simplicity, we just return the scored results

            return Response({"results": scored_results}, status=status.HTTP_200_OK)
        except Exception as e:
            logger.error(f"Error fetching recommendations: {str(e)}")
            return Response({"error": "Failed to fetch recommendations from YouTube"}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

class CourseProgressView(views.APIView):
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request, video_id=None):
        if video_id:
            try:
                progress = CourseProgress.objects.get(user=request.user, video_id=video_id)
                serializer = CourseProgressSerializer(progress)
                return Response(serializer.data)
            except CourseProgress.DoesNotExist:
                return Response({
                    "video_id": video_id,
                    "watched_seconds": 0,
                    "total_seconds": 0,
                    "watch_percentage": 0,
                }, status=status.HTTP_200_OK)
        else:
            progress_list = CourseProgress.objects.filter(user=request.user)
            serializer = CourseProgressSerializer(progress_list, many=True)
            return Response(serializer.data)

    def post(self, request):
        video_id = request.data.get('video_id')
        watched_seconds = request.data.get('watched_seconds')
        total_seconds = request.data.get('total_seconds')

        if not video_id:
            return Response({"error": "video_id is required"}, status=status.HTTP_400_BAD_REQUEST)

        progress, created = CourseProgress.objects.update_or_create(
            user=request.user,
            video_id=video_id,
            defaults={
                'watched_seconds': watched_seconds,
                'total_seconds': total_seconds
            }
        )

        serializer = CourseProgressSerializer(progress)
        return Response(serializer.data, status=status.HTTP_200_OK)
