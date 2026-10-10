from django.urls import path

from .views import CatalogView, CreateOrderView, CurrentSubscriptionView, VerifyPaymentView, razorpay_webhook

urlpatterns = [
    path("catalog/", CatalogView.as_view(), name="billing-catalog"),
    path("orders/", CreateOrderView.as_view(), name="billing-create-order"),
    path("orders/verify/", VerifyPaymentView.as_view(), name="billing-verify-payment"),
    path("subscription/", CurrentSubscriptionView.as_view(), name="billing-current-subscription"),
    path("webhooks/razorpay/", razorpay_webhook, name="billing-razorpay-webhook"),
]
