from django.contrib import admin

from .models import PaymentOrder, PremiumSubscription, WebhookEvent


@admin.register(PaymentOrder)
class PaymentOrderAdmin(admin.ModelAdmin):
    list_display = ("created_at", "user", "product_code", "amount", "currency", "status", "razorpay_payment_id")
    list_filter = ("status", "product_code", "created_at")
    search_fields = ("user__phone_number", "user__email", "razorpay_order_id", "razorpay_payment_id")
    readonly_fields = tuple(field.name for field in PaymentOrder._meta.fields)


@admin.register(PremiumSubscription)
class PremiumSubscriptionAdmin(admin.ModelAdmin):
    list_display = ("user", "status", "started_at", "expires_at", "auto_renew")
    readonly_fields = tuple(field.name for field in PremiumSubscription._meta.fields)


@admin.register(WebhookEvent)
class WebhookEventAdmin(admin.ModelAdmin):
    list_display = ("created_at", "event_type", "event_id", "processed", "error")
    readonly_fields = tuple(field.name for field in WebhookEvent._meta.fields)
