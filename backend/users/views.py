from rest_framework.views import APIView
from rest_framework.response import Response 
from rest_framework import status, permissions
from rest_framework.throttling import AnonRateThrottle, UserRateThrottle
from .serializers import RegisterSerializer, otpVerifySerializer, LoginSerializer, ChangePasswordSerializer, UserProfileSerializer
from django.contrib.auth import authenticate 
from .models import OTP, User
from rest_framework_simplejwt.tokens import RefreshToken
import random

def get_tokens_for_user(user):
    refresh = RefreshToken.for_user(user)
    return {
        'refresh': str(refresh),
        'access': str(refresh.access_token),
    }

class RegisterView(APIView):
    permission_classes = [permissions.AllowAny]
    throttle_classes = [AnonRateThrottle]
    def post(self, request):
        serializer = RegisterSerializer(data=request.data)
        if serializer.is_valid():
            user = serializer.save()
            user.is_active = False
            user.save()
            otp_code = str(random.randint(100000, 999999))
            OTP.objects.create(email=user.email, otp=otp_code, purpose='register')
            return Response({"message": "User Registered. Verify OTP.", "otp": otp_code}, status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

class LoginView(APIView):
    permission_classes = [permissions.AllowAny]
    throttle_classes = [AnonRateThrottle]
    def post(self, request):
        serializer = LoginSerializer(data=request.data)
        if serializer.is_valid():
            user = authenticate(email=serializer.validated_data['email'], password=serializer.validated_data['password'])
            if user:
                if not user.is_active:
                    return Response({"error": "Account not activated."}, status=status.HTTP_403_FORBIDDEN)
                tokens = get_tokens_for_user(user)
                return Response({"message": "Login successful", "tokens": tokens, "user": UserProfileSerializer(user).data}, status=status.HTTP_200_OK)
            return Response({"error": "Invalid credentials"}, status=status.HTTP_401_UNAUTHORIZED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

class VerifyOTPView(APIView):
    def post(self, request):
        serializer = otpVerifySerializer(data=request.data)
        if serializer.is_valid():
            otp_obj = OTP.objects.filter(email=serializer.validated_data['email'], otp=serializer.validated_data['otp']).last()
            if otp_obj and not otp_obj.is_expired():
                user = User.objects.filter(email=otp_obj.email).first()
                if user:
                    user.is_active = True
                    user.is_verified = True
                    user.save()
                    otp_obj.delete()
                    return Response({"message": "Account activated."}, status=status.HTTP_200_OK)
            return Response({"error": "Invalid or expired OTP"}, status=status.HTTP_400_BAD_REQUEST)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

class ResendOTPView(APIView):
    throttle_classes = [AnonRateThrottle]
    def post(self, request):
        email = request.data.get('email')
        user = User.objects.filter(email=email).first()
        if user and not user.is_active:
            otp_code = str(random.randint(100000, 999999))
            OTP.objects.create(email=email, otp=otp_code, purpose='register')
            return Response({"message": "OTP resent.", "otp": otp_code}, status=status.HTTP_200_OK)
        return Response({"error": "Invalid request."}, status=status.HTTP_400_BAD_REQUEST)

class LogoutView(APIView):
    permission_classes = [permissions.IsAuthenticated]
    def post(self, request):
        try:
            refresh_token = request.data["refresh"]
            token = RefreshToken(refresh_token)
            token.blacklist()
            return Response({"message": "Logged out."}, status=status.HTTP_205_RESET_CONTENT)
        except Exception:
            return Response(status=status.HTTP_400_BAD_REQUEST)

class ChangePasswordView(APIView):
    permission_classes = [permissions.IsAuthenticated]
    def post(self, request):
        serializer = ChangePasswordSerializer(data=request.data)
        if serializer.is_valid():
            if not request.user.check_password(serializer.validated_data['old_password']):
                return Response({"old_password": ["Wrong password."]}, status=status.HTTP_400_BAD_REQUEST)
            request.user.set_password(serializer.validated_data['new_password'])
            request.user.save()
            return Response({"message": "Password changed."}, status=status.HTTP_200_OK)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

class UserProfileView(APIView):
    permission_classes = [permissions.IsAuthenticated]
    def get(self, request):
        return Response(UserProfileSerializer(request.user).data)
    def patch(self, request):
        serializer = UserProfileSerializer(request.user, data=request.data, partial=True)
        if serializer.is_valid():
            serializer.save()
            return Response(serializer.data)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
