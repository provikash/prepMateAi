% Quick Reference - AI Course Finder
---

# 🎯 Quick Start Checklist

## Backend (Django)

```bash
# 1. Install dependencies
pip install google-api-python-client==2.120.0 python-dateutil==2.8.2

# 2. Set environment variable
export YOUTUBE_API_KEY="your_key_here"

# 3. Create migrations
python manage.py makemigrations course_recommendations

# 4. Run migrations  
python manage.py migrate course_recommendations

# 5. Start server
python manage.py runserver
```

## Frontend (Flutter)

```bash
# 1. Get dependencies
flutter pub get

# 2. Generate serializers
dart run build_runner build --delete-conflicting-outputs

# 3. Run app
flutter run
```

---

# 📂 File Locations

| Purpose | Location |
|---------|----------|
| Backend App | `backend/course_recommendations/` |
| Backend Models | `backend/course_recommendations/models.py` |
| Backend Views | `backend/course_recommendations/views.py` |
| YouTube Service | `backend/course_recommendations/services/youtube_service.py` |
| Scoring Engine | `backend/course_recommendations/services/scoring.py` |
| Flutter Models | `lib/features/courses/data/models/ai_course_model.dart` |
| Flutter Repository | `lib/features/courses/data/repositories/course_repository.dart` |
| Flutter Providers | `lib/features/courses/presentation/providers/course_providers.dart` |
| Main UI Screen | `lib/features/courses/presentation/screens/ai_course_finder_screen.dart` |
| Video Player | `lib/features/courses/presentation/screens/course_video_player_screen.dart` |
| Course Card Widget | `lib/features/courses/presentation/widgets/ai_course_card.dart` |
| Skill Summary Widget | `lib/features/courses/presentation/widgets/skill_gap_summary.dart` |

---

# 🔌 API Quick Reference

### Get Recommendations
```bash
curl -X POST http://localhost:8000/api/v1/course-recommendations/ \
  -H "Authorization: Bearer TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "skills": ["react", "state management", "clean code"]
  }'
```

### Update Progress  
```bash
curl -X POST http://localhost:8000/api/v1/course-progress/create/ \
  -H "Authorization: Bearer TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "video_id": "dQw4w9WgXcQ",
    "watched_seconds": 320,
    "total_seconds": 1200
  }'
```

### Get Progress
```bash
curl -X GET http://localhost:8000/api/v1/course-progress/dQw4w9WgXcQ/ \
  -H "Authorization: Bearer TOKEN"
```

---

# 🛠️ Common Tasks

### Add New Endpoint
1. Add serializer in `serializers.py`
2. Add view class in `views.py`
3. Register URL in `urls.py`
4. Add repository method in `course_repository.dart`
5. Add provider in `course_providers.dart`

### Modify Scoring Logic
Edit `backend/course_recommendations/services/scoring.py`:
- Adjust weights (must sum to 1.0)
- Modify keyword lists
- Change duration thresholds
- Update recency formula

### Change YouTube Search Parameters
Edit `backend/course_recommendations/services/youtube_service.py`:
- `max_results` parameter
- `videoDuration` filter (short/medium/long)
- Search order (relevance/viewCount/rating)

### Update Progress Tracking Interval
Edit `lib/features/courses/presentation/screens/course_video_player_screen.dart`:
- Line: `if ((currentPosition.inSeconds - _lastReportedPosition.inSeconds).abs() >= 5)`
- Change `5` to desired seconds

---

# 📊 Scoring Breakdown

| Factor | Weight | Purpose |
|--------|--------|---------|
| Keyword Relevance | 40% | How well title matches skills |
| Video Recency | 20% | Prefer recent over old videos |
| Engagement | 25% | Views and likes |
| Duration | 15% | Prefer 15-120 minute videos |

**Total Score Formula:**
```
score = (keyword × 0.4) + (recency × 0.2) + (engagement × 0.25) + (duration × 0.15)
```

---

# 🎨 UI Color Scheme

| Element | Color | Hex |
|---------|-------|-----|
| Primary | Purple | #7C3AED |
| Accent | Green | #10B981 |
| Warning | Orange | #F97316 |
| Error | Red | #EF4444 |
| Background | Light Purple | #F0E7FF |
| Border | Purple | #D4B3FF |

---

# 🔐 Authentication

All endpoints require:
```
Header: Authorization: Bearer {JWT_TOKEN}
```

Token is automatically added by Dio interceptor in `config/dio_client.dart`

---

# 📈 Performance Targets

| Metric | Target |
|--------|--------|
| Search response time | < 2 seconds |
| UI render time | < 16ms (60 FPS) |
| Progress report interval | 5-10 seconds |
| YouTube API quota | < 1000/day |
| Progress sync latency | < 1 second |

---

# 🐛 Debugging Tips

### Backend
```python
# Enable debug logging
import logging
logger = logging.getLogger('course_recommendations')
logger.debug(f"Message: {data}")

# Test YouTube service directly
from course_recommendations.services.youtube_service import get_youtube_service
yt = get_youtube_service()
results = yt.search_videos("react full course")
```

### Frontend
```dart
// Enable debug prints
debugPrint('Video ID: ${course.videoId}');

// Watch provider state
ref.listen(courseRecommendationsProvider, (previous, next) {
  print('Recommendations changed: $next');
});

// Check YouTube player controller
print(_youtubeController.value.isPlaying);
print(_youtubeController.metadata.duration);
```

---

# 🚀 Deployment Checklist

- [ ] Set YouTube API key
- [ ] Set DEBUG=False
- [ ] Configure ALLOWED_HOSTS
- [ ] Run migrations
- [ ] Test all endpoints
- [ ] Test video player on devices
- [ ] Verify progress persistence
- [ ] Check error handling
- [ ] Monitor API quota
- [ ] Setup database backups
- [ ] Configure CORS correctly
- [ ] Test with slow network

---

# 📚 Related Documentation

- [Full Setup Guide](./AI_COURSE_FINDER_GUIDE.md)
- [Implementation Summary](./IMPLEMENTATION_SUMMARY.md)
- YouTube API: https://developers.google.com/youtube/v3
- Riverpod: https://riverpod.dev
- Django REST: https://www.django-rest-framework.org/

---

# 💡 Tips & Tricks

1. **Fast Testing**: Use Django shell for quick queries
   ```bash
   python manage.py shell
   >>> from course_recommendations.models import CourseProgress
   >>> CourseProgress.objects.all()
   ```

2. **Quick Scoring Test**: 
   ```python
   from course_recommendations.services.scoring import get_scoring_engine
   engine = get_scoring_engine()
   score = engine.calculate_score("react", video_data, details)
   ```

3. **Riverpod Debugging**: Use DevTools console to inspect provider state

4. **YouTube Player**: Test with various video durations for UI responsiveness

5. **Progress Reset**: Admin interface to manually reset progress:
   - http://localhost:8000/admin/course_recommendations/

