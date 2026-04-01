from django.urls import path 
from .views import ResumeCreateView, ResumeListView , ResumeDetailView

urlpatterns =[
    path('create/',ResumeCreateView.as_view()),
    path('',ResumeListView.as_view()),
    path('<int:pk>/',ResumeDetailView.as_view()),
]