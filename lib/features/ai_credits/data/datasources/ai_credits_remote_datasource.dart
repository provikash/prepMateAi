import 'package:dio/dio.dart';

class AiCreditsRemoteDataSource {
  const AiCreditsRemoteDataSource(this._dio);
  final Dio _dio;

  Future<Map<String, dynamic>> getAccount() async =>
      _asMap((await _dio.get('ai/credits/')).data);
  Future<List<Map<String, dynamic>>> getTransactions({
    String? filter,
    String? query,
    String? ordering,
    int? limit,
    int? offset,
  }) async =>
      _asList((await _dio.get(
        'ai/credits/transactions/',
        queryParameters: {
          if (filter != null && filter.isNotEmpty) 'filter': filter,
          if (query != null && query.isNotEmpty) 'q': query,
          if (ordering != null && ordering.isNotEmpty) 'ordering': ordering,
          if (limit != null) 'limit': limit,
          if (offset != null) 'offset': offset,
        },
      )).data);
  Future<List<Map<String, dynamic>>> getOperations() async =>
      _asList((await _dio.get('ai/operations/')).data);
  Future<List<Map<String, dynamic>>> getPlans() async =>
      _asList((await _dio.get('subscriptions/plans/')).data);
  Future<Map<String, dynamic>?> getCurrentSubscription() async {
    final data = (await _dio.get('billing/subscription/')).data;
    return data == null ? null : _asMap(data);
  }

  Future<Map<String, dynamic>> getOrderStatus(String orderId) async =>
      _asMap((await _dio.get('billing/orders/status/', queryParameters: {'order_id': orderId})).data);

  Future<Map<String, dynamic>> getOrderReceipt(String orderId) async =>
      _asMap((await _dio.get('billing/orders/receipt/', queryParameters: {'order_id': orderId})).data);

  Future<Map<String, dynamic>> getCatalog() async =>
      _asMap((await _dio.get('billing/catalog/')).data);

  Future<Map<String, dynamic>> createOrder(String productCode) async => _asMap(
    (await _dio.post(
      'billing/orders/',
      data: {'product_code': productCode},
    )).data,
  );
  Future<void> verifyPayment({
    required String orderId,
    required String paymentId,
    required String signature,
  }) async {
    await _dio.post(
      'billing/orders/verify/',
      data: {
        'razorpay_order_id': orderId,
        'razorpay_payment_id': paymentId,
        'razorpay_signature': signature,
      },
    );
  }

  Future<Map<String, dynamic>> submitSupportTicket({
    required String category,
    required String subject,
    required String message,
    String? transactionReference,
    String? idempotencyKey,
    Map<String, dynamic>? metadata,
  }) async => _asMap(
    (await _dio.post(
      'billing/support/tickets/',
      data: {
        'category': category,
        'subject': subject,
        'message': message,
        if (transactionReference != null)
          'transaction_reference': transactionReference,
        if (idempotencyKey != null) 'idempotency_key': idempotencyKey,
        if (metadata != null) 'metadata': metadata,
      },
    )).data,
  );

  Map<String, dynamic> _asMap(Object? value) {
    if (value is Map && value['data'] is Map) value = value['data'];
    if (value is! Map) {
      throw const FormatException('Expected an object response.');
    }
    return Map<String, dynamic>.from(value);
  }

  List<Map<String, dynamic>> _asList(Object? value) {
    if (value is Map) value = value['results'] ?? value['data'];
    if (value is! List) {
      throw const FormatException('Expected a list response.');
    }
    return value.map((item) => Map<String, dynamic>.from(item as Map)).toList();
  }
}
