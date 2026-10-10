enum CreditTransactionType {
  grant,
  purchase,
  reservation,
  release,
  usage,
  refund,
  expiration,
  adjustment;

  static CreditTransactionType fromApi(Object? value) {
    final normalized = value?.toString().toLowerCase();
    return values.firstWhere(
      (item) => item.name == normalized,
      orElse: () => CreditTransactionType.adjustment,
    );
  }
}

enum CreditTransactionStatus {
  pending,
  completed,
  failed;

  static CreditTransactionStatus fromApi(Object? value) {
    final normalized = value?.toString().toLowerCase();
    return values.firstWhere(
      (item) => item.name == normalized,
      orElse: () => CreditTransactionStatus.completed,
    );
  }
}

enum BillingPeriod { monthly, annual, oneTime }

class BillingProduct {
  const BillingProduct({
    required this.code,
    required this.name,
    required this.amount,
    required this.currency,
    required this.credits,
    required this.premiumDays,
  });
  final String code;
  final String name;
  final int amount;
  final String currency;
  final int credits;
  final int premiumDays;
  bool get isCreditPack => premiumDays == 0;
}

class CheckoutOrder {
  const CheckoutOrder({
    required this.keyId,
    required this.orderId,
    required this.amount,
    required this.currency,
    required this.name,
    required this.description,
    required this.prefill,
  });
  final String keyId;
  final String orderId;
  final int amount;
  final String currency;
  final String name;
  final String description;
  final Map<String, dynamic> prefill;
}

class AiCreditAccount {
  const AiCreditAccount({
    required this.balance,
    required this.monthlyAllocation,
    required this.usedThisCycle,
    required this.resetDate,
    this.reservedCredits = 0,
    this.lifetimeEarned = 0,
    this.lifetimeUsed = 0,
    this.isUnlimited = false,
  });

  final int balance;
  final int reservedCredits;
  final int monthlyAllocation;
  final int usedThisCycle;
  final int lifetimeEarned;
  final int lifetimeUsed;
  final DateTime? resetDate;
  final bool isUnlimited;

  int get availableCredits =>
      isUnlimited ? balance : (balance - reservedCredits).clamp(0, balance);
  double get usageFraction => monthlyAllocation <= 0
      ? 0
      : (usedThisCycle / monthlyAllocation).clamp(0, 1);
}

class AiOperation {
  const AiOperation({
    required this.operation,
    required this.displayName,
    required this.description,
    required this.creditCost,
  });

  final String operation;
  final String displayName;
  final String description;
  final int creditCost;
}

class SubscriptionPlan {
  const SubscriptionPlan({
    required this.id,
    required this.name,
    required this.slug,
    required this.monthlyPrice,
    required this.annualPrice,
    required this.currency,
    required this.monthlyAiCredits,
    required this.features,
    this.isActive = true,
    this.isRecommended = false,
  });

  final String id;
  final String name;
  final String slug;
  final double monthlyPrice;
  final double annualPrice;
  final String currency;
  final int monthlyAiCredits;
  final List<String> features;
  final bool isActive;
  final bool isRecommended;

  double priceFor(BillingPeriod period) =>
      period == BillingPeriod.annual ? annualPrice : monthlyPrice;
}

class UserSubscription {
  const UserSubscription({
    required this.planId,
    required this.status,
    required this.startedAt,
    this.expiresAt,
    this.autoRenew = false,
  });

  final String planId;
  final String status;
  final DateTime startedAt;
  final DateTime? expiresAt;
  final bool autoRenew;
}

class AiCreditTransaction {
  const AiCreditTransaction({
    required this.id,
    required this.type,
    required this.amount,
    required this.description,
    required this.createdAt,
    required this.status,
    this.operation,
    this.balanceBefore,
    this.balanceAfter,
    this.reference,
    this.creditSource,
    this.receiptAvailable = false,
  });

  final String id;
  final CreditTransactionType type;
  final int amount;
  final String? operation;
  final String description;
  final DateTime createdAt;
  final CreditTransactionStatus status;
  final int? balanceBefore;
  final int? balanceAfter;
  final String? reference;
  final String? creditSource;
  final bool receiptAvailable;
}

class OrderStatusResult {
  const OrderStatusResult({
    required this.orderId,
    required this.status,
    required this.credits,
    required this.premiumDays,
    required this.productCode,
    required this.productName,
    required this.amount,
    required this.currency,
    required this.reference,
    this.paidAt,
    this.receipt,
  });

  final String orderId;
  final String status;
  final int credits;
  final int premiumDays;
  final String productCode;
  final String productName;
  final int amount;
  final String currency;
  final String reference;
  final DateTime? paidAt;
  final String? receipt;
}

class OrderReceipt {
  const OrderReceipt({
    required this.receiptNumber,
    required this.reference,
    required this.productName,
    required this.amount,
    required this.currency,
    required this.credits,
    required this.premiumDays,
    required this.status,
    required this.createdAt,
    required this.customerName,
    required this.customerPhone,
    required this.billingProvider,
    this.paidAt,
  });

  final String receiptNumber;
  final String reference;
  final String productName;
  final double amount;
  final String currency;
  final int credits;
  final int premiumDays;
  final String status;
  final DateTime createdAt;
  final DateTime? paidAt;
  final String customerName;
  final String customerPhone;
  final String billingProvider;
}

