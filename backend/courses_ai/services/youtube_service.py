import os
from googleapiclient.discovery import build
import isodate
import httplib2

class YouTubeService:
    def __init__(self):
        self.api_key = os.getenv("YOUTUBE_API_KEY")
        if self.api_key:
            self.youtube = build("youtube", "v3", developerKey=self.api_key, http=httplib2.Http(timeout=15), cache_discovery=False)
        else:
            self.youtube = None

    def search_playlists(self, query, max_results=10):
        if not self.youtube:
            raise RuntimeError('YouTube API is not configured.')

        search_response = self.youtube.search().list(
            q=query,
            type="playlist",
            part="id,snippet",
            maxResults=max_results
        ).execute()

        playlist_ids = [item['id']['playlistId'] for item in search_response.get('items', [])]
        if not playlist_ids:
            return []
        details = self.youtube.playlists().list(part='contentDetails', id=','.join(playlist_ids)).execute()
        counts = {item['id']: item['contentDetails']['itemCount'] for item in details.get('items', [])}
        results = []
        for item in search_response.get("items", []):
            playlist_id = item["id"]["playlistId"]
            snippet = item["snippet"]

            # Get more details for the playlist
            video_count = counts.get(playlist_id, 0)

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

            if not video_id:
                continue

            results.append({
                "title": snippet["title"],
                "channel": snippet["channelTitle"],
                "video_id": video_id,  # Lead video ID
                "playlist_id": playlist_id,
                "thumbnail": (snippet.get('thumbnails', {}).get('high') or snippet.get('thumbnails', {}).get('default') or {}).get('url', ''),
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
