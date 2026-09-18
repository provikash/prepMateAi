import '../../domain/entities/ai_credit_models.dart';

enum AiCreditStatus { initial, loading, loaded, refreshing, error }

class AiCreditState {
  const AiCreditState({
    this.status = AiCreditStatus.initial,
    this.account,
    this.currentSubscription,
    this.plans = const [],
    this.operations = const [],
    this.transactions = const [],
    this.error,
    this.transactionsError,
  });

  final AiCreditStatus status;
  final AiCreditAccount? account;
  final UserSubscription? currentSubscription;
  final List<SubscriptionPlan> plans;
  final List<AiOperation> operations;
  final List<AiCreditTransaction> transactions;
  final String? error;
  final String? transactionsError;

  bool get hasAccount => account != null;
  bool get isLoading => status == AiCreditStatus.loading;
  bool get isRefreshing => status == AiCreditStatus.refreshing;
  bool get hasNoCredits =>
      account != null &&
      !account!.isUnlimited &&
      account!.availableCredits == 0;
  bool get isLow =>
      account != null &&
      !account!.isUnlimited &&
      account!.monthlyAllocation > 0 &&
      account!.availableCredits > 0 &&
      account!.availableCredits <= account!.monthlyAllocation * .25;
  SubscriptionPlan? get currentPlan {
    final planId = currentSubscription?.planId;
    for (final plan in plans) {
      if (plan.id == planId || plan.slug == planId) return plan;
    }
    return null;
  }

  AiOperation? operationById(String id) {
    for (final operation in operations) {
      if (operation.operation == id) return operation;
    }
    return null;
  }

  AiCreditState copyWith({
    AiCreditStatus? status,
    AiCreditAccount? account,
    UserSubscription? currentSubscription,
    List<SubscriptionPlan>? plans,
    List<AiOperation>? operations,
    List<AiCreditTransaction>? transactions,
    String? error,
    String? transactionsError,
    bool clearError = false,
    bool clearTransactionsError = false,
  }) => AiCreditState(
    status: status ?? this.status,
    account: account ?? this.account,
    currentSubscription: currentSubscription ?? this.currentSubscription,
    plans: plans ?? this.plans,
    operations: operations ?? this.operations,
    transactions: transactions ?? this.transactions,
    error: clearError ? null : error ?? this.error,
    transactionsError: clearTransactionsError
        ? null
        : transactionsError ?? this.transactionsError,
  );
}
