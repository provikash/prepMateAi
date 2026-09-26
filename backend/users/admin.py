from django.contrib import admin
from django.contrib.auth.admin import UserAdmin as BaseUserAdmin

from .models import User


@admin.register(User)
class UserAdmin(BaseUserAdmin):
    model = User
    ordering = ("username",)
    list_display = ("username", "phone_number", "email", "name", "is_staff", "is_active")
    search_fields = ("username", "phone_number", "email", "name")

    fieldsets = (
        (None, {"fields": ("username", "phone_number", "email", "name", "first_name", "last_name", "password", "is_verified", "is_phone_verified", "phone_verified_at", "profile_completed")}),
        ("Permissions", {"fields": ("is_active", "is_staff", "is_superuser", "groups", "user_permissions")}),
        ("Important dates", {"fields": ("last_login", "date_joined")}),
    )

    add_fieldsets = (
        (
            None,
            {
                "classes": ("wide",),
                "fields": ("username", "email", "name", "password1", "password2", "is_staff", "is_superuser"),
            },
        ),
    )
