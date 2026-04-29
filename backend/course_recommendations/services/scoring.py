import logging
from typing import List, Dict
from datetime import datetime
from dateutil import parser as date_parser

logger = logging.getLogger(__name__)


class ScoringEngine:
    """Calculate relevance scores for course recommendations."""

    # Weighting factors (must sum to 1.0)
    KEYWORD_WEIGHT = 0.40  # 40%
    RECENCY_WEIGHT = 0.20  # 20%
    ENGAGEMENT_WEIGHT = 0.25  # 25%
    DURATION_WEIGHT = 0.15  # 15%

    def __init__(self):
        # Keywords that boost score
        self.high_value_keywords = [
            "full course",
            "tutorial",
            "beginner",
            "complete",
            "learn",
            "master",
            "advanced",
            "project-based",
            "hands-on",
        ]

        # Keywords that lower score
        self.low_value_keywords = [
            "trailer",
            "clip",
            "shorts",
            "meme",
            "unboxing",
        ]

    def calculate_score(
        self,
        search_query: str,
        video_data: Dict,
        video_details: Dict = None,
    ) -> float:
        """
        Calculate match score (0-100) for a video.
        
        Args:
            search_query: Original search query
            video_data: Video info from YouTube API
            video_details: Detailed statistics (optional)
            
        Returns:
            Score between 0-100
        """
        keyword_score = self._keyword_relevance(search_query, video_data)
        recency_score = self._recency_score(video_data.get("published_at", ""))
        engagement_score = self._engagement_score(video_details or {})
        duration_score = self._duration_score(video_details or {})

        # Weighted average
        total_score = (
            (keyword_score * self.KEYWORD_WEIGHT) +
            (recency_score * self.RECENCY_WEIGHT) +
            (engagement_score * self.ENGAGEMENT_WEIGHT) +
            (duration_score * self.DURATION_WEIGHT)
        )

        return round(max(0.0, min(100.0, total_score)), 2)

    def _keyword_relevance(self, query: str, video_data: Dict) -> float:
        """Calculate keyword matching score (0-100)."""
        title = video_data.get("title", "").lower()
        channel = video_data.get("channel", "").lower()
        description = video_data.get("description", "").lower()
        query_lower = query.lower()

        score = 0.0

        # Exact query match in title = high score
        if query_lower in title:
            score += 50.0
        else:
            # Check individual query words in title
            query_words = query_lower.split()
            matched_words = sum(1 for word in query_words if word in title)
            score += (matched_words / len(query_words)) * 40.0 if query_words else 0

        # High-value keywords boost
        high_value_count = sum(1 for kw in self.high_value_keywords if kw in title)
        score += min(30.0, high_value_count * 10.0)

        # Low-value keywords penalty
        low_value_count = sum(1 for kw in self.low_value_keywords if kw in title)
        score -= min(30.0, low_value_count * 15.0)

        # Channel relevance boost
        if "freeCodeCamp" in channel or "FCC" in channel:
            score += 15.0
        elif any(org in channel for org in ["Udemy", "Coursera", "Edx"]):
            score += 10.0

        return max(0.0, min(100.0, score))

    def _recency_score(self, published_at: str) -> float:
        """Score based on how recent the video is (0-100)."""
        if not published_at:
            return 50.0

        try:
            pub_date = date_parser.parse(published_at)
            days_old = (datetime.utcnow() - pub_date.replace(tzinfo=None)).days

            # Videos from last 2 years get full score
            if days_old <= 730:
                return 100.0
            # Older videos get degraded score (1% per month)
            elif days_old <= 1460:  # 4 years
                return max(0.0, 100.0 - (days_old - 730) * 0.5)
            else:
                return 0.0
        except Exception as e:
            logger.warning(f"Error parsing date {published_at}: {e}")
            return 50.0

    def _engagement_score(self, video_details: Dict) -> float:
        """Score based on view count and engagement (0-100)."""
        view_count = video_details.get("view_count", 0)

        # Logarithmic scale
        if view_count == 0:
            return 30.0  # Default for videos without view data
        elif view_count >= 1_000_000:
            return 100.0
        elif view_count >= 100_000:
            return 85.0
        elif view_count >= 10_000:
            return 70.0
        elif view_count >= 1_000:
            return 50.0
        else:
            return 30.0

    def _duration_score(self, video_details: Dict) -> float:
        """Score based on video duration (0-100)."""
        duration_str = video_details.get("duration", "")

        if not duration_str:
            return 50.0

        try:
            # Parse ISO 8601 duration (e.g., "PT1H30M45S")
            total_seconds = self._parse_iso8601_duration(duration_str)

            # Prefer videos 15-120 minutes
            if 900 <= total_seconds <= 7200:  # 15-120 minutes
                return 100.0
            elif 300 <= total_seconds < 900:  # 5-15 minutes (too short)
                return 60.0
            elif 7200 < total_seconds <= 14400:  # 120-240 minutes (acceptable)
                return 85.0
            else:  # Too long or very short
                return 40.0
        except Exception as e:
            logger.warning(f"Error parsing duration {duration_str}: {e}")
            return 50.0

    @staticmethod
    def _parse_iso8601_duration(duration: str) -> int:
        """Parse ISO 8601 duration to total seconds."""
        import re

        # Format: PT[hours]H[minutes]M[seconds]S
        pattern = r"PT(?:(\d+)H)?(?:(\d+)M)?(?:(\d+)S)?"
        match = re.match(pattern, duration)

        if not match:
            return 0

        hours, minutes, seconds = match.groups()
        total = 0
        total += int(hours or 0) * 3600
        total += int(minutes or 0) * 60
        total += int(seconds or 0)

        return total

    def rank_results(
        self, results: List[Dict], query: str, video_details_map: Dict = None
    ) -> List[Dict]:
        """
        Score and rank all results.
        
        Args:
            results: List of video data from YouTube
            query: Original search query
            video_details_map: Map of video_id -> details
            
        Returns:
            Sorted list with scores added
        """
        video_details_map = video_details_map or {}
        scored_results = []

        for video in results:
            video_id = video.get("video_id")
            details = video_details_map.get(video_id, {})
            score = self.calculate_score(query, video, details)
            
            video["match_score"] = score
            scored_results.append(video)

        # Sort by score descending
        scored_results.sort(key=lambda x: x["match_score"], reverse=True)

        return scored_results


# Singleton instance
_scoring_engine = None


def get_scoring_engine() -> ScoringEngine:
    """Get or create singleton scoring engine instance."""
    global _scoring_engine
    if _scoring_engine is None:
        _scoring_engine = ScoringEngine()
    return _scoring_engine
