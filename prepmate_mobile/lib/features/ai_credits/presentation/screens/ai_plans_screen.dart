import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../config/theme.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/app_state.dart';
import '../../domain/entities/ai_credit_models.dart';
import '../providers/ai_credits_provider.dart';
import '../viewmodels/ai_credit_state.dart';
import '../widgets/credit_widgets.dart';

class AiPlansScreen extends ConsumerStatefulWidget {
  const AiPlansScreen({super.key});
  @override
  ConsumerState<AiPlansScreen> createState() => _AiPlansScreenState();
}

class _AiPlansScreenState extends ConsumerState<AiPlansScreen> {
  BillingPeriod period = BillingPeriod.monthly;
  String? selectedPlan;

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
      title: 'Subscription Plans',
      description:
          'Get more AI credits for career tools. Resume creation and editing remain free.',
      padding: EdgeInsets.zero,
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : state.status == AiCreditStatus.error && state.plans.isEmpty
          ? AppErrorState(
              message: state.error ?? 'Plans could not be loaded.',
              onAction: () => ref.read(aiCreditsProvider.notifier).load(),
            )
          : _content(context, state),
    );
  }

  Widget _content(BuildContext context, AiCreditState state) => Align(
    alignment: Alignment.topCenter,
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 960),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.screen,
          0,
          AppSpacing.screen,
          AppSpacing.xxl,
        ),
        children: [
          SegmentedButton<BillingPeriod>(
            segments: const [
              ButtonSegment(
                value: BillingPeriod.monthly,
                label: Text('Monthly'),
              ),
              ButtonSegment(
                value: BillingPeriod.annual,
                label: Text('Annual'),
                icon: Icon(Icons.savings_outlined),
              ),
            ],
            selected: {period},
            onSelectionChanged: (value) => setState(() => period = value.first),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Choose your AI plan',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Upgrade or cancel any time when billing is available.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.of(context).textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          LayoutBuilder(
            builder: (context, constraints) {
              final cards = state.plans
                  .map(
                    (plan) => SubscriptionPlanCard(
                      plan: plan,
                      period: period,
                      isCurrent:
                          state.currentSubscription?.planId == plan.id ||
                          state.currentSubscription?.planId == plan.slug,
                      selected: selectedPlan == plan.id,
                      onSelected: () => _selectPlan(context, plan),
                    ),
                  )
                  .toList();
              if (constraints.maxWidth < 700) {
                return Column(
                  children: [
                    for (var i = 0; i < cards.length; i++) ...[
                      cards[i],
                      if (i != cards.length - 1)
                        const SizedBox(height: AppSpacing.md),
                    ],
                  ],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (var i = 0; i < cards.length; i++) ...[
                    Expanded(child: cards[i]),
                    if (i != cards.length - 1)
                      const SizedBox(width: AppSpacing.md),
                  ],
                ],
              );
            },
          ),
          const SizedBox(height: AppSpacing.section),
          AppCard(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.lock_outline_rounded,
                  color: AppColors.of(context).primary,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Zero-lockout guarantee',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        'Resumes and PDF exports are never locked when AI credits run out. Only AI generation pauses.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.of(context).textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );

  void _selectPlan(BuildContext context, SubscriptionPlan plan) {
    setState(() => selectedPlan = plan.id);
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screen,
            AppSpacing.sm,
            AppSpacing.screen,
            AppSpacing.xl,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.payment_outlined,
                size: 40,
                color: AppColors.of(sheetContext).primary,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Checkout coming soon',
                style: Theme.of(sheetContext).textTheme.titleLarge,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'The ${plan.name} selection is ready, but payment has not been connected yet. No subscription or charge was created.',
                textAlign: TextAlign.center,
                style: Theme.of(sheetContext).textTheme.bodyMedium?.copyWith(
                  color: AppColors.of(sheetContext).textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              FilledButton(
                onPressed: () => Navigator.pop(sheetContext),
                child: const Text('Got it'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
