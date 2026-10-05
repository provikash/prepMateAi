import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../config/theme.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/app_state.dart';
import '../providers/ai_credits_provider.dart';
import '../viewmodels/ai_credit_state.dart';
import '../widgets/credit_widgets.dart';

enum _TransactionFilter { all, used, added }

class AiTransactionsScreen extends ConsumerStatefulWidget {
  const AiTransactionsScreen({super.key});
  @override
  ConsumerState<AiTransactionsScreen> createState() =>
      _AiTransactionsScreenState();
}

class _AiTransactionsScreenState extends ConsumerState<AiTransactionsScreen> {
  _TransactionFilter filter = _TransactionFilter.all;
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final state = ref.read(aiCreditsProvider);
      if (state.status == AiCreditStatus.initial) {
        ref.read(aiCreditsProvider.notifier).load();
      } else if (state.transactions.isEmpty &&
          state.transactionsError == null) {
        ref.read(aiCreditsProvider.notifier).loadTransactions();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(aiCreditsProvider);
    final items = state.transactions
        .where(
          (item) => switch (filter) {
            _TransactionFilter.all => true,
            _TransactionFilter.used => item.amount < 0,
            _TransactionFilter.added => item.amount >= 0,
          },
        )
        .toList();
    return AppScaffold(
      title: 'AI Credit Activity',
      padding: EdgeInsets.zero,
      body: state.isLoading && state.transactions.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : state.transactionsError != null && state.transactions.isEmpty
          ? AppErrorState(
              message: 'Unable to load credit activity.',
              onAction: () =>
                  ref.read(aiCreditsProvider.notifier).loadTransactions(),
            )
          : Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 760),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.screen,
                        AppSpacing.sm,
                        AppSpacing.screen,
                        AppSpacing.md,
                      ),
                      child: SegmentedButton<_TransactionFilter>(
                        segments: const [
                          ButtonSegment(
                            value: _TransactionFilter.all,
                            label: Text('All'),
                          ),
                          ButtonSegment(
                            value: _TransactionFilter.used,
                            label: Text('Used'),
                          ),
                          ButtonSegment(
                            value: _TransactionFilter.added,
                            label: Text('Added'),
                          ),
                        ],
                        selected: {filter},
                        onSelectionChanged: (value) =>
                            setState(() => filter = value.first),
                      ),
                    ),
                    Expanded(
                      child: items.isEmpty
                          ? const AppEmptyState(
                              title: 'No credit transactions yet',
                              message:
                                  'Credit grants and AI usage will appear here.',
                              icon: Icons.history_rounded,
                            )
                          : RefreshIndicator(
                              onRefresh: () => ref
                                  .read(aiCreditsProvider.notifier)
                                  .loadTransactions(),
                              child: ListView.builder(
                                physics: const AlwaysScrollableScrollPhysics(),
                                padding: const EdgeInsets.fromLTRB(
                                  AppSpacing.screen,
                                  0,
                                  AppSpacing.screen,
                                  AppSpacing.xxl,
                                ),
                                itemCount: items.length,
                                itemBuilder: (context, index) => Padding(
                                  padding: const EdgeInsets.only(
                                    bottom: AppSpacing.sm,
                                  ),
                                  child: AppCard(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: AppSpacing.card,
                                    ),
                                    child: CreditTransactionTile(
                                      transaction: items[index],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
