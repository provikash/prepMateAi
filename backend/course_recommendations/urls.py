from django.urls import path
from . import views

app_name = "course_recommendations"

urlpatterns = [
    # Course Recommendations
    path(
        "course-recommendations/",
        views.CourseRecommendationAPIView.as_view(),
        name="course-recommendation",
    ),
    
    # Course Progress
    path(
        "course-progress/",
        views.CourseProgressListAPIView.as_view(),
        name="course-progress-list",
    ),
    path(
        "course-progress/create/",
        views.CourseProgressCreateUpdateAPIView.as_view(),
        name="course-progress-create",
    ),
    path(
        "course-progress/<str:video_id>/",
        views.CourseProgressDetailAPIView.as_view(),
        name="course-progress-detail",
    ),
]
