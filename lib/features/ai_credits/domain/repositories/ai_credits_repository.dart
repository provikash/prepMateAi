import '../entities/ai_credit_models.dart';

abstract interface class AiCreditsRepository {
  Future<AiCreditAccount> getCreditAccount();
  Future<List<AiCreditTransaction>> getTransactions({
    String? filter,
    String? query,
    String? ordering,
    int? limit,
    int? offset,
  });
  Future<List<AiOperation>> getOperations();
  Future<List<SubscriptionPlan>> getPlans();
  Future<UserSubscription?> getCurrentSubscription();
  Future<List<BillingProduct>> getProducts();
  Future<CheckoutOrder> createOrder(String productCode);
  Future<void> verifyPayment({
    required String orderId,
    required String paymentId,
    required String signature,
  });
  Future<OrderStatusResult> getOrderStatus(String orderId);
  Future<OrderReceipt> getOrderReceipt(String orderId);
  Future<void> refresh();
  Future<Map<String, dynamic>> submitSupportTicket({
    required String category,
    required String subject,
    required String message,
    String? transactionReference,
    String? idempotencyKey,
    Map<String, dynamic>? metadata,
  });
}

