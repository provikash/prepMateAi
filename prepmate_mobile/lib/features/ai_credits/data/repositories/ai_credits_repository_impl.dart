import '../../domain/entities/ai_credit_models.dart';
import '../../domain/repositories/ai_credits_repository.dart';
import '../datasources/ai_credits_remote_datasource.dart';
import '../models/ai_credit_models.dart';

class AiCreditsRepositoryImpl implements AiCreditsRepository {
  const AiCreditsRepositoryImpl(this._remote);
  final AiCreditsRemoteDataSource _remote;

  @override
  Future<AiCreditAccount> getCreditAccount() async =>
      AiCreditAccountModel.fromJson(await _remote.getAccount());
  @override
  Future<List<AiCreditTransaction>> getTransactions() async =>
      (await _remote.getTransactions())
          .map(AiCreditTransactionModel.fromJson)
          .toList();
  @override
  Future<List<AiOperation>> getOperations() async =>
      (await _remote.getOperations()).map(AiOperationModel.fromJson).toList();
  @override
  Future<List<SubscriptionPlan>> getPlans() async =>
      (await _remote.getPlans()).map(SubscriptionPlanModel.fromJson).toList();
  @override
  Future<UserSubscription?> getCurrentSubscription() async {
    final value = await _remote.getCurrentSubscription();
    return value == null ? null : UserSubscriptionModel.fromJson(value);
  }

  @override
  Future<void> refresh() async {}
}
