import os
from googleapiclient.discovery import build
import isodate

class YouTubeService:
    def __init__(self):
        self.api_key = os.getenv("YOUTUBE_API_KEY")
        if self.api_key:
            self.youtube = build("youtube", "v3", developerKey=self.api_key)
        else:
            self.youtube = None

    def search_playlists(self, query, max_results=10):
        if not self.youtube:
            return []

        search_response = self.youtube.search().list(
            q=query,
            type="playlist",
            part="id,snippet",
            maxResults=max_results
        ).execute()

        results = []
        for item in search_response.get("items", []):
            playlist_id = item["id"]["playlistId"]
            snippet = item["snippet"]

            # Get more details for the playlist
            playlist_details = self.youtube.playlists().list(
                part="contentDetails",
                id=playlist_id
            ).execute()

            video_count = 0
            if playlist_details["items"]:
                video_count = playlist_details["items"][0]["contentDetails"]["itemCount"]

            # Get the first video of the playlist to get a video_id for playback
            # (youtube_player_flutter works best with video IDs)
            playlist_items = self.youtube.playlistItems().list(
                part="contentDetails",
                playlistId=playlist_id,
                maxResults=1
            ).execute()

            video_id = ""
            if playlist_items["items"]:
                video_id = playlist_items["items"][0]["contentDetails"]["videoId"]

            results.append({
                "title": snippet["title"],
                "channel": snippet["channelTitle"],
                "video_id": video_id,  # Lead video ID
                "playlist_id": playlist_id,
                "thumbnail": snippet["thumbnails"]["high"]["url"],
                "video_count": video_count,
                "description": snippet["description"]
            })

        return results

    def get_video_details(self, video_id):
        if not self.youtube:
            return None

        response = self.youtube.videos().list(
            part="contentDetails,statistics,snippet",
            id=video_id
        ).execute()

        if not response["items"]:
            return None

        item = response["items"][0]
        duration_iso = item["contentDetails"]["duration"]
        duration_seconds = int(isodate.parse_duration(duration_iso).total_seconds())

        return {
            "duration_seconds": duration_seconds,
            "view_count": int(item["statistics"].get("viewCount", 0)),
            "published_at": item["snippet"]["publishedAt"]
        }
