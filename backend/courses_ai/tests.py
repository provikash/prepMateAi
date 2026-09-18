from unittest.mock import patch
from django.contrib.auth import get_user_model
from django.core.cache import cache
from rest_framework.test import APITestCase
from .models import CourseProgress


class CourseAPITests(APITestCase):
    def setUp(self):
        cache.clear()
        self.user = get_user_model().objects.create_user(email='courses@example.com', password='testing-password')
        self.other = get_user_model().objects.create_user(email='other@example.com', password='testing-password')
        self.client.force_authenticate(self.user)

    def test_recommendations_require_valid_skills(self):
        for skills in [[], 'python', [''], ['x' * 81], ['python'] * 16]:
            response = self.client.post('/api/v1/courses/recommendations/', {'skills': skills}, format='json')
            self.assertEqual(response.status_code, 400)

    @patch('courses_ai.views.YouTubeService')
    def test_recommendations_are_cached_and_ranked(self, service):
        service.return_value.search_playlists.return_value = [
            {'title': 'Other', 'video_count': 1}, {'title': 'Python', 'video_count': 12},
        ]
        for _ in range(2):
            response = self.client.post('/api/v1/courses/recommendations/', {'skills': ['Python']}, format='json')
            self.assertEqual(response.status_code, 200)
            self.assertEqual(response.data['results'][0]['title'], 'Python')
        service.return_value.search_playlists.assert_called_once()

    @patch('courses_ai.views.YouTubeService', side_effect=RuntimeError('provider-secret'))
    def test_provider_failure_does_not_expose_details(self, service):
        response = self.client.post('/api/v1/courses/recommendations/', {'skills': ['python']}, format='json')
        self.assertEqual(response.status_code, 503)
        self.assertNotIn('provider-secret', str(response.data))

    def test_progress_validates_times_and_is_private(self):
        payload = {'video_id': 'abcdefghijk', 'watched_seconds': 30, 'total_seconds': 60}
        response = self.client.post('/api/v1/courses/progress/', payload, format='json')
        self.assertEqual(response.status_code, 201)
        self.assertEqual(response.data['watch_percentage'], 50)
        for updates in [{'watched_seconds': -1}, {'total_seconds': 0}, {'watched_seconds': 61}, {'video_id': '../bad'}]:
            response = self.client.post('/api/v1/courses/progress/', {**payload, **updates}, format='json')
            self.assertEqual(response.status_code, 400)
        self.client.force_authenticate(self.other)
        self.assertEqual(self.client.get('/api/v1/courses/progress/').data, [])
        self.assertEqual(CourseProgress.objects.get(user=self.user).watched_seconds, 30)

    def test_anonymous_requests_are_rejected(self):
        self.client.force_authenticate(None)
        self.assertEqual(self.client.get('/api/v1/courses/progress/').status_code, 401)
