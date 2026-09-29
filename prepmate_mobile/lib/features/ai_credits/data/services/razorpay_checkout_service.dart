import 'dart:async';

import 'package:razorpay_flutter/razorpay_flutter.dart';

import '../../domain/entities/ai_credit_models.dart';

class CheckoutResult {
  const CheckoutResult({
    required this.paymentId,
    required this.orderId,
    required this.signature,
  });
  final String paymentId;
  final String orderId;
  final String signature;
}

class RazorpayCheckoutService {
  RazorpayCheckoutService() {
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _success);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _failure);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _wallet);
  }
  final Razorpay _razorpay = Razorpay();
  Completer<CheckoutResult>? _completer;

  Future<CheckoutResult> open(CheckoutOrder order) {
    if (_completer != null) throw StateError('A checkout is already open.');
    _completer = Completer<CheckoutResult>();
    _razorpay.open({
      'key': order.keyId,
      'order_id': order.orderId,
      'amount': order.amount,
      'currency': order.currency,
      'name': order.name,
      'description': order.description,
      'prefill': order.prefill,
      'retry': {'enabled': true, 'max_count': 4},
      'theme': {'color': '#5B5FEF'},
    });
    return _completer!.future.whenComplete(() => _completer = null);
  }

  void _success(PaymentSuccessResponse response) {
    final paymentId = response.paymentId;
    final orderId = response.orderId;
    final signature = response.signature;
    if (paymentId == null || orderId == null || signature == null) {
      _completer?.completeError(
        StateError('Razorpay returned an incomplete payment response.'),
      );
    } else {
      _completer?.complete(
        CheckoutResult(
          paymentId: paymentId,
          orderId: orderId,
          signature: signature,
        ),
      );
    }
  }

  void _failure(PaymentFailureResponse response) => _completer?.completeError(
    Exception(response.message ?? 'Payment failed.'),
  );
  void _wallet(ExternalWalletResponse response) {}
  void dispose() {
    _razorpay.clear();
    if (_completer case final completer? when !completer.isCompleted) {
      completer.completeError(StateError('Checkout closed.'));
    }
  }
}
