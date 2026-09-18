import '../entities/ai_credit_models.dart';

abstract interface class AiCreditsRepository {
  Future<AiCreditAccount> getCreditAccount();
  Future<List<AiCreditTransaction>> getTransactions();
  Future<List<AiOperation>> getOperations();
  Future<List<SubscriptionPlan>> getPlans();
  Future<UserSubscription?> getCurrentSubscription();
  Future<void> refresh();
}
