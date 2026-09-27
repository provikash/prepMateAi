from django.contrib import admin
from django.contrib.auth.admin import UserAdmin as BaseUserAdmin
from django.core.exceptions import ObjectDoesNotExist
from django.urls import reverse
from django.utils.html import format_html

from .models import User


@admin.register(User)
class UserAdmin(BaseUserAdmin):
    model = User
    ordering = ("username",)
    list_display = (
        "username",
        "phone_number",
        "email",
        "name",
        "ai_credits",
        "is_staff",
        "is_active",
    )
    search_fields = ("username", "phone_number", "email", "name")
    readonly_fields = ("ai_credit_account_link",)

    fieldsets = (
        (None, {"fields": ("username", "phone_number", "email", "name", "first_name", "last_name", "password", "is_verified", "is_phone_verified", "phone_verified_at", "profile_completed")}),
        ("Permissions", {"fields": ("is_active", "is_staff", "is_superuser", "groups", "user_permissions")}),
        ("AI credits", {"fields": ("ai_credit_account_link",)}),
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

    def get_queryset(self, request):
        return super().get_queryset(request).select_related("ai_credit_account")

    def _credit_account(self, obj):
        try:
            return obj.ai_credit_account
        except ObjectDoesNotExist:
            return None

    @admin.display(description="AI credits", ordering="ai_credit_account__balance")
    def ai_credits(self, obj):
        account = self._credit_account(obj)
        if account is None:
            return "Not initialized"
        url = reverse("admin:ai_aicreditaccount_change", args=[account.pk])
        return format_html("<a href=\"{}\">{} available</a>", url, account.available)

    @admin.display(description="AI credit account")
    def ai_credit_account_link(self, obj):
        if not obj or not obj.pk:
            return "Created automatically after saving the user."
        return self.ai_credits(obj)
