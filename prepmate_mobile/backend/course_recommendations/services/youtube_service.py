import os
import logging
from typing import List, Dict, Optional
from googleapiclient.discovery import build
from googleapiclient.errors import HttpError

logger = logging.getLogger(__name__)


class YouTubeService:
    """Service for searching YouTube videos and extracting metadata."""

    def __init__(self):
        self.api_key = os.getenv("YOUTUBE_API_KEY")
        if not self.api_key:
            logger.warning("YOUTUBE_API_KEY not set in environment")
            self.service = None
        else:
            self.service = build("youtube", "v3", developerKey=self.api_key)

    def search_videos(
        self, query: str, max_results: int = 20
    ) -> List[Dict]:
        """
        Search YouTube for videos/playlists.
        
        Args:
            query: Search query string
            max_results: Maximum number of results (default 20)
            
        Returns:
            List of normalized video/playlist data
        """
        if not self.service:
            logger.error("YouTube service not initialized")
            return []

        try:
            request = self.service.search().list(
                q=query,
                part="snippet",
                maxResults=min(max_results, 50),  # YouTube API max is 50
                type="video",
                videoDuration="long",  # 20+ minutes
                order="relevance",
                regionCode="US",
            )
            response = request.execute()
            return self._normalize_results(response)
        except HttpError as e:
            logger.error(f"YouTube API error: {e}")
            return []
        except Exception as e:
            logger.error(f"Unexpected error searching YouTube: {e}")
            return []

    def _normalize_results(self, response: Dict) -> List[Dict]:
        """
        Normalize YouTube API response to our format.
        
        Args:
            response: Raw YouTube API response
            
        Returns:
            Normalized list of video data
        """
        results = []
        items = response.get("items", [])

        for item in items:
            snippet = item.get("snippet", {})
            video_id = item.get("id", {}).get("videoId")

            if not video_id:
                continue

            normalized = {
                "title": snippet.get("title", "Unknown"),
                "channel": snippet.get("channelTitle", "Unknown"),
                "video_id": video_id,
                "thumbnail": self._get_thumbnail_url(snippet),
                "description": snippet.get("description", ""),
                "published_at": snippet.get("publishedAt", ""),
            }
            results.append(normalized)

        return results

    def _get_thumbnail_url(self, snippet: Dict) -> str:
        """Extract best quality thumbnail URL from snippet."""
        thumbnails = snippet.get("thumbnails", {})
        
        # Prefer high quality
        if "high" in thumbnails:
            return thumbnails["high"]["url"]
        elif "medium" in thumbnails:
            return thumbnails["medium"]["url"]
        elif "default" in thumbnails:
            return thumbnails["default"]["url"]
        
        return ""

    def get_video_details(self, video_id: str) -> Optional[Dict]:
        """
        Get detailed information about a specific video.
        
        Args:
            video_id: YouTube video ID
            
        Returns:
            Video details including duration and view count
        """
        if not self.service:
            return None

        try:
            request = self.service.videos().list(
                part="contentDetails,statistics",
                id=video_id,
            )
            response = request.execute()
            items = response.get("items", [])

            if not items:
                return None

            item = items[0]
            content_details = item.get("contentDetails", {})
            statistics = item.get("statistics", {})

            return {
                "duration": content_details.get("duration"),
                "view_count": int(statistics.get("viewCount", 0)),
                "like_count": int(statistics.get("likeCount", 0)),
            }
        except Exception as e:
            logger.error(f"Error getting video details for {video_id}: {e}")
            return None


# Singleton instance
_youtube_service = None


def get_youtube_service() -> YouTubeService:
    """Get or create singleton YouTube service instance."""
    global _youtube_service
    if _youtube_service is None:
        _youtube_service = YouTubeService()
    return _youtube_service
