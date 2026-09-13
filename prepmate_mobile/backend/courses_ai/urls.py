from django.urls import path
from .views import CourseRecommendationView, CourseProgressView

urlpatterns = [
    path('recommendations/', CourseRecommendationView.as_view(), name='course-recommendations'),
    path('progress/', CourseProgressView.as_view(), name='course-progress-list'),
    path('progress/<str:video_id>/', CourseProgressView.as_view(), name='course-progress-detail'),
]
