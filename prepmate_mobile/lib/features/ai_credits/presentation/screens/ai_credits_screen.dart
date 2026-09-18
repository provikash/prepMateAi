import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/theme.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/app_state.dart';
import '../providers/ai_credits_provider.dart';
import '../viewmodels/ai_credit_state.dart';
import '../widgets/credit_widgets.dart';

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
      title: 'AI Credits',
      actions: [
        IconButton(
          tooltip: 'Refresh credits',
          onPressed: state.isRefreshing
              ? null
              : () => ref.read(aiCreditsProvider.notifier).refresh(),
          icon: const Icon(Icons.refresh_rounded),
        ),
      ],
      padding: EdgeInsets.zero,
      body: switch (state.status) {
        AiCreditStatus.initial ||
        AiCreditStatus.loading => const _CreditsLoading(),
        AiCreditStatus.error when !state.hasAccount => AppErrorState(
          title: 'Unable to load your AI credits',
          message: state.error ?? 'Please try again.',
          onAction: () => ref.read(aiCreditsProvider.notifier).load(),
        ),
        _ => _CreditsContent(state: state),
      },
    );
  }
}

class _CreditsContent extends ConsumerWidget {
  const _CreditsContent({required this.state});
  final AiCreditState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final account = state.account!;
    final recent = state.transactions.take(3).toList();
    final planName = state.currentPlan?.name ?? 'Free Tier';
    final content = RefreshIndicator(
      onRefresh: () => ref.read(aiCreditsProvider.notifier).refresh(),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.screen,
          AppSpacing.sm,
          AppSpacing.screen,
          AppSpacing.xxl,
        ),
        children: [
          CreditBalanceCard(account: account, planName: planName),
          if (state.isRefreshing)
            const Padding(
              padding: EdgeInsets.only(top: AppSpacing.xs),
              child: LinearProgressIndicator(minHeight: 2),
            ),
          const SizedBox(height: AppSpacing.md),
          CreditNotice(
            account: account,
            onViewPlans: () => context.push('/ai-plans'),
          ),
          if (state.isLow || state.hasNoCredits)
            const SizedBox(height: AppSpacing.md),
          _CurrentPlanCard(
            planName: planName,
            credits:
                state.currentPlan?.monthlyAiCredits ??
                account.monthlyAllocation,
            onUpgrade: () => context.push('/ai-plans'),
          ),
          const SizedBox(height: AppSpacing.section),
          _SectionHeader(
            title: 'AI feature costs',
            action: 'View plans',
            onAction: () => context.push('/ai-plans'),
          ),
          const SizedBox(height: AppSpacing.xs),
          AppCard(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.card),
            child: Column(
              children: [
                for (
                  var index = 0;
                  index < state.operations.take(4).length;
                  index++
                ) ...[
                  AiOperationCostTile(operation: state.operations[index]),
                  if (index != state.operations.take(4).length - 1)
                    const Divider(height: 1),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.section),
          _SectionHeader(
            title: 'Recent AI activity',
            action: 'View all',
            onAction: () => context.push('/ai-transactions'),
          ),
          const SizedBox(height: AppSpacing.xs),
          AppCard(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.card),
            child: state.transactionsError != null
                ? Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.md,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Activity could not be loaded.',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                        TextButton(
                          onPressed: () => ref
                              .read(aiCreditsProvider.notifier)
                              .loadTransactions(),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  )
                : recent.isEmpty
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
                    child: _NoActivity(),
                  )
                : Column(
                    children: [
                      for (var index = 0; index < recent.length; index++) ...[
                        CreditTransactionTile(transaction: recent[index]),
                        if (index != recent.length - 1)
                          const Divider(height: 1),
                      ],
                    ],
                  ),
          ),
          const SizedBox(height: AppSpacing.section),
          _ResumeToolsNotice(),
        ],
      ),
    );
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 920),
        child: content,
      ),
    );
  }
}

class _CurrentPlanCard extends StatelessWidget {
  const _CurrentPlanCard({
    required this.planName,
    required this.credits,
    required this.onUpgrade,
  });
  final String planName;
  final int credits;
  final VoidCallback onUpgrade;
  @override
  Widget build(BuildContext context) => AppCard(
    child: LayoutBuilder(
      builder: (context, constraints) {
        final details = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'CURRENT PLAN',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppColors.of(context).textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.xxs),
            Text(planName, style: Theme.of(context).textTheme.titleLarge),
            Text(
              '$credits monthly AI credits',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.of(context).textSecondary,
              ),
            ),
          ],
        );
        if (constraints.maxWidth < 440) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              details,
              const SizedBox(height: AppSpacing.md),
              AppPrimaryButton(label: 'Upgrade plan', onPressed: onUpgrade),
            ],
          );
        }
        return Row(
          children: [
            Expanded(child: details),
            AppPrimaryButton(
              label: 'Upgrade plan',
              onPressed: onUpgrade,
              expand: false,
            ),
          ],
        );
      },
    ),
  );
}

class _ResumeToolsNotice extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return AppCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.verified_user_outlined, color: colors.secondary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your core resume tools stay free',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  'Creating, editing, previewing, and downloading resumes never uses AI credits.',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: colors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.action,
    required this.onAction,
  });
  final String title;
  final String action;
  final VoidCallback onAction;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Text(title, style: Theme.of(context).textTheme.titleMedium),
      ),
      TextButton(onPressed: onAction, child: Text(action)),
    ],
  );
}

class _NoActivity extends StatelessWidget {
  const _NoActivity();
  @override
  Widget build(BuildContext context) => Column(
    children: [
      Icon(Icons.history_rounded, color: AppColors.of(context).textSecondary),
      const SizedBox(height: AppSpacing.xs),
      Text('No AI activity yet', style: Theme.of(context).textTheme.titleSmall),
      Text(
        'Your AI usage history will appear here.',
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: AppColors.of(context).textSecondary,
        ),
      ),
    ],
  );
}

class _CreditsLoading extends StatelessWidget {
  const _CreditsLoading();
  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(AppSpacing.screen),
    children: const [
      _Skeleton(height: 210),
      SizedBox(height: AppSpacing.md),
      _Skeleton(height: 120),
      SizedBox(height: AppSpacing.section),
      _Skeleton(height: 260),
    ],
  );
}

class _Skeleton extends StatelessWidget {
  const _Skeleton({required this.height});
  final double height;
  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Loading credit information',
    child: Container(
      height: height,
      decoration: BoxDecoration(
        color: AppColors.of(context).mutedBackground,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
    ),
  );
}
