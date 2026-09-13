from django.contrib.auth.models import AbstractUser, BaseUserManager
from django.db import models
from django.db.models.functions import Lower
from django.utils import timezone


class UserManager(BaseUserManager):
    use_in_migrations = True

    @classmethod
    def normalize_email(cls, email):
        return (email or "").strip().lower()

    def _create_user(self, email, password, **extra_fields):
        email = self.normalize_email(email)
        if not email:
            raise ValueError("The email field must be set.")
        if not password:
            raise ValueError("Password is required. Use an explicit unusable password for OAuth accounts.")

        email = self.normalize_email(email)
        extra_fields.setdefault("username", email)

        user = self.model(email=email, **extra_fields)
        user.set_password(password)
        from django.db import transaction
        with transaction.atomic(using=self._db):
            user.save(using=self._db)
        return user

    def create_user(self, email, password=None, **extra_fields):
        extra_fields.setdefault("is_staff", False)
        extra_fields.setdefault("is_superuser", False)
        extra_fields.setdefault("name", email)
        return self._create_user(email, password, **extra_fields)

    def create_superuser(self, email, password=None, **extra_fields):
        extra_fields.setdefault("is_staff", True)
        extra_fields.setdefault("is_superuser", True)
        extra_fields.setdefault("name", email)

        if extra_fields.get("is_staff") is not True:
            raise ValueError("Superuser must have is_staff=True.")
        if extra_fields.get("is_superuser") is not True:
            raise ValueError("Superuser must have is_superuser=True.")

        return self._create_user(email, password, **extra_fields)


class User(AbstractUser):
    username = models.CharField(max_length=255, unique=True)
    email = models.EmailField(unique=True, max_length=255)
    name = models.CharField(max_length=255)
    avatar_url = models.URLField(max_length=1024, blank=True, null=True)
    is_verified = models.BooleanField(default=False)
    created_at = models.DateTimeField(default=timezone.now, editable=False)
    updated_at = models.DateTimeField(auto_now=True)
    deleted_at = models.DateTimeField(null=True, blank=True, editable=False)

    objects = UserManager()

    USERNAME_FIELD = "email"
    REQUIRED_FIELDS = []

    class Meta:
        constraints = [models.UniqueConstraint(Lower("email"), name="users_email_ci_unique")]

    @property
    def is_email_verified(self):
        return self.is_verified

    def save(self, *args, **kwargs):
        if self.email:
            self.email = UserManager.normalize_email(self.email)
            self.username = self.email
        super().save(*args, **kwargs)

    @property
    def full_name(self):
        return self.name

    @full_name.setter
    def full_name(self, value):
        self.name = value

    def __str__(self):
        return self.email


class UserProfile(models.Model):
    user = models.OneToOneField(User, on_delete=models.CASCADE, related_name="profile")
    full_name = models.CharField(max_length=255, blank=True, default="")
    phone = models.CharField(max_length=30, blank=True, default="")
    location = models.CharField(max_length=255, blank=True, default="")
    job_title = models.CharField(max_length=120, blank=True, default="")
    bio = models.TextField(blank=True, default="")
    linkedin = models.URLField(max_length=1024, blank=True, default="")
    github = models.URLField(max_length=1024, blank=True, default="")
    portfolio_url = models.URLField(max_length=1024, blank=True, default="")
    created_at = models.DateTimeField(default=timezone.now, editable=False)
    profile_image = models.ImageField(upload_to="users/profile_images/", blank=True, null=True)
    updated_at = models.DateTimeField(auto_now=True)

    def __str__(self):
        return f"Profile<{self.user.email}>"


class EmailOTP(models.Model):
    class Purpose(models.TextChoices):
        EMAIL_VERIFICATION = "EMAIL_VERIFICATION", "Email verification"
        PASSWORD_RESET = "PASSWORD_RESET", "Password reset"

    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name="email_otps")
    code_hash = models.CharField(max_length=128)
    purpose = models.CharField(max_length=24, choices=Purpose.choices)
    expires_at = models.DateTimeField(db_index=True)
    attempt_count = models.PositiveSmallIntegerField(default=0)
    is_used = models.BooleanField(default=False)
    created_at = models.DateTimeField(default=timezone.now, editable=False)

    class Meta:
        indexes = [models.Index(fields=["user", "purpose", "-created_at"], name="users_otp_lookup")]
        constraints = [models.UniqueConstraint(fields=["user", "purpose"], condition=models.Q(is_used=False), name="users_one_active_otp")]
