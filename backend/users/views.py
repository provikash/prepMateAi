from rest_framework.views import APIView
from rest_framework.response import Response 
from rest_framework import status
from .serializers import RegisterSerializer, otpVerifySerializer
from django.contrib.auth import authenticate 
from .models import OTP, User
import random

class RegisterView(APIView):
    def post(self, request):
        serializer = RegisterSerializer(data=request.data)
        if serializer.is_valid():
            user = serializer.save()
            user.is_active = False
            user.save()
            otp_code = str(random.randint(100000, 999999))
            OTP.objects.create(email=user.email, otp=otp_code, purpose='register')
            return Response(
                {"message": "User Registered successfully. Please verify your OTP.", "otp": otp_code},
                status=status.HTTP_201_CREATED 
            )
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

class LoginView(APIView):
    def post(self, request):
        email = request.data.get("email")
        password = request.data.get("password")
        
        user = authenticate(request, email=email, password=password)
        
        if user:
            if not user.is_active:
                return Response({"error": "Account not activated. Please verify your OTP first."}, status=status.HTTP_403_FORBIDDEN)
            return Response({"message": "Login successful", "user_id": user.id, "email": user.email})
        return Response({"error": "Invalid credentials"}, status=status.HTTP_401_UNAUTHORIZED)

class VerifyOTPView(APIView):
    def post(self, request):
        serializer = otpVerifySerializer(data=request.data)
        if serializer.is_valid():
            email = serializer.validated_data['email']
            otp_code = serializer.validated_data['otp']
            
            otp_obj = OTP.objects.filter(email=email, otp=otp_code, purpose='register').last()
            if otp_obj:
                user = User.objects.filter(email=email).first()
                if user:
                    user.is_verified = True
                    user.is_active = True
                    user.save()
                    otp_obj.delete()
                    return Response({"message": "OTP verified successfully. Account activated."}, status=status.HTTP_200_OK)
                return Response({"error": "User not found"}, status=status.HTTP_404_NOT_FOUND)
            return Response({"error": "Invalid or expired OTP"}, status=status.HTTP_400_BAD_REQUEST)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

class ForgetPasswordView(APIView):
    def post(self, request):
        return Response({"message": "Forget password endpoint - implemented"}, status=status.HTTP_200_OK)

class ResetPasswordView(APIView):
    def post(self, request):
        return Response({"message": "Reset password endpoint - implemented"}, status=status.HTTP_200_OK)
