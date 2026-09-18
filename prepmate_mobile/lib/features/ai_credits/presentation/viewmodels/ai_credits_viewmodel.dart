import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/ai_credit_models.dart';
import '../../domain/repositories/ai_credits_repository.dart';
import 'ai_credit_state.dart';

class AiCreditsViewModel extends StateNotifier<AiCreditState> {
  AiCreditsViewModel(this._repository) : super(const AiCreditState());
  final AiCreditsRepository _repository;

  Future<void> load() async {
    if (state.status == AiCreditStatus.loading) return;
    state = state.copyWith(status: AiCreditStatus.loading, clearError: true);
    try {
      final results = await Future.wait<Object?>([
        _repository.getCreditAccount(),
        _repository.getPlans(),
        _repository.getOperations(),
        _repository.getCurrentSubscription(),
      ]);
      state = state.copyWith(
        status: AiCreditStatus.loaded,
        account: results[0] as AiCreditAccount,
        plans: results[1] as List<SubscriptionPlan>,
        operations: results[2] as List<AiOperation>,
        currentSubscription: results[3] as UserSubscription?,
        clearError: true,
      );
      await loadTransactions();
    } catch (error) {
      state = state.copyWith(
        status: state.hasAccount ? AiCreditStatus.loaded : AiCreditStatus.error,
        error: _message(error),
      );
    }
  }

  Future<void> loadTransactions() async {
    try {
      final transactions = await _repository.getTransactions();
      state = state.copyWith(
        transactions: transactions,
        clearTransactionsError: true,
      );
    } catch (error) {
      state = state.copyWith(transactionsError: _message(error));
    }
  }

  Future<void> refresh() async {
    state = state.copyWith(status: AiCreditStatus.refreshing, clearError: true);
    try {
      await _repository.refresh();
      final account = await _repository.getCreditAccount();
      state = state.copyWith(status: AiCreditStatus.loaded, account: account);
      await loadTransactions();
    } catch (error) {
      state = state.copyWith(
        status: AiCreditStatus.loaded,
        error: _message(error),
      );
    }
  }

  Future<void> refreshAfterAiOperation() => refresh();

  String _message(Object error) =>
      error.toString().replaceFirst('Exception: ', '');
}
