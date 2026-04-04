from django.urls import path
from .views import (
    RegisterView, LoginView, VerifyOTPView, ResendOTPView,
    LogoutView, ChangePasswordView, UserProfileView, GoogleLoginView,ForgotPasswordView,ResetPasswordView
)

urlpatterns = [
    path('register/', RegisterView.as_view(), name='register'),
    path('verify-otp/', VerifyOTPView.as_view(), name='verify_otp'),
    path('resend-otp/', ResendOTPView.as_view(), name='resend_otp'),
    path('login/', LoginView.as_view(), name='login'),
    path('logout/', LogoutView.as_view(), name='logout'),
    path('change-password/', ChangePasswordView.as_view(), name='change_password'),
    path('profile/', UserProfileView.as_view(), name='profile'),
    path("auth/google/", GoogleLoginView.as_view(), name="google-login"), # path POST /api/users/auth/google/
    path("forgot-password/",ForgotPasswordView.as_view()),
    path("reset-password/",ResetPasswordView.as_view())

   

]
