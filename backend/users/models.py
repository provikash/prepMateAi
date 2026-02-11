# users/models.py
from django.db import models
from django.contrib.auth.models import AbstractUser
from django.utils import timezone


class User(AbstractUser):
    """
    Custom User model that uses email as the primary login field.
    """
    email = models.EmailField(
        unique=True,
        verbose_name='email address',
        max_length=255,
        error_messages={
            'unique': "A user with that email already exists.",
        },
    )

    # Make username optional (we'll use email as the main identifier)
    username = models.CharField(
        max_length=150,
        unique=False,           # not enforcing uniqueness here
        blank=True,
        null=True,
    )

    # Override the USERNAME_FIELD to use email instead of username
    USERNAME_FIELD = 'email'
    REQUIRED_FIELDS = []  # No additional required fields

    # Important: remove username from required fields during creation
    def __str__(self):
        return self.email

    class Meta:
        verbose_name = 'user'
        verbose_name_plural = 'users'
        ordering = ['email']


class OTP(models.Model):
    """
    One-time password model used for email verification and password reset.
    """
    user = models.ForeignKey(
        User,
        on_delete=models.CASCADE,
        related_name='otps'
    )
    otp_code = models.CharField(
        max_length=6,
        verbose_name='OTP Code'
    )
    created_at = models.DateTimeField(
        auto_now_add=True,
        verbose_name='Created At'
    )
    is_verified = models.BooleanField(
        default=False,
        verbose_name='Verified'
    )
    purpose = models.CharField(
        max_length=20,
        choices=[
            ('registration', 'Registration'),
            ('password_reset', 'Password Reset'),
        ],
        default='registration',
        verbose_name='Purpose'
    )

    class Meta:
        verbose_name = 'OTP'
        verbose_name_plural = 'OTPs'
        ordering = ['-created_at']
        indexes = [
            models.Index(fields=['user', 'otp_code', 'is_verified']),
        ]

    def __str__(self):
        return f"{self.user.email} - {self.otp_code} ({self.purpose})"

    def is_expired(self):
        """Check if OTP has expired (10 minutes validity)"""
        expiry_time = self.created_at + timezone.timedelta(minutes=10)
        return timezone.now() > expiry_time

    def clean_expired(self):
        """Delete this OTP if expired"""
        if self.is_expired():
            self.delete()
            return True
        return False