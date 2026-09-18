import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prepmate_mobile/features/ai_credits/data/datasources/ai_credits_remote_datasource.dart';
import 'package:prepmate_mobile/features/ai_credits/data/repositories/ai_credits_repository_impl.dart';
import 'package:prepmate_mobile/features/ai_credits/domain/entities/ai_credit_models.dart';
import 'package:prepmate_mobile/features/ai_credits/domain/repositories/ai_credits_repository.dart';
import 'package:prepmate_mobile/features/ai_credits/presentation/viewmodels/ai_credit_state.dart';
import 'package:prepmate_mobile/features/ai_credits/presentation/viewmodels/ai_credits_viewmodel.dart';
import 'package:prepmate_mobile/features/ai_credits/presentation/widgets/credit_widgets.dart';

void main() {
  group('AiCreditsViewModel', () {
    test(
      'loads account, plans, operations, subscription and transactions',
      () async {
        final repository = _FakeRepository();
        final viewModel = AiCreditsViewModel(repository);

        await viewModel.load();

        expect(viewModel.state.status, AiCreditStatus.loaded);
        expect(viewModel.state.account?.availableCredits, 24);
        expect(viewModel.state.plans.single.name, 'Pro');
        expect(viewModel.state.operations.single.creditCost, 5);
        expect(viewModel.state.transactions.single.amount, -5);
        expect(viewModel.state.currentPlan?.id, 'pro');
      },
    );

    test('exposes a recoverable repository error', () async {
      final viewModel = AiCreditsViewModel(_FakeRepository(failAccount: true));

      await viewModel.load();

      expect(viewModel.state.status, AiCreditStatus.error);
      expect(viewModel.state.error, contains('offline'));
    });

    test(
      'refresh requests authoritative account and transactions again',
      () async {
        final repository = _FakeRepository();
        final viewModel = AiCreditsViewModel(repository);
        await viewModel.load();

        await viewModel.refreshAfterAiOperation();

        expect(repository.refreshCalls, 1);
        expect(repository.accountCalls, 2);
        expect(repository.transactionCalls, 2);
      },
    );

    test('keeps account usable when only transactions fail', () async {
      final viewModel = AiCreditsViewModel(
        _FakeRepository(failTransactions: true),
      );

      await viewModel.load();

      expect(viewModel.state.status, AiCreditStatus.loaded);
      expect(viewModel.state.account, isNotNull);
      expect(viewModel.state.transactionsError, contains('ledger'));
    });
  });

  group('credit widgets', () {
    testWidgets('zero-credit state explains resume tools remain available', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(
          CreditNotice(
            account: AiCreditAccount(
              balance: 0,
              monthlyAllocation: 100,
              usedThisCycle: 100,
              resetDate: DateTime(2030),
            ),
            onViewPlans: () {},
          ),
        ),
      );

      expect(find.text("You've used all your AI credits"), findsOneWidget);
      expect(find.textContaining('normal resume tools'), findsOneWidget);
      expect(find.text('View plans'), findsOneWidget);
    });

    testWidgets('low-credit state is explicit and non-blocking', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(
          CreditNotice(
            account: AiCreditAccount(
              balance: 20,
              monthlyAllocation: 100,
              usedThisCycle: 80,
              resetDate: DateTime(2030),
            ),
            onViewPlans: () {},
          ),
        ),
      );

      expect(find.text('20 credits remaining'), findsOneWidget);
      expect(find.text("You're running low on AI credits."), findsOneWidget);
    });

    testWidgets('AI action routes insufficient balance without executing', (
      tester,
    ) async {
      var executed = false;
      var insufficient = false;
      await tester.pumpWidget(
        _app(
          AiActionButton(
            label: 'Run ATS analysis',
            creditCost: 5,
            availableCredits: 2,
            onPressed: () => executed = true,
            onInsufficientCredits: () => insufficient = true,
          ),
        ),
      );

      await tester.tap(find.byType(FilledButton));

      expect(executed, isFalse);
      expect(insufficient, isTrue);
    });

    testWidgets('AI action executes when sufficient credits are available', (
      tester,
    ) async {
      var executed = false;
      await tester.pumpWidget(
        _app(
          AiActionButton(
            label: 'Run ATS analysis',
            creditCost: 5,
            availableCredits: 12,
            onPressed: () => executed = true,
            onInsufficientCredits: () {},
          ),
        ),
      );

      await tester.tap(find.byType(FilledButton));

      expect(executed, isTrue);
    });
  });

  group('API repository contract', () {
    test('maps successful API responses', () async {
      final repository = AiCreditsRepositoryImpl(_SuccessRemote());

      final account = await repository.getCreditAccount();
      final transactions = await repository.getTransactions();

      expect(account.availableCredits, 40);
      expect(transactions.single.type, CreditTransactionType.usage);
    });

    test('propagates API errors', () async {
      final repository = AiCreditsRepositoryImpl(_ErrorRemote());
      expect(repository.getCreditAccount(), throwsA(isA<DioException>()));
    });

    test('rejects malformed response bodies', () async {
      final dio = Dio(BaseOptions(baseUrl: 'https://example.test/'));
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            handler.resolve(
              Response(requestOptions: options, data: 'not-an-object'),
            );
          },
        ),
      );
      final remote = AiCreditsRemoteDataSource(dio);

      expect(remote.getAccount(), throwsA(isA<FormatException>()));
    });
  });
}

Widget _app(Widget child) => MaterialApp(home: Scaffold(body: child));

class _FakeRepository implements AiCreditsRepository {
  _FakeRepository({this.failAccount = false, this.failTransactions = false});
  final bool failAccount;
  final bool failTransactions;
  int accountCalls = 0;
  int transactionCalls = 0;
  int refreshCalls = 0;

  @override
  Future<AiCreditAccount> getCreditAccount() async {
    accountCalls++;
    if (failAccount) throw Exception('offline');
    return AiCreditAccount(
      balance: 24,
      monthlyAllocation: 100,
      usedThisCycle: 76,
      resetDate: DateTime(2030),
    );
  }

  @override
  Future<UserSubscription?> getCurrentSubscription() async => UserSubscription(
    planId: 'pro',
    status: 'active',
    startedAt: DateTime(2029),
  );
  @override
  Future<List<AiOperation>> getOperations() async => const [
    AiOperation(
      operation: 'ats',
      displayName: 'ATS Analysis',
      description: 'Review',
      creditCost: 5,
    ),
  ];
  @override
  Future<List<SubscriptionPlan>> getPlans() async => const [
    SubscriptionPlan(
      id: 'pro',
      name: 'Pro',
      slug: 'pro',
      monthlyPrice: 99,
      annualPrice: 950,
      currency: 'INR',
      monthlyAiCredits: 500,
      features: [],
    ),
  ];
  @override
  Future<List<AiCreditTransaction>> getTransactions() async {
    transactionCalls++;
    if (failTransactions) throw Exception('ledger unavailable');
    return [
      AiCreditTransaction(
        id: '1',
        type: CreditTransactionType.usage,
        amount: -5,
        description: 'ATS Analysis',
        createdAt: DateTime(2030),
        status: CreditTransactionStatus.completed,
      ),
    ];
  }

  @override
  Future<void> refresh() async => refreshCalls++;
}

class _SuccessRemote extends AiCreditsRemoteDataSource {
  _SuccessRemote() : super(Dio());
  @override
  Future<Map<String, dynamic>> getAccount() async => {
    'balance': 40,
    'monthly_allocation': 100,
    'used_this_cycle': 60,
  };
  @override
  Future<List<Map<String, dynamic>>> getTransactions() async => [
    {
      'id': '1',
      'transaction_type': 'USAGE',
      'amount': -5,
      'description': 'ATS Analysis',
      'created_at': '2030-01-01T00:00:00Z',
      'status': 'COMPLETED',
    },
  ];
}

class _ErrorRemote extends AiCreditsRemoteDataSource {
  _ErrorRemote() : super(Dio());
  @override
  Future<Map<String, dynamic>> getAccount() =>
      throw DioException(requestOptions: RequestOptions(path: 'ai/credits/'));
}
