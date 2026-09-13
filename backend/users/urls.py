from django.urls import path

from .views import AuthViewSet, DashboardView, GoogleAuthView, ProfileViewSet, UserProfileRetrieveUpdateView
from .account_views import AccountActionView, AuthenticatedAccountView, AuthenticationSchemaView


urlpatterns = [
    path("auth/schema/", AuthenticationSchemaView.as_view(), name="authentication-schema"),
    path("auth/token/refresh/", AuthViewSet.as_view({"post": "refresh"}), name="auth-token-refresh"),
    path("auth/me/", AuthenticatedAccountView.as_view(action="me"), name="auth-me"),
    path("auth/logout/", AuthenticatedAccountView.as_view(action="logout"), name="auth-logout"),
    path("auth/change-password/", AuthenticatedAccountView.as_view(action="change_password"), name="auth-change-password"),
    path("auth/deactivate/", AuthenticatedAccountView.as_view(action="deactivate"), name="auth-deactivate"),
    path("auth/account/", AuthenticatedAccountView.as_view(action="account"), name="auth-account"),
    path("auth/verify-email/", AccountActionView.as_view(action="verify"), name="auth-verify-email"),
    path("auth/verify-email/resend/", AccountActionView.as_view(action="resend"), name="auth-resend"),
    path("auth/password-reset/request/", AccountActionView.as_view(action="reset_request"), name="auth-reset-request"),
    path("auth/password-reset/confirm/", AccountActionView.as_view(action="reset_confirm"), name="auth-reset-confirm"),
    path("auth/verify-otp/", AccountActionView.as_view(action="verify")),
    path("users/verify-otp/", AccountActionView.as_view(action="verify")),
    path("auth/forgot-password/", AccountActionView.as_view(action="reset_request")),
    path("auth/register/", AuthViewSet.as_view({"post": "register"}), name="auth-register"),
    path("auth/login/", AuthViewSet.as_view({"post": "login"}), name="auth-login"),
    path("auth/refresh/", AuthViewSet.as_view({"post": "refresh"}), name="auth-refresh"),
    path("auth/google/", GoogleAuthView.as_view(), name="auth-google"),
    path("dashboard/", DashboardView.as_view(), name="dashboard"),
    path("profile/", UserProfileRetrieveUpdateView.as_view(), name="profile"),
    path("profile", ProfileViewSet.as_view({"get": "me", "put": "me", "patch": "me"}), name="user-profile"),
]
