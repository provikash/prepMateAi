from django.urls import path

from .views import UserProfileRetrieveUpdateView

urlpatterns = [
    # Example:
    path('me/', UserProfileRetrieveUpdateView.as_view()),
]