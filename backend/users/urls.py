from django.urls import path
from .views import(RegisterView,LoginView,VerifyOTPView,ResetPasswordView,ForgetPasswordView)

urlpatterns= [
  path('register/', RegisterView.as_view(),name='register'),
  path('verify-otp/',VerifyOTPView.as_view(),name='verify_otp'),
  path('login/',LoginView.as_view(),name='login'),
  path('forget-password/',ForgetPasswordView.as_view(),name='forget_password'),
  path('reset-password/',ResetPasswordView.as_view(),name='reset_password')
]