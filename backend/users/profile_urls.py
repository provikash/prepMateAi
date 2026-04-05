from django.urls import path

from .views import UserProfileView

urlpatterns = [
    # Example:
    path('me/', UserProfileView.as_view()),
]