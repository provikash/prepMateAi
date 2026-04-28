from django.urls import path

from .views import AuthViewSet, DashboardView, ProfileViewSet, UserProfileRetrieveUpdateView


urlpatterns = [
    path("auth/register/", AuthViewSet.as_view({"post": "register"}), name="auth-register"),
    path("auth/login/", AuthViewSet.as_view({"post": "login"}), name="auth-login"),
    path("auth/refresh/", AuthViewSet.as_view({"post": "refresh"}), name="auth-refresh"),
    path("dashboard/", DashboardView.as_view(), name="dashboard"),
    path("profile/", UserProfileRetrieveUpdateView.as_view(), name="profile"),
    path("profile", ProfileViewSet.as_view({"get": "me", "put": "me", "patch": "me"}), name="user-profile"),
]
