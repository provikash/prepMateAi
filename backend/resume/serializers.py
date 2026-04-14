from rest_framework import serializers
from .models import Resume

class ResumeSerializer(serializers.ModelSerializer):
    class Meta:
        model = Resume
        fields = ['id', 'user','title', 'template','canvas_data','created_at','uploaded_at']
        read_only_fields=['id','user', 'created_at','updated_at']