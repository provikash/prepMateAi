import uuid

from django import forms
from django.contrib import admin, messages
from django.conf import settings

from .models import AICreditAccount, AICreditTransaction, AIUsage
from .services.credits import CreditService


class CreditAdjustmentForm(forms.ModelForm):
    adjustment = forms.IntegerField(
        label="Credit adjustment",
        help_text="Use a positive number to grant credits or a negative number to deduct them.",
    )
    reason = forms.CharField(
        max_length=255,
        widget=forms.Textarea(attrs={"rows": 3}),
        help_text="Required audit reason. Do not include secrets or payment-card data.",
    )
    adjustment_id = forms.UUIDField(
        widget=forms.HiddenInput,
        initial=uuid.uuid4,
    )

    class Meta:
        model = AICreditAccount
        fields = ()

    def clean(self):
        cleaned = super().clean()
        delta = cleaned.get("adjustment")
        if delta is None:
            return cleaned
        if delta == 0:
            self.add_error("adjustment", "Adjustment cannot be zero.")
        elif abs(delta) > settings.AI_ADMIN_MAX_ADJUSTMENT:
            self.add_error(
                "adjustment",
                f"One adjustment cannot exceed {settings.AI_ADMIN_MAX_ADJUSTMENT} credits.",
            )
        elif self.instance.pk:
            balance_after = self.instance.balance + delta
            if balance_after < self.instance.reserved_credits:
                self.add_error(
                    "adjustment",
                    "The balance cannot be lower than currently reserved credits.",
                )
            elif balance_after > settings.AI_CREDIT_MAX_BALANCE:
                self.add_error(
                    "adjustment",
                    f"The balance cannot exceed {settings.AI_CREDIT_MAX_BALANCE} credits.",
                )
        return cleaned


@admin.register(AICreditAccount)
class AICreditAccountAdmin(admin.ModelAdmin):
    form = CreditAdjustmentForm
    list_display = (
        "user_identifier",
        "balance",
        "reserved_credits",
        "available_credits",
        "lifetime_earned",
        "lifetime_used",
        "updated_at",
    )
    search_fields = ("user__phone_number", "user__email", "user__name", "user__username")
    list_select_related = ("user",)
    ordering = ("-updated_at",)
    readonly_fields = (
        "user",
        "balance",
        "reserved_credits",
        "available_credits",
        "lifetime_earned",
        "lifetime_used",
        "created_at",
        "updated_at",
    )
    fields = (
        "user",
        "balance",
        "reserved_credits",
        "available_credits",
        "lifetime_earned",
        "lifetime_used",
        "adjustment",
        "reason",
        "adjustment_id",
        "created_at",
        "updated_at",
    )

    @admin.display(description="User", ordering="user__phone_number")
    def user_identifier(self, obj):
        return obj.user.phone_number or obj.user.email or obj.user.username

    @admin.display(description="Available")
    def available_credits(self, obj):
        return obj.available

    def has_add_permission(self, request):
        return False

    def has_delete_permission(self, request, obj=None):
        return False

    def save_model(self, request, obj, form, change):
        account, transaction_entry, created = CreditService.adjust(
            account=obj,
            delta=form.cleaned_data["adjustment"],
            reason=form.cleaned_data["reason"],
            performed_by=request.user,
            idempotency_key=form.cleaned_data["adjustment_id"],
        )
        obj.balance = account.balance
        obj.lifetime_earned = account.lifetime_earned
        if created:
            self.message_user(
                request,
                f"Credit balance updated to {account.balance}. Ledger entry: {transaction_entry.pk}.",
                level=messages.SUCCESS,
            )
        else:
            self.message_user(
                request,
                "This adjustment was already applied; no duplicate credits were added.",
                level=messages.WARNING,
            )


class ReadOnlyLedgerAdmin(admin.ModelAdmin):
    actions = None

    def has_add_permission(self, request):
        return False

    def has_change_permission(self, request, obj=None):
        return False

    def has_view_permission(self, request, obj=None):
        return super().has_view_permission(request, obj)

    def has_delete_permission(self, request, obj=None):
        return False

    def get_readonly_fields(self, request, obj=None):
        return tuple(field.name for field in self.model._meta.fields)

    def save_model(self, request, obj, form, change):
        raise PermissionError("Ledger records are immutable.")


@admin.register(AICreditTransaction)
class AICreditTransactionAdmin(ReadOnlyLedgerAdmin):
    list_display = (
        "created_at",
        "user",
        "transaction_type",
        "amount",
        "balance_before",
        "balance_after",
        "operation",
        "performed_by",
    )
    list_filter = ("transaction_type", "operation", "created_at")
    search_fields = (
        "user__phone_number",
        "user__email",
        "description",
        "idempotency_key",
    )
    list_select_related = ("user", "performed_by")
    date_hierarchy = "created_at"


@admin.register(AIUsage)
class AIUsageAdmin(ReadOnlyLedgerAdmin):
    list_display = (
        "created_at",
        "user",
        "operation",
        "status",
        "credits_reserved",
        "credits_used",
        "model",
        "latency_ms",
    )
    list_filter = ("status", "operation", "provider", "created_at")
    search_fields = ("user__phone_number", "user__email", "request_id", "idempotency_key")
    list_select_related = ("user",)
    date_hierarchy = "created_at"
