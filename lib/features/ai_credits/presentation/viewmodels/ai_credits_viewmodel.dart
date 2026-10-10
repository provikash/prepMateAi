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
        _repository.getOperations(),
      ]);
      state = state.copyWith(
        status: AiCreditStatus.loaded,
        account: results[0] as AiCreditAccount,
        operations: results[1] as List<AiOperation>,
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

  Future<void> loadTransactions({
    String? filter,
    String? query,
    String? ordering,
  }) async {
    try {
      final transactions = await _repository.getTransactions(
        filter: filter,
        query: query,
        ordering: ordering,
      );
      state = state.copyWith(
        transactions: transactions,
        clearTransactionsError: true,
      );
    } catch (error) {
      state = state.copyWith(transactionsError: _message(error));
    }
  }

  Future<OrderStatusResult?> getOrderStatus(String orderId) async {
    try {
      return await _repository.getOrderStatus(orderId);
    } catch (_) {
      return null;
    }
  }

  Future<OrderReceipt?> getOrderReceipt(String orderId) async {
    try {
      return await _repository.getOrderReceipt(orderId);
    } catch (_) {
      return null;
    }
  }

  Future<CheckoutOrder?> createOrder(String productCode) async {
    try {
      return await _repository.createOrder(productCode);
    } catch (error) {
      state = state.copyWith(error: _message(error));
      return null;
    }
  }

  Future<bool> verifyPayment({
    required String orderId,
    required String paymentId,
    required String signature,
  }) async {
    try {
      await _repository.verifyPayment(
        orderId: orderId,
        paymentId: paymentId,
        signature: signature,
      );
      await refresh();
      return true;
    } catch (error) {
      state = state.copyWith(error: _message(error));
      return false;
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

  Future<Map<String, dynamic>?> submitSupportTicket({
    required String category,
    required String subject,
    required String message,
    String? transactionReference,
    Map<String, dynamic>? metadata,
  }) async {
    final key = 'support-${DateTime.now().millisecondsSinceEpoch}';
    try {
      final res = await _repository.submitSupportTicket(
        category: category,
        subject: subject,
        message: message,
        transactionReference: transactionReference,
        idempotencyKey: key,
        metadata: metadata,
      );
      return res;
    } catch (error) {
      state = state.copyWith(error: _message(error));
      return null;
    }
  }

  String _message(Object error) =>
      error.toString().replaceFirst('Exception: ', '');
}
