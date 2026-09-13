# AI Course Finder - Full-Stack Implementation Guide

## Overview

This guide covers the complete AI Course Finder feature implementation for PrepMate - an AI-powered learning platform that recommends personalized courses based on skill gaps from resume analysis.

---

## Backend Setup (Django)

### 1. Database Migrations

Run migrations to create the new models:

```bash
cd backend
python manage.py makemigrations course_recommendations
python manage.py migrate course_recommendations
```

This creates two tables:
- `course_recommendations_courserecommendation` - Caches YouTube course recommendations
- `course_recommendations_courseprogress` - Tracks user's watch progress per video

### 2. Environment Variables

Add to your `.env` file:

```env
# YouTube API Configuration
YOUTUBE_API_KEY=your_youtube_api_v3_key_here

# Optional: for production, ensure these are set
DEBUG=False
ALLOWED_HOSTS=your_domain.com
```

**Get YouTube API Key:**
1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create a new project
3. Enable "YouTube Data API v3"
4. Create API Key credentials
5. Restrict to "YouTube Data API v3"

### 3. Install Dependencies

```bash
pip install -r requirements.txt
```

Key new dependencies:
- `google-api-python-client==2.120.0` - YouTube API client
- `python-dateutil==2.8.2` - Date parsing utilities

### 4. Admin Panel

Access Django admin to view cached recommendations and user progress:

```
http://localhost:8000/admin/course_recommendations/
```

---

## Backend API Endpoints

### 1. Get Course Recommendations

**Endpoint:** `POST /api/v1/course-recommendations/`

**Authentication:** Required (JWT Bearer token)

**Request:**
```json
{
  "skills": ["react", "state management", "clean code"]
}
```

**Response:**
```json
{
  "results": [
    {
      "id": "uuid",
      "title": "React JS Full Course for Beginners",
      "channel": "freeCodeCamp",
      "video_id": "abc123xyz",
      "thumbnail": "https://i.ytimg.com/...",
      "duration": "PT1H30M45S",
      "video_count": 0,
      "match_score": 92.5,
      "created_at": "2026-04-28T10:00:00Z"
    }
    // ... more results
  ]
}
```

**Logic:**
1. Builds search query: "react state management clean code full course playlist tutorial"
2. Searches YouTube for matching videos
3. Extracts metadata (title, channel, thumbnail, duration, view count)
4. Calculates match score based on:
   - Keyword relevance (40%)
   - Video recency (20%)
   - Engagement metrics (25%)
   - Duration appropriateness (15%)
5. Returns top 12 results sorted by match score

### 2. Update Course Progress

**Endpoint:** `POST /api/v1/course-progress/create/`

**Authentication:** Required

**Request:**
```json
{
  "video_id": "abc123",
  "watched_seconds": 320,
  "total_seconds": 1200
}
```

**Response:**
```json
{
  "id": "uuid",
  "video_id": "abc123",
  "watched_seconds": 320,
  "total_seconds": 1200,
  "watch_percentage": 26.67,
  "last_updated": "2026-04-28T10:05:00Z"
}
```

**Behavior:**
- Creates new progress record or updates existing
- Called by mobile app every 5-10 seconds during playback
- Persists on server for resume capability

### 3. Get Course Progress for Video

**Endpoint:** `GET /api/v1/course-progress/{video_id}/`

**Authentication:** Required

**Response:**
```json
{
  "video_id": "abc123",
  "watched_seconds": 320,
  "total_seconds": 1200,
  "watch_percentage": 26.67,
  "last_updated": "2026-04-28T10:05:00Z"
}
```

**Note:** Returns zero progress if video never watched by user

### 4. Get All Course Progress

**Endpoint:** `GET /api/v1/course-progress/`

**Authentication:** Required

**Response:**
```json
[
  {
    "id": "uuid",
    "video_id": "abc123",
    "watched_seconds": 320,
    "total_seconds": 1200,
    "watch_percentage": 26.67,
    "last_updated": "2026-04-28T10:05:00Z"
  }
  // ... more progress records
]
```

---

## Backend Architecture

### Services

#### `services/youtube_service.py`
- **`search_videos(query, max_results=20)`** - Search YouTube for videos
- **`get_video_details(video_id)`** - Fetch view count, duration, likes
- **`_normalize_results(response)`** - Convert API response to standard format

#### `services/scoring.py`
- **`calculate_score(query, video_data, video_details)`** - Compute 0-100 match score
- **Factors:**
  - Keyword matching in title/description
  - High-value keywords (full course, tutorial, etc.)
  - Video recency (prefer videos < 2 years old)
  - View count engagement
  - Duration appropriateness (15-120 minutes preferred)
- **`rank_results(results, query, video_details_map)`** - Sort by score

### Data Flow

```
Request: { skills: [...] }
    ↓
build_query() → "skill1 skill2 full course playlist..."
    ↓
youtube_service.search_videos()
    ↓
get_video_details() for each result
    ↓
scoring_engine.rank_results()
    ↓
Cache in database
    ↓
Response: { results: [...] }
```

---

## Frontend Setup (Flutter)

### 1. Add JSON Generation

Update `pubspec.yaml`:

```yaml
dev_dependencies:
  build_runner: ^2.4.0
  json_serializable: ^6.7.0
```

Generate serializers:
```bash
cd prepmate_mobile
flutter pub get
dart run build_runner build --delete-conflicting-outputs
```

### 2. File Structure

```
lib/features/courses/
├── data/
│   ├── models/
│   │   ├── ai_course_model.dart (NEW)
│   │   └── course_model.dart
│   └── repositories/
│       └── course_repository.dart (NEW)
├── domain/
└── presentation/
    ├── providers/
    │   └── course_providers.dart (UPDATED)
    ├── screens/
    │   ├── ai_course_finder_screen.dart (NEW)
    │   └── course_video_player_screen.dart (NEW)
    └── widgets/
        ├── ai_course_card.dart (NEW)
        └── skill_gap_summary.dart (NEW)
```

### 3. Riverpod Providers

#### `courseRecommendationsProvider`
- Manages list of AI-recommended courses
- AsyncNotifier pattern
- Methods: `fetchRecommendations(skills)`, `refresh(skills)`

#### `courseProgressProvider(videoId)`
- Manages progress for individual video
- Family AsyncNotifier
- Methods: `updateProgress(watchedSeconds, totalSeconds)`, `refresh()`

#### `allCourseProgressProvider`
- Manages all user's progress records
- Used for "Continue Learning" section

#### `skillGapProvider`
- Manages list of missing skills from resume analyzer
- TODO: Integrate with existing resume_analyzer API

#### `currentVideoIdProvider`
- StateNotifier for currently playing video
- Used to sync UI state across screens

#### `continueLearningProvider`
- Computed provider combining recommendations + progress
- Filters to videos that are started but not completed

### 4. Models

#### `AICourse`
```dart
final String id;              // UUID
final String title;           // "React JS Full Course"
final String channel;         // "freeCodeCamp"
final String videoId;         // YouTube video ID
final String thumbnail;       // Image URL
final String? duration;       // ISO 8601 duration
final int videoCount;         // For playlists
final double matchScore;      // 0-100
final String createdAt;       // Timestamp
```

#### `CourseProgress`
```dart
final String? id;             // UUID
final String videoId;         // YouTube video ID
final int watchedSeconds;     // Seconds watched
final int totalSeconds;       // Total video duration
final double watchPercentage; // 0-100
final String? lastUpdated;    // Timestamp

// Computed properties:
bool get isCompleted;         // > 95%
bool get hasStarted;          // > 0 seconds
```

### 5. Repository

`CourseRepository` handles all API calls:

```dart
// Get recommendations
getCourseRecommendations(skills: List<String>)

// Get single video progress
getCourseProgress(videoId: String)

// Get all progress
getAllCourseProgress()

// Update progress (called every 5-10 seconds)
updateCourseProgress(videoId, watchedSeconds, totalSeconds)
```

---

## Frontend UI Screens

### AI Course Finder Screen (Main)

**Sections (top to bottom):**

1. **Header**
   - Title: "Courses"
   - Subtitle: "Personalized courses based on your Skill Gap"

2. **AI Search Box**
   - Purple gradient container
   - Search icon with "AI Course Finder" label
   - Pre-filled with skill keywords
   - Search button triggers `fetchRecommendations()`
   - "Powered by Skill Analyzer" badge

3. **Skill Gap Summary Card**
   - Overall Score circular progress (62%)
   - Top Missing Skills chips (State Management, Testing, etc.)
   - Recommended Focus box

4. **Continue Learning Section** (if available)
   - Card with thumbnail, title, progress bar
   - Resume button opens video player
   - Shows percentage watched

5. **Recommended Playlists**
   - Horizontal scrollable list
   - Each card shows:
     - Thumbnail with YouTube play button overlay
     - Match % badge (top-right)
     - Title + Channel name
     - Duration + Video count
   - Tap to open video player

### Video Player Screen

**Components:**

1. **YouTube Player**
   - `youtube_player_flutter` widget
   - Full-screen capable
   - Progress indicator with timestamp
   - Resumes from saved position

2. **Video Info Section**
   - Title and channel
   - Watch progress bar with percentage
   - Current time / Total time
   - Match score badge
   - Completion congratulations (if > 95%)

3. **Progress Tracking**
   - Every 5-10 seconds, updates backend
   - Survives app exit/resume
   - Calculated from `watched_seconds / total_seconds`

---

## Integration Checklist

### Backend
- [ ] Create migrations and run database setup
- [ ] Add YouTube API key to environment
- [ ] Install new dependencies (google-api-python-client, python-dateutil)
- [ ] Test API endpoints with Postman/curl
- [ ] Verify YouTube service fetches results
- [ ] Check scoring engine calculates correctly
- [ ] Test resume progress endpoints

### Frontend
- [ ] Run `flutter pub get`
- [ ] Generate JSON serializers (`dart run build_runner build`)
- [ ] Add models (AI course, progress)
- [ ] Create repository for API calls
- [ ] Implement Riverpod providers
- [ ] Build UI screens (course finder, video player)
- [ ] Test with hot reload
- [ ] Verify progress tracking works
- [ ] Test resume from saved position

### Integration
- [ ] Update main app to include AI Course Finder screen in navigation
- [ ] Connect skill gap data from resume analyzer
- [ ] Test end-to-end: analyze resume → get skills → search courses → watch video → track progress
- [ ] Handle auth token refresh in interceptors
- [ ] Add error handling for network failures

---

## Error Handling

### Backend Errors

- **401 Unauthorized** - Invalid/expired JWT token
  - Frontend should redirect to login

- **YouTube API Failure** - API key invalid or quota exceeded
  - Returns 500 with error message
  - Frontend shows fallback message

- **No Results** - Query doesn't match any videos
  - Returns 200 with empty results array

### Frontend Errors

- **Loading State** - Show skeleton/shimmer while fetching
- **Error State** - Show error message with retry button
- **Player Errors** - Try resuming, show message if fails
- **Network Timeout** - Implement retry logic with exponential backoff

---

## Performance Tips

### Backend
1. **Cache recommendations** - Database stores recent searches
2. **Lazy load video details** - Only fetch for top results
3. **YouTube API quota** - Free tier: 10,000 units/day
   - Each search: ~100 units
   - Each video.list: ~1 unit

### Frontend
1. **Image caching** - Use `cached_network_image` plugin
2. **Lazy load recommendations** - Pagination after first 12
3. **Minimize API calls** - Batch progress updates (every 10 seconds, not every second)
4. **Riverpod caching** - Providers cache results automatically

---

## Testing

### Backend API Tests

```bash
# Get recommendations
curl -X POST http://localhost:8000/api/v1/course-recommendations/ \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"skills": ["react", "state management"]}'

# Update progress
curl -X POST http://localhost:8000/api/v1/course-progress/create/ \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"video_id": "abc123", "watched_seconds": 320, "total_seconds": 1200}'

# Get progress
curl -X GET http://localhost:8000/api/v1/course-progress/abc123/ \
  -H "Authorization: Bearer YOUR_TOKEN"
```

### Frontend Testing

1. **Unit Tests** - Test scoring engine logic
2. **Widget Tests** - Test UI components
3. **Integration Tests** - Test full flow

---

## Deployment Considerations

### Backend
- [ ] Set `DEBUG=False` in production
- [ ] Use strong `SECRET_KEY`
- [ ] Configure `ALLOWED_HOSTS`
- [ ] Use environment-specific YouTube API key
- [ ] Enable CORS only for frontend domain
- [ ] Set up database backups
- [ ] Monitor YouTube API quota usage

### Frontend
- [ ] Update API base URL to production
- [ ] Test on physical devices
- [ ] Configure app signing (Android/iOS)
- [ ] Test with slow network conditions
- [ ] Verify video player works on all devices

---

## Future Enhancements

1. **Search Customization** - Allow users to enter custom search queries
2. **Playlist Support** - Group related videos into learning paths
3. **Social Features** - Share courses, recommendations with others
4. **Offline Playback** - Download videos for offline viewing
5. **Advanced Analytics** - Insights on learning patterns
6. **AI Tutor** - Chat with AI about course content
7. **Certificates** - Generate completion certificates
8. **Integration with Udemy/Coursera** - Expand course sources beyond YouTube

---

## Troubleshooting

### YouTube API Issues
- **"Quota exceeded"** - Upgrade to paid plan or wait 24 hours
- **"Invalid API key"** - Verify key in environment and API is enabled
- **"No results"** - Try simpler search queries

### Frontend Issues
- **Player doesn't resume** - Ensure progress is saved to backend
- **Progress not tracking** - Check network connectivity
- **Crashes on video select** - Verify video_id is valid

### Scoring Issues
- **All scores similar** - Adjust weighting factors in `scoring.py`
- **Wrong videos ranked first** - Check keyword relevance logic

---

## Support & Debugging

For issues:
1. Check backend logs: `docker logs prepmate-backend` or console output
2. Check frontend logs: Flutter DevTools console
3. Verify API response: Use Postman/curl
4. Check YouTube API quotas: Google Cloud Console
5. Enable debug mode: `debugPrint()` in Flutter, `logger.debug()` in Django

