from rest_framework.views import APIView
from rest_framework.response import Response 
from rest_framework import status
from .serializers import RegisterSerializer
from django.contrib.auth import authenticate 

class RegisterView(APIView):
  def post (self,request):
    serializer = RegisterSerializer(data=request.data)
    if serializer.is_valid():
      serializer.save()
      return Response(
        {"message":"User Registered successfully"},
        status=status.HTTP_201_CREATED 
      )
    return Response(serializer.errors,status.HTTP_400_BAD_REQUEST)

class LoginView(APIView):
  def post(self,request):
    username =request.data.get("username")
    password = request.data.get("password")
    user =authenticate(username=username,password=password)
    if user:
      return Response({"message":"Login successful","user_id":user.id,"username":user.username})
    return Response({"error": "Invalid credentials"}, status=status.HTTP_401_UNAUTHORIZED)

class VerifyOTPView(APIView):
    def post(self, request):
        return Response({"message": "Endpoint under construction"}, status=status.HTTP_501_NOT_IMPLEMENTED)

class ForgetPasswordView(APIView):
    def post(self, request):
        return Response({"message": "Endpoint under construction"}, status=status.HTTP_501_NOT_IMPLEMENTED)

class ResetPasswordView(APIView):
    def post(self, request):
        return Response({"message": "Endpoint under construction"}, status=status.HTTP_501_NOT_IMPLEMENTED)
