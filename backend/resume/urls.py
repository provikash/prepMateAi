from django.urls import path
from .views import ResumeListCreateView, ResumeDetailView

urlpatterns = [
    path('', ResumeListCreateView.as_view()),       # GET + POST
    path('<int:pk>/', ResumeDetailView.as_view()),  # GET + PUT + DELETE
]