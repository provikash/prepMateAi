import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../config/theme.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/app_state.dart';
import '../../domain/entities/ai_credit_models.dart';
import '../providers/ai_credits_provider.dart';
import '../viewmodels/ai_credit_state.dart';

/// Lean credit overview for the MVP. Checkout and subscription management are
/// intentionally excluded until monetization is validated.
class AiCreditsScreen extends ConsumerStatefulWidget {
  const AiCreditsScreen({super.key});

  @override
  ConsumerState<AiCreditsScreen> createState() => _AiCreditsScreenState();
}

class _AiCreditsScreenState extends ConsumerState<AiCreditsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (ref.read(aiCreditsProvider).status == AiCreditStatus.initial) {
        ref.read(aiCreditsProvider.notifier).load();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(aiCreditsProvider);
    return AppScaffold(
      title: 'AI credits',
      description: 'Usage for the three focused AI writing tools.',
      actions: [
        IconButton(
          tooltip: 'Refresh credits',
          onPressed: state.isRefreshing
              ? null
              : () => ref.read(aiCreditsProvider.notifier).refresh(),
          icon: const Icon(Icons.refresh_rounded),
        ),
      ],
      body: switch (state.status) {
        AiCreditStatus.initial || AiCreditStatus.loading => const Center(
          child: CircularProgressIndicator(),
        ),
        AiCreditStatus.error when !state.hasAccount => AppErrorState(
          title: 'Unable to load AI credits',
          message: state.error ?? 'Please check your connection and try again.',
          onAction: () => ref.read(aiCreditsProvider.notifier).load(),
        ),
        _ => _CreditOverview(state: state),
      },
    );
  }
}

class _CreditOverview extends StatelessWidget {
  const _CreditOverview({required this.state});

  final AiCreditState state;

  @override
  Widget build(BuildContext context) {
    final account = state.account!;
    final colors = AppColors.of(context);
    final recent = state.transactions.take(5).toList(growable: false);
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: ListView(
          children: [
            AppCard(
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: colors.primarySoft,
                    child: Icon(Icons.auto_awesome, color: colors.primary),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          account.isUnlimited
                              ? 'Unlimited credits'
                              : '${account.availableCredits} credits available',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: AppSpacing.xxs),
                        Text(
                          'Resume building, editing, and PDF export stay available even when credits run out.',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: colors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text('Tool costs', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppSpacing.sm),
            AppCard(
              child: Column(
                children: [
                  for (
                    var index = 0;
                    index < state.operations.length;
                    index++
                  ) ...[
                    _OperationRow(operation: state.operations[index]),
                    if (index != state.operations.length - 1)
                      const Divider(height: AppSpacing.lg),
                  ],
                  if (state.operations.isEmpty)
                    Text(
                      'Tool costs are temporarily unavailable.',
                      style: TextStyle(color: colors.textSecondary),
                    ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Recent usage',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.sm),
            AppCard(
              child: Column(
                children: [
                  for (var index = 0; index < recent.length; index++) ...[
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                      title: Text(recent[index].description),
                      subtitle: Text(
                        recent[index].createdAt
                            .toLocal()
                            .toString()
                            .split('.')
                            .first,
                      ),
                      trailing: Text(
                        '${recent[index].amount > 0 ? '+' : ''}${recent[index].amount}',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: recent[index].amount < 0
                              ? colors.textPrimary
                              : colors.success,
                        ),
                      ),
                    ),
                    if (index != recent.length - 1) const Divider(height: 1),
                  ],
                  if (recent.isEmpty)
                    Text(
                      state.transactionsError ?? 'No AI usage yet.',
                      style: TextStyle(color: colors.textSecondary),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OperationRow extends StatelessWidget {
  const _OperationRow({required this.operation});

  final AiOperation operation;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(child: Text(operation.displayName)),
      Text(
        '${operation.creditCost} credit${operation.creditCost == 1 ? '' : 's'}',
      ),
    ],
  );
}
