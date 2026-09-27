from django.urls import path

from .views import AuthViewSet, DashboardView, ProfileViewSet, UserProfileRetrieveUpdateView
from .account_views import (
    AccountActionChallengeView,
    AccountDeactivateView,
    AccountDeleteView,
    AuthenticatedAccountView,
    AuthenticationSchemaView,
    LogoutAllView,
    PhoneChangeRequestView,
    PhoneChangeVerifyView,
)
from .mobile_auth_views import MobileOTPVerifyView, MobileOTPView


urlpatterns = [
    path("auth/schema/", AuthenticationSchemaView.as_view(), name="authentication-schema"),
    path("auth/token/refresh/", AuthViewSet.as_view({"post": "refresh"}), name="auth-token-refresh"),
    path("auth/me/", AuthenticatedAccountView.as_view(action="me"), name="auth-me"),
    path("auth/logout/", AuthenticatedAccountView.as_view(action="logout"), name="auth-logout"),
    path("auth/logout-all/", LogoutAllView.as_view(), name="auth-logout-all"),
    path("auth/otp/request/", MobileOTPView.as_view(action="otp_request"), name="auth-otp-request"),
    path("auth/otp/verify/", MobileOTPVerifyView.as_view(), name="auth-otp-verify"),
    path("auth/otp/resend/", MobileOTPView.as_view(action="otp_resend"), name="auth-otp-resend"),
    path("auth/refresh/", AuthViewSet.as_view({"post": "refresh"}), name="auth-refresh"),
    path("auth/phone/change/request/", PhoneChangeRequestView.as_view(), name="auth-phone-change-request"),
    path("auth/phone/change/verify/", PhoneChangeVerifyView.as_view(), name="auth-phone-change-verify"),
    path("auth/account/verification/request/", AccountActionChallengeView.as_view(), name="auth-account-verification-request"),
    path("auth/account/deactivate/", AccountDeactivateView.as_view(), name="auth-account-deactivate"),
    path("auth/account/", AccountDeleteView.as_view(), name="auth-account-delete"),
    path("dashboard/", DashboardView.as_view(), name="dashboard"),
    path("profile/", UserProfileRetrieveUpdateView.as_view(), name="profile"),
    path("profile", ProfileViewSet.as_view({"get": "me", "put": "me", "patch": "me"}), name="user-profile"),
]
