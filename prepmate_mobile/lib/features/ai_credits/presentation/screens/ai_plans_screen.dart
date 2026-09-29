import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../config/theme.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/app_state.dart';
import '../../domain/entities/ai_credit_models.dart';
import '../../data/services/razorpay_checkout_service.dart';
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
  String? purchasingCode;
  late final RazorpayCheckoutService _checkout;

  @override
  void initState() {
    super.initState();
    _checkout = RazorpayCheckoutService();
    Future.microtask(() {
      if (ref.read(aiCreditsProvider).status == AiCreditStatus.initial) {
        ref.read(aiCreditsProvider.notifier).load();
      }
    });
  }

  @override
  void dispose() {
    _checkout.dispose();
    super.dispose();
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
            'Premium is prepaid and does not renew automatically.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.of(context).textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          if (state.plans.isEmpty)
            const AppCard(
              child: Text(
                'Plans could not be loaded. Please check your connection and try again.',
              ),
            ),
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
                      loading: purchasingCode != null,
                      onSelected: () => _buy(
                        period == BillingPeriod.annual
                            ? 'premium_annual'
                            : 'premium_monthly',
                      ),
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
          Text('Buy AI credits', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: AppSpacing.sm),
          Column(
            children: [
              for (final pack in state.products.where(
                (item) => item.isCreditPack,
              ))
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: AppCard(
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                pack.name,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              Text(
                                '₹${(pack.amount / 100).toStringAsFixed(0)}',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        FilledButton(
                          onPressed: purchasingCode == null
                                  ? () => _buy(pack.code)
                              : null,
                          child: purchasingCode == pack.code
                              ? const SizedBox.square(
                                  dimension: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text('Buy'),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
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

  Future<void> _buy(String productCode) async {
    if (purchasingCode != null) return;
    setState(() => purchasingCode = productCode);
    try {
      final repository = ref.read(aiCreditsRepositoryProvider);
      final order = await repository.createOrder(productCode);
      final result = await _checkout.open(order);
      await repository.verifyPayment(
        orderId: result.orderId,
        paymentId: result.paymentId,
        signature: result.signature,
      );
      await ref.read(aiCreditsProvider.notifier).load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Payment verified successfully.')),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error.toString().replaceFirst('Exception: ', '')),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => purchasingCode = null);
    }
  }
}
