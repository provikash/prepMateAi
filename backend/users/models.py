from django.contrib.auth.models import AbstractUser, PermissionsMixin, BaseUserManager
from django.db import models
from django.utils import timezone

class CustomUserManager(BaseUserManager):
    def create_user(self, email, password=None, **extra_fields):
        if not email:
            raise ValueError('The Email is required')
        email = self.normalize_email(email)
        user = self.model(email=email, **extra_fields)
        user.set_password(password)
        user.save(using=self._db)
        return user

    def create_superuser(self, email, password=None, **extra_fields):
        extra_fields.setdefault('is_staff', True)
        extra_fields.setdefault('is_superuser', True)
        extra_fields.setdefault('is_active', True)
        return self.create_user(email, password, **extra_fields)

class User(AbstractUser, PermissionsMixin):
    email = models.EmailField(unique=True)
    is_active = models.BooleanField(default=True)
    is_staff = models.BooleanField(default=False)
    is_verified = models.BooleanField(default=False)
    date_joined = models.DateTimeField(default=timezone.now)
    
    username = models.CharField(max_length=150, unique=True)
    USERNAME_FIELD = 'email'
    REQUIRED_FIELDS = ['username']

    objects = CustomUserManager()

    def __str__(self):
        return self.email

class OTP(models.Model):
    PURPOSE_CHOICES = (
        ('register', 'Register'),
        ('reset', 'Reset Password'),
    )
    
    email = models.EmailField()
    otp = models.CharField(max_length=6)
    created_at = models.DateTimeField(auto_now_add=True)
    purpose = models.CharField(max_length=20, choices=PURPOSE_CHOICES)

    def __str__(self):
        return f"{self.email}-{self.purpose}"
