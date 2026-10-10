import hashlib
import json
import uuid

from django.conf import settings
from django.db import transaction
from django.http import JsonResponse
from django.views.decorators.csrf import csrf_exempt
from rest_framework import permissions, status
from rest_framework.response import Response
from rest_framework.views import APIView

from .models import PaymentOrder, PremiumSubscription, WebhookEvent
from .serializers import CreateOrderSerializer, VerifyPaymentSerializer
from .services import PaymentError, RazorpayClient, fulfill_order, verify_checkout_signature, verify_webhook_signature


def _product_payload(code, item):
    return {"code": code, "name": item["name"], "amount": item["amount"], "currency": settings.RAZORPAY_CURRENCY, "credits": item["credits"], "premium_days": item["premium_days"]}


def _subscription_payload(user):
    subscription = PremiumSubscription.objects.filter(user=user).first()
    if not subscription or not subscription.is_active:
        return None
    return {"plan_id": "premium", "status": "active", "started_at": subscription.started_at, "expires_at": subscription.expires_at, "auto_renew": subscription.auto_renew}


class CatalogView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request):
        products = [_product_payload(code, item) for code, item in settings.RAZORPAY_PRODUCTS.items()]
        return Response({"key_id": settings.RAZORPAY_KEY_ID, "products": products, "subscription": _subscription_payload(request.user)})


class CreateOrderView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request):
        serializer = CreateOrderSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        code = serializer.validated_data["product_code"]
        product = settings.RAZORPAY_PRODUCTS.get(code)
        if not product:
            return Response({"detail": "Unknown product."}, status=status.HTTP_400_BAD_REQUEST)
        receipt = f"pm_{uuid.uuid4().hex[:24]}"
        order = PaymentOrder.objects.create(user=request.user, product_code=code, amount=product["amount"], currency=settings.RAZORPAY_CURRENCY, credits=product["credits"], premium_days=product["premium_days"], receipt=receipt)
        try:
            remote = RazorpayClient().create_order({"amount": order.amount, "currency": order.currency, "receipt": receipt, "notes": {"local_order_id": str(order.pk), "product_code": code}, "partial_payment": False})
        except PaymentError as exc:
            order.status = PaymentOrder.Status.FAILED
            order.save(update_fields=["status", "updated_at"])
            return Response({"detail": str(exc)}, status=status.HTTP_503_SERVICE_UNAVAILABLE)
        order.razorpay_order_id = remote["id"]
        order.save(update_fields=["razorpay_order_id", "updated_at"])
        return Response({"key_id": settings.RAZORPAY_KEY_ID, "order_id": order.razorpay_order_id, "amount": order.amount, "currency": order.currency, "name": "PrepMate AI", "description": product["name"], "prefill": {"name": request.user.name, "email": request.user.email or "", "contact": request.user.phone_number or ""}}, status=status.HTTP_201_CREATED)


class VerifyPaymentView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request):
        serializer = VerifyPaymentSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        data = serializer.validated_data
        order = PaymentOrder.objects.filter(user=request.user, razorpay_order_id=data["razorpay_order_id"]).first()
        if not order:
            return Response({"detail": "Order not found."}, status=status.HTTP_404_NOT_FOUND)
        if not verify_checkout_signature(order.razorpay_order_id, data["razorpay_payment_id"], data["razorpay_signature"]):
            return Response({"detail": "Invalid payment signature."}, status=status.HTTP_400_BAD_REQUEST)
        try:
            payment = RazorpayClient().fetch_payment(data["razorpay_payment_id"])
            fulfilled, _ = fulfill_order(order.razorpay_order_id, payment)
        except PaymentError as exc:
            return Response({"detail": str(exc)}, status=status.HTTP_409_CONFLICT)
        return Response({"status": "paid", "order_id": fulfilled.razorpay_order_id, "subscription": _subscription_payload(request.user)})


class CurrentSubscriptionView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request):
        return Response(_subscription_payload(request.user))


@csrf_exempt
def razorpay_webhook(request):
    if request.method != "POST":
        return JsonResponse({"detail": "Method not allowed."}, status=405)
    if not verify_webhook_signature(request.body, request.headers.get("X-Razorpay-Signature", "")):
        return JsonResponse({"detail": "Invalid signature."}, status=400)
    try:
        payload = json.loads(request.body)
        event_type = payload.get("event", "")
        event_id = request.headers.get("X-Razorpay-Event-Id") or hashlib.sha256(request.body).hexdigest()
        with transaction.atomic():
            event, created = WebhookEvent.objects.get_or_create(event_id=event_id, defaults={"event_type": event_type, "payload_sha256": hashlib.sha256(request.body).hexdigest()})
            if not created and event.processed:
                return JsonResponse({"status": "duplicate"})
            if event_type in {"payment.captured", "order.paid"}:
                payment = payload.get("payload", {}).get("payment", {}).get("entity", {})
                if payment.get("order_id"):
                    fulfill_order(payment["order_id"], payment)
            event.processed = True
            event.error = ""
            event.save(update_fields=["processed", "error", "updated_at"])
        return JsonResponse({"status": "ok"})
    except (ValueError, PaymentOrder.DoesNotExist, PaymentError) as exc:
        return JsonResponse({"detail": str(exc)}, status=400)
