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
  Future<List<AiCreditTransaction>> getTransactions({
    String? filter,
    String? query,
    String? ordering,
    int? limit,
    int? offset,
  }) async =>
      (await _remote.getTransactions(
        filter: filter,
        query: query,
        ordering: ordering,
        limit: limit,
        offset: offset,
      ))
          .map(AiCreditTransactionModel.fromJson)
          .toList();
  @override
  Future<List<AiOperation>> getOperations() async =>
      (await _remote.getOperations()).map(AiOperationModel.fromJson).toList();
  @override
  Future<List<SubscriptionPlan>> getPlans() async {
    final products = await getProducts();
    final monthly = products
        .where((item) => item.code == 'premium_monthly')
        .firstOrNull;
    final annual = products
        .where((item) => item.code == 'premium_annual')
        .firstOrNull;
    if (monthly == null && annual == null) {
      return const [];
    }
    return [
      SubscriptionPlan(
        id: 'premium',
        name: 'Premium',
        slug: 'premium',
        monthlyPrice: (monthly?.amount ?? 9900) / 100,
        annualPrice: (annual?.amount ?? 99900) / 100,
        currency: monthly?.currency ?? 'INR',
        monthlyAiCredits: monthly?.credits ?? 500,
        features: const [
          'Job description optimization',
          'ATS scoring and keyword diagnostics',
          'Premium resume templates',
          'AI credit allowance',
        ],
        isRecommended: true,
      ),
    ];
  }


  @override
  Future<UserSubscription?> getCurrentSubscription() async {
    final value = await _remote.getCurrentSubscription();
    return value == null ? null : UserSubscriptionModel.fromJson(value);
  }

  @override
  Future<List<BillingProduct>> getProducts() async {
    final catalog = await _remote.getCatalog();
    return (catalog['products'] as List? ?? const [])
        .map(
          (item) => BillingProductModel.fromJson(
            Map<String, dynamic>.from(item as Map),
          ),
        )
        .toList();
  }

  @override
  Future<CheckoutOrder> createOrder(String productCode) async =>
      CheckoutOrderModel.fromJson(await _remote.createOrder(productCode));
  @override
  Future<void> verifyPayment({
    required String orderId,
    required String paymentId,
    required String signature,
  }) => _remote.verifyPayment(
    orderId: orderId,
    paymentId: paymentId,
    signature: signature,
  );

  @override
  Future<OrderStatusResult> getOrderStatus(String orderId) async =>
      OrderStatusResultModel.fromJson(await _remote.getOrderStatus(orderId));

  @override
  Future<OrderReceipt> getOrderReceipt(String orderId) async =>
      OrderReceiptModel.fromJson(await _remote.getOrderReceipt(orderId));

  @override
  Future<void> refresh() async {}

  @override
  Future<Map<String, dynamic>> submitSupportTicket({
    required String category,
    required String subject,
    required String message,
    String? transactionReference,
    String? idempotencyKey,
    Map<String, dynamic>? metadata,
  }) => _remote.submitSupportTicket(
    category: category,
    subject: subject,
    message: message,
    transactionReference: transactionReference,
    idempotencyKey: idempotencyKey,
    metadata: metadata,
  );
}
