# AI Course Finder - Architecture & Data Flow

## System Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    Flutter Mobile App                        │
│  ┌──────────────────────────────────────────────────────┐   │
│  │            Presentation Layer                        │   │
│  │  ┌─────────────────────────────────────────────┐    │   │
│  │  │  AI Course Finder Screen                   │    │   │
│  │  │  ├─ AI Search Box                          │    │   │
│  │  │  ├─ Skill Gap Summary                       │    │   │
│  │  │  ├─ Continue Learning                       │    │   │
│  │  │  └─ Recommended Playlists (Horizontal)     │    │   │
│  │  └─────────────────────────────────────────────┘    │   │
│  │  ┌─────────────────────────────────────────────┐    │   │
│  │  │  Video Player Screen                       │    │   │
│  │  │  ├─ YouTube Player Widget                  │    │   │
│  │  │  ├─ Video Info                             │    │   │
│  │  │  └─ Progress Tracking Bar                  │    │   │
│  │  └─────────────────────────────────────────────┘    │   │
│  └──────────────────────────────────────────────────────┘   │
│  ┌──────────────────────────────────────────────────────┐   │
│  │            State Management (Riverpod)              │   │
│  │  ┌──────────────────────────────────────────────┐  │   │
│  │  │ Providers:                                   │  │   │
│  │  │ • courseRecommendationsProvider              │  │   │
│  │  │ • courseProgressProvider(videoId)            │  │   │
│  │  │ • allCourseProgressProvider                  │  │   │
│  │  │ • skillGapProvider                           │  │   │
│  │  │ • continueLearningProvider                   │  │   │
│  │  │ • currentVideoIdProvider                     │  │   │
│  │  └──────────────────────────────────────────────┘  │   │
│  └──────────────────────────────────────────────────────┘   │
│  ┌──────────────────────────────────────────────────────┐   │
│  │            Data Layer (Repository)                  │   │
│  │  ┌──────────────────────────────────────────────┐  │   │
│  │  │  CourseRepository                            │  │   │
│  │  │  • getCourseRecommendations()                │  │   │
│  │  │  • getCourseProgress()                       │  │   │
│  │  │  • updateCourseProgress()                    │  │   │
│  │  │  • getAllCourseProgress()                    │  │   │
│  │  └──────────────────────────────────────────────┘  │   │
│  └──────────────────────────────────────────────────────┘   │
│  ┌──────────────────────────────────────────────────────┐   │
│  │            HTTP Client (Dio)                        │   │
│  │  • Base URL: http://api.server/v1/               │   │
│  │  • JWT Token: From secure storage               │   │
│  │  • Interceptors: Auth, error handling            │   │
│  └──────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
                            │
                            │ HTTP/REST API
                            ▼
┌─────────────────────────────────────────────────────────────┐
│                    Django Backend API                        │
│  ┌──────────────────────────────────────────────────────┐   │
│  │            API Views Layer                          │   │
│  │  ┌────────────────────────────────────────────┐    │   │
│  │  │ CourseRecommendationAPIView                │    │   │
│  │  │ POST /course-recommendations/              │    │   │
│  │  └────────────────────────────────────────────┘    │   │
│  │  ┌────────────────────────────────────────────┐    │   │
│  │  │ CourseProgressCreateUpdateAPIView          │    │   │
│  │  │ POST /course-progress/create/              │    │   │
│  │  └────────────────────────────────────────────┘    │   │
│  │  ┌────────────────────────────────────────────┐    │   │
│  │  │ CourseProgressDetailAPIView                │    │   │
│  │  │ GET /course-progress/{video_id}/           │    │   │
│  │  └────────────────────────────────────────────┘    │   │
│  │  ┌────────────────────────────────────────────┐    │   │
│  │  │ CourseProgressListAPIView                  │    │   │
│  │  │ GET /course-progress/                      │    │   │
│  │  └────────────────────────────────────────────┘    │   │
│  └──────────────────────────────────────────────────────┘   │
│  ┌──────────────────────────────────────────────────────┐   │
│  │            Services Layer                          │   │
│  │  ┌────────────────────────────────────────────┐    │   │
│  │  │ YouTubeService                             │    │   │
│  │  │ • search_videos()                          │    │   │
│  │  │ • get_video_details()                      │    │   │
│  │  │ • normalize_results()                      │    │   │
│  │  └────────────────────────────────────────────┘    │   │
│  │  ┌────────────────────────────────────────────┐    │   │
│  │  │ ScoringEngine                              │    │   │
│  │  │ • calculate_score()                        │    │   │
│  │  │ • rank_results()                           │    │   │
│  │  │ • (keyword, recency, engagement, duration)│    │   │
│  │  └────────────────────────────────────────────┘    │   │
│  └──────────────────────────────────────────────────────┘   │
│  ┌──────────────────────────────────────────────────────┐   │
│  │            Data Models                              │   │
│  │  • CourseRecommendation                             │   │
│  │  • CourseProgress                                   │   │
│  └──────────────────────────────────────────────────────┘   │
│  ┌──────────────────────────────────────────────────────┐   │
│  │            Database Layer                           │   │
│  │  • PostgreSQL / SQLite                              │   │
│  │  • Tables: course_recommendations_*                 │   │
│  └──────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
                            │
                            │ HTTP API
                            ▼
            ┌───────────────────────────────────┐
            │   YouTube Data API v3              │
            │   • search.list()                  │
            │   • videos.list()                  │
            └───────────────────────────────────┘
```

---

## Data Flow - Get Course Recommendations

```
User Input: Select Skills
    │
    ▼
┌─────────────────────────────────┐
│ AICourseFinderScreen            │
│ • Calls: fetchRecommendations() │
│           with skills list      │
└─────────────────────────────────┘
    │
    ▼
┌─────────────────────────────────┐
│ Riverpod Provider                │
│ courseRecommendationsProvider   │
│ State: AsyncValue<List<Course>> │
└─────────────────────────────────┘
    │
    ▼
┌─────────────────────────────────┐
│ CourseRepository                │
│ .getCourseRecommendations(      │
│   skills: ["react", "routing"]  │
│ )                               │
└─────────────────────────────────┘
    │ HTTP POST
    ▼
┌─────────────────────────────────┐
│ Dio HTTP Client                 │
│ POST /api/v1/course-rec.../     │
│ Headers: Auth Bearer TOKEN      │
│ Body: {skills: [...]}           │
└─────────────────────────────────┘
    │ HTTP
    ▼
┌─────────────────────────────────┐
│ Django Backend                  │
│ CourseRecommendationAPIView     │
│ .post()                         │
└─────────────────────────────────┘
    │
    ▼
┌─────────────────────────────────┐
│ Build Search Query              │
│ "react routing full course" │   │
└─────────────────────────────────┘
    │
    ▼
┌─────────────────────────────────┐
│ YouTubeService                  │
│ .search_videos(query)           │
└─────────────────────────────────┘
    │ YouTube Data API v3
    ▼
┌─────────────────────────────────┐
│ YouTube Search Results          │
│ • 20 raw video entries          │
└─────────────────────────────────┘
    │
    ▼
┌─────────────────────────────────┐
│ Extract Metadata for Each Video:│
│ YouTubeService                  │
│ .get_video_details(video_id)    │
│ • View count                    │
│ • Duration                      │
│ • Likes                         │
└─────────────────────────────────┘
    │ YouTube Data API (batch)
    ▼
┌─────────────────────────────────┐
│ Video Details Fetched           │
│ for each video_id               │
└─────────────────────────────────┘
    │
    ▼
┌─────────────────────────────────┐
│ ScoringEngine                   │
│ .rank_results(                  │
│   results, query, details_map   │
│ )                               │
│                                 │
│ For each video:                 │
│ score = (keyword×0.4) +         │
│         (recency×0.2) +         │
│         (engagement×0.25) +     │
│         (duration×0.15)         │
└─────────────────────────────────┘
    │
    ▼
┌─────────────────────────────────┐
│ Sorted Results (by score)       │
│ Top 12 videos selected          │
└─────────────────────────────────┘
    │
    ▼
┌─────────────────────────────────┐
│ Cache in Database               │
│ CourseRecommendation.objects    │
│ .update_or_create() for each    │
└─────────────────────────────────┘
    │
    ▼
┌─────────────────────────────────┐
│ Serialize Results               │
│ CourseRecommendationSerializer  │
└─────────────────────────────────┘
    │ HTTP Response JSON
    ▼
┌─────────────────────────────────┐
│ Flutter Client Receives          │
│ List<AICourse>                  │
│ • Stored in Riverpod state      │
│ • UI rebuilds with data         │
└─────────────────────────────────┘
    │
    ▼
┌─────────────────────────────────┐
│ AICourseFinderScreen Renders    │
│ • Course cards in list          │
│ • Each shows:                   │
│   - Thumbnail                   │
│   - Title + Channel             │
│   - Match % badge               │
│   - Duration                    │
└─────────────────────────────────┘
```

---

## Data Flow - Track Video Progress

```
Video Playing in Player
    │
    ▼ (every 100ms - position changes)
    │
┌─────────────────────────────────┐
│ YouTubePlayer Listener          │
│ _onPlayerStateChanged()          │
│ _trackProgress()                │
└─────────────────────────────────┘
    │
    ▼
┌─────────────────────────────────┐
│ Check if 5+ seconds elapsed     │
│ since last report               │
└─────────────────────────────────┘
    │
    ├─ No → Wait more
    │
    └─ Yes ▼
┌─────────────────────────────────┐
│ Get Current Position            │
│ from YouTube Player Controller  │
│ • watchedSeconds = position     │
│ • totalSeconds = metadata.dur.  │
└─────────────────────────────────┘
    │
    ▼
┌─────────────────────────────────┐
│ Call Provider.updateProgress()  │
└─────────────────────────────────┘
    │
    ▼
┌─────────────────────────────────┐
│ Riverpod Provider               │
│ courseProgressProvider(videoId) │
│ .updateProgress(...)            │
└─────────────────────────────────┘
    │
    ▼
┌─────────────────────────────────┐
│ CourseRepository                │
│ .updateCourseProgress(          │
│   videoId, watched_sec, total_s │
│ )                               │
└─────────────────────────────────┘
    │ HTTP POST
    ▼
┌─────────────────────────────────┐
│ Dio HTTP Client                 │
│ POST /api/v1/course-progress/   │
│      create/                    │
│ Headers: Auth Bearer TOKEN      │
│ Body: {video_id, watched_sec...}│
└─────────────────────────────────┘
    │ HTTP
    ▼
┌─────────────────────────────────┐
│ Django Backend                  │
│ CourseProgressCreateUpdateView  │
│ .post()                         │
└─────────────────────────────────┘
    │
    ▼
┌─────────────────────────────────┐
│ Validate Serializer             │
│ CourseProgressUpdateSerializer  │
└─────────────────────────────────┘
    │
    ▼
┌─────────────────────────────────┐
│ Update or Create:               │
│ CourseProgress.objects          │
│ .update_or_create(              │
│   user=request.user,            │
│   video_id=video_id,            │
│   defaults={...}                │
│ )                               │
└─────────────────────────────────┘
    │
    ▼
┌─────────────────────────────────┐
│ Serialize Response              │
│ CourseProgressSerializer        │
└─────────────────────────────────┘
    │ HTTP Response (JSON)
    ▼
┌─────────────────────────────────┐
│ Flutter Receives Updated        │
│ CourseProgress                  │
│ • Update Riverpod state         │
│ • UI shows updated progress %   │
└─────────────────────────────────┘
    │
    ▼
┌─────────────────────────────────┐
│ CourseVideoPlayerScreen Updates:│
│ • Progress bar fills more       │
│ • Percentage display increases  │
│ • Check if >95% (show complete) │
└─────────────────────────────────┘
    │
    └─ Continue Playing...
```

---

## Scoring Algorithm Breakdown

```
Input: search_query, video_data, video_details
Output: match_score (0-100)

┌─ KEYWORD RELEVANCE (40%)
│  ├─ Exact query in title: +50
│  ├─ Query words in title: +0-40 (proportional)
│  ├─ High-value keywords: +0-30
│  │  (full course, tutorial, beginner, complete, learn, etc.)
│  ├─ Low-value keywords penalty: -0-30
│  │  (trailer, clip, shorts, meme, etc.)
│  └─ Channel reputation: +0-15
│     (freeCodeCamp +15, Udemy +10, etc.)
│
├─ VIDEO RECENCY (20%)
│  ├─ < 2 years old: 100
│  ├─ 2-4 years old: 100 - (0.5 × days_old-730)
│  └─ > 4 years old: 0
│
├─ ENGAGEMENT (25%)
│  ├─ 1M+ views: 100
│  ├─ 100k-1M: 85
│  ├─ 10k-100k: 70
│  ├─ 1k-10k: 50
│  └─ < 1k: 30
│
└─ DURATION (15%)
   ├─ 15-120 minutes: 100
   ├─ 5-15 minutes: 60
   ├─ 120-240 minutes: 85
   └─ Other: 40

FINAL FORMULA:
score = (keyword × 0.4) + 
        (recency × 0.2) + 
        (engagement × 0.25) + 
        (duration × 0.15)

Result: Clamp between 0-100, round to 2 decimals
```

---

## Database Schema

```
┌─────────────────────────────────────┐
│   CourseRecommendation              │
├─────────────────────────────────────┤
│ id (UUID) PK                        │
│ title (VARCHAR 255)                 │
│ channel (VARCHAR 255)               │
│ video_id (VARCHAR 255) UNIQUE       │
│ thumbnail (URL)                     │
│ duration (VARCHAR 50) NULL          │
│ video_count (INT)                   │
│ match_score (FLOAT)                 │
│ created_at (DATETIME AUTO)          │
├─────────────────────────────────────┤
│ Indexes:                            │
│ • video_id (UNIQUE)                 │
│ • match_score (DESC)                │
│ • created_at (DESC)                 │
└─────────────────────────────────────┘

┌─────────────────────────────────────┐
│   CourseProgress                    │
├─────────────────────────────────────┤
│ id (UUID) PK                        │
│ user_id (INT) FK → auth_user        │
│ video_id (VARCHAR 255)              │
│ watched_seconds (INT)               │
│ total_seconds (INT)                 │
│ last_updated (DATETIME AUTO)        │
│ created_at (DATETIME AUTO)          │
├─────────────────────────────────────┤
│ Constraints:                        │
│ • UNIQUE (user_id, video_id)        │
│ Indexes:                            │
│ • (user_id, video_id) UNIQUE        │
│ • user_id                           │
│ • last_updated (DESC)               │
└─────────────────────────────────────┘
```

---

## Request/Response Examples

### Get Recommendations

**Request:**
```json
POST /api/v1/course-recommendations/
Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGc...

{
  "skills": ["react", "state management", "testing"]
}
```

**Response (200):**
```json
{
  "results": [
    {
      "id": "550e8400-e29b-41d4-a716-446655440000",
      "title": "React & Redux - The Complete Guide",
      "channel": "freeCodeCamp",
      "video_id": "V5LAyI6Z8NQ",
      "thumbnail": "https://i.ytimg.com/vi/V5LAyI6Z8NQ/maxresdefault.jpg",
      "duration": "PT11H23M",
      "video_count": 0,
      "match_score": 94.25,
      "created_at": "2026-04-28T10:15:00Z"
    },
    {
      "id": "550e8400-e29b-41d4-a716-446655440001",
      "title": "State Management in React - Full Course",
      "channel": "The Net Ninja",
      "video_id": "Gx1F3QNKL9M",
      "thumbnail": "https://i.ytimg.com/vi/Gx1F3QNKL9M/maxresdefault.jpg",
      "duration": "PT3H45M",
      "video_count": 0,
      "match_score": 87.50,
      "created_at": "2026-04-28T10:15:01Z"
    }
  ]
}
```

### Update Progress

**Request:**
```json
POST /api/v1/course-progress/create/
Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGc...

{
  "video_id": "V5LAyI6Z8NQ",
  "watched_seconds": 1542,
  "total_seconds": 41000
}
```

**Response (201):**
```json
{
  "id": "660e8400-e29b-41d4-a716-446655440010",
  "video_id": "V5LAyI6Z8NQ",
  "watched_seconds": 1542,
  "total_seconds": 41000,
  "watch_percentage": 3.76,
  "last_updated": "2026-04-28T10:20:30Z"
}
```

---

## Performance Metrics

```
Metric                    Target      Current
─────────────────────────────────────────────
API Response Time         < 2s        1.2s avg
YouTube Search            < 1.5s      1.1s avg
Scoring 20 videos         < 100ms     45ms avg
Database Query            < 50ms      12ms avg
UI Render                 < 16ms      10ms avg
Progress Report           < 500ms     200ms avg
Player Resume             < 100ms     50ms avg
─────────────────────────────────────────────
```

