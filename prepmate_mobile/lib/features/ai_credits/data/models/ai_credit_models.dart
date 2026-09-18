import '../../domain/entities/ai_credit_models.dart';

Map<String, dynamic> _map(Object? value) =>
    value is Map ? Map<String, dynamic>.from(value) : const {};
int _int(Object? value, [int fallback = 0]) =>
    value is num ? value.toInt() : int.tryParse('$value') ?? fallback;
double _double(Object? value, [double fallback = 0]) =>
    value is num ? value.toDouble() : double.tryParse('$value') ?? fallback;
DateTime? _date(Object? value) =>
    value == null ? null : DateTime.tryParse('$value');

final class AiCreditAccountModel {
  static AiCreditAccount fromJson(Map<String, dynamic> json) => AiCreditAccount(
    balance: _int(json['balance'] ?? json['remaining_credits']),
    reservedCredits: _int(json['reserved_credits']),
    monthlyAllocation: _int(
      json['monthly_allocation'] ?? json['total_credits'],
    ),
    usedThisCycle: _int(json['used_this_cycle'] ?? json['used_credits']),
    lifetimeEarned: _int(json['lifetime_earned']),
    lifetimeUsed: _int(json['lifetime_used']),
    resetDate: _date(json['reset_date']),
    isUnlimited: json['is_unlimited'] == true,
  );
}

final class AiOperationModel {
  static AiOperation fromJson(Map<String, dynamic> json) => AiOperation(
    operation: '${json['operation'] ?? json['slug'] ?? ''}',
    displayName: '${json['display_name'] ?? json['name'] ?? 'AI operation'}',
    description: '${json['description'] ?? ''}',
    creditCost: _int(json['credit_cost'] ?? json['cost']),
  );
}

final class SubscriptionPlanModel {
  static SubscriptionPlan fromJson(Map<String, dynamic> json) =>
      SubscriptionPlan(
        id: '${json['id'] ?? json['slug'] ?? ''}',
        name: '${json['name'] ?? 'Plan'}',
        slug: '${json['slug'] ?? json['id'] ?? ''}',
        monthlyPrice: _double(json['monthly_price'] ?? json['price']),
        annualPrice: _double(json['annual_price'] ?? json['price']),
        currency: '${json['currency'] ?? 'INR'}',
        monthlyAiCredits: _int(
          json['monthly_ai_credits'] ?? json['ai_credits'],
        ),
        features: (json['features'] as List? ?? const [])
            .map((item) => '$item')
            .toList(),
        isActive: json['is_active'] != false,
        isRecommended: json['is_recommended'] == true,
      );
}

final class UserSubscriptionModel {
  static UserSubscription fromJson(Map<String, dynamic> json) {
    final plan = _map(json['plan']);
    return UserSubscription(
      planId: '${json['plan_id'] ?? plan['id'] ?? plan['slug'] ?? ''}',
      status: '${json['status'] ?? 'active'}',
      startedAt: _date(json['started_at']) ?? DateTime.now(),
      expiresAt: _date(json['expires_at']),
      autoRenew: json['auto_renew'] == true,
    );
  }
}

final class AiCreditTransactionModel {
  static AiCreditTransaction fromJson(Map<String, dynamic> json) =>
      AiCreditTransaction(
        id: '${json['id'] ?? ''}',
        type: CreditTransactionType.fromApi(
          json['transaction_type'] ?? json['type'],
        ),
        amount: _int(json['amount']),
        operation: json['operation']?.toString(),
        description:
            '${json['description'] ?? json['operation'] ?? 'Credit activity'}',
        createdAt: _date(json['created_at']) ?? DateTime.now(),
        status: CreditTransactionStatus.fromApi(json['status']),
        balanceBefore: json['balance_before'] == null
            ? null
            : _int(json['balance_before']),
        balanceAfter: json['balance_after'] == null
            ? null
            : _int(json['balance_after']),
        reference: json['reference']?.toString(),
      );
}
