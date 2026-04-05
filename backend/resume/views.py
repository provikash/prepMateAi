from django.shortcuts import render
from rest_framework import generics, permissions
from .models import Resume
from .serializers import ResumeSerializer



# Create your views here.

class ResumeListCreateView(generics.ListCreateAPIView):  # ✅ FIX
    serializer_class = ResumeSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        return Resume.objects.filter(user=self.request.user)

    def perform_create(self, serializer):
        serializer.save(user=self.request.user)




    

#Retrive + Update +Delete 

class ResumeDetailView(generics.RetrieveUpdateDestroyAPIView):
    serializer_class = ResumeSerializer
    permission_classes =[permissions.IsAuthenticated]

    def get_queryset(self):
        return Resume.objects.filter(user=self.request.user)
