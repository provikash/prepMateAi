import '../entities/ai_credit_models.dart';

abstract interface class AiCreditsRepository {
  Future<AiCreditAccount> getCreditAccount();
  Future<List<AiCreditTransaction>> getTransactions();
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
  Future<void> refresh();
}
