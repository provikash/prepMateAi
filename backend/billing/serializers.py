from rest_framework import serializers


class CreateOrderSerializer(serializers.Serializer):
    product_code = serializers.CharField(max_length=40)


class VerifyPaymentSerializer(serializers.Serializer):
    razorpay_order_id = serializers.RegexField(r"^order_[A-Za-z0-9]+$", max_length=64)
    razorpay_payment_id = serializers.RegexField(r"^pay_[A-Za-z0-9]+$", max_length=64)
    razorpay_signature = serializers.RegexField(r"^[a-fA-F0-9]{64}$", max_length=64)
