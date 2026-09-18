import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../config/theme.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../domain/entities/ai_credit_models.dart';

class CreditCostLabel extends StatelessWidget {
  const CreditCostLabel({
    super.key,
    required this.credits,
    this.compact = false,
  });
  final int credits;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final label = '$credits ${credits == 1 ? 'credit' : 'credits'}';
    return Semantics(
      label: label,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? AppSpacing.xs : AppSpacing.sm,
          vertical: AppSpacing.xxs,
        ),
        decoration: BoxDecoration(
          color: colors.primarySoft,
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.bolt_rounded, size: 16, color: colors.primary),
            const SizedBox(width: AppSpacing.xxs),
            Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.labelSmall?.copyWith(color: colors.primary),
            ),
          ],
        ),
      ),
    );
  }
}

class CreditUsageProgress extends StatelessWidget {
  const CreditUsageProgress({super.key, required this.account});
  final AiCreditAccount account;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final usedLabel = account.isUnlimited
        ? 'Unlimited AI credits'
        : '${account.usedThisCycle} of ${account.monthlyAllocation} used';
    return Semantics(
      label: '$usedLabel. ${account.availableCredits} credits remaining.',
      value: account.isUnlimited
          ? 'Unlimited'
          : '${(account.usageFraction * 100).round()} percent used',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  usedLabel,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: colors.textSecondary),
                ),
              ),
              if (!account.isUnlimited)
                Text(
                  '${(account.usageFraction * 100).round()}%',
                  style: Theme.of(context).textTheme.labelMedium,
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            child: LinearProgressIndicator(
              minHeight: 8,
              value: account.isUnlimited ? null : account.usageFraction,
              color: account.availableCredits == 0
                  ? colors.error
                  : account.availableCredits <= account.monthlyAllocation * .25
                  ? colors.warning
                  : colors.primary,
              backgroundColor: colors.mutedBackground,
            ),
          ),
        ],
      ),
    );
  }
}

class CreditBalanceCard extends StatelessWidget {
  const CreditBalanceCard({super.key, required this.account, this.planName});
  final AiCreditAccount account;
  final String? planName;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final reset = account.resetDate == null
        ? null
        : DateFormat('MMM d').format(account.resetDate!.toLocal());
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: colors.primarySoft,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Icon(
                  Icons.auto_awesome_rounded,
                  color: colors.primary,
                  size: AppSizes.iconSmall,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'AI Credits Balance',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              if (planName != null)
                _StatusPill(
                  label: planName!,
                  color: colors.primary,
                  background: colors.primarySoft,
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            account.isUnlimited ? '∞' : '${account.availableCredits}',
            style: Theme.of(
              context,
            ).textTheme.displaySmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          Text(
            account.isUnlimited
                ? 'credits available'
                : 'credits remaining of ${account.monthlyAllocation}',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: colors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.md),
          CreditUsageProgress(account: account),
          if (reset != null) ...[
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Icon(
                  Icons.refresh_rounded,
                  size: 18,
                  color: colors.textSecondary,
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  'Monthly credits reset $reset',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: colors.textSecondary),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class AiOperationCostTile extends StatelessWidget {
  const AiOperationCostTile({super.key, required this.operation});
  final AiOperation operation;
  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: colors.iconSoftBackground,
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        child: Icon(
          _operationIcon(operation.operation),
          color: colors.primary,
          size: AppSizes.iconSmall,
        ),
      ),
      title: Text(operation.displayName),
      subtitle: operation.description.isEmpty
          ? null
          : Text(
              operation.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
      trailing: CreditCostLabel(credits: operation.creditCost, compact: true),
    );
  }
}

class CreditTransactionTile extends StatelessWidget {
  const CreditTransactionTile({super.key, required this.transaction});
  final AiCreditTransaction transaction;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final positive = transaction.amount >= 0;
    final amountColor = positive ? colors.success : colors.textPrimary;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: positive ? colors.successSoft : colors.primarySoft,
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        child: Icon(
          positive ? Icons.add_rounded : Icons.auto_awesome_rounded,
          color: positive ? colors.success : colors.primary,
          size: AppSizes.iconSmall,
        ),
      ),
      title: Text(transaction.description),
      subtitle: Text(
        '${DateFormat('MMM d, h:mm a').format(transaction.createdAt.toLocal())} · ${_titleCase(transaction.status.name)}',
      ),
      trailing: Text(
        '${positive ? '+' : ''}${transaction.amount}',
        style: Theme.of(
          context,
        ).textTheme.titleSmall?.copyWith(color: amountColor),
      ),
    );
  }
}

class SubscriptionPlanCard extends StatelessWidget {
  const SubscriptionPlanCard({
    super.key,
    required this.plan,
    required this.period,
    required this.onSelected,
    this.isCurrent = false,
    this.selected = false,
    this.loading = false,
  });
  final SubscriptionPlan plan;
  final BillingPeriod period;
  final VoidCallback? onSelected;
  final bool isCurrent;
  final bool selected;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final price = plan.priceFor(period);
    final symbol = plan.currency.toUpperCase() == 'INR' ? '₹' : plan.currency;
    return AnimatedContainer(
      duration: AppMotion.standard,
      decoration: BoxDecoration(
        color: colors.cardBackground,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: selected || plan.isRecommended
              ? colors.primary
              : colors.border,
          width: selected ? 2 : 1,
        ),
      ),
      padding: const EdgeInsets.all(AppSpacing.card),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (plan.isRecommended)
            Align(
              alignment: Alignment.centerLeft,
              child: _StatusPill(
                label: 'MOST POPULAR',
                color: colors.primary,
                background: colors.primarySoft,
              ),
            ),
          if (plan.isRecommended) const SizedBox(height: AppSpacing.sm),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      plan.name,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    Text(
                      '${plan.monthlyAiCredits} AI credits / month',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '$symbol${price.toStringAsFixed(price % 1 == 0 ? 0 : 2)}',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          for (final feature in plan.features)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.check_circle_outline_rounded,
                    size: 18,
                    color: colors.secondary,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text(
                      feature,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: AppSpacing.sm),
          AppButton(
            label: isCurrent ? 'Current plan' : 'Choose ${plan.name}',
            icon: isCurrent ? Icons.check_rounded : Icons.arrow_forward_rounded,
            loading: loading,
            variant: isCurrent
                ? AppButtonVariant.secondary
                : AppButtonVariant.primary,
            onPressed: isCurrent || !plan.isActive ? null : onSelected,
          ),
        ],
      ),
    );
  }
}

enum AiActionButtonState {
  idle,
  loading,
  disabled,
  insufficientCredits,
  success,
}

class AiActionButton extends StatelessWidget {
  const AiActionButton({
    super.key,
    required this.label,
    required this.creditCost,
    required this.availableCredits,
    required this.onPressed,
    required this.onInsufficientCredits,
    this.state = AiActionButtonState.idle,
  });
  final String label;
  final int creditCost;
  final int availableCredits;
  final VoidCallback onPressed;
  final VoidCallback onInsufficientCredits;
  final AiActionButtonState state;

  @override
  Widget build(BuildContext context) {
    final insufficient =
        state == AiActionButtonState.insufficientCredits ||
        availableCredits < creditCost;
    return AppButton(
      label: state == AiActionButtonState.success
          ? 'Completed'
          : '$label · $creditCost ${creditCost == 1 ? 'credit' : 'credits'}',
      icon: state == AiActionButtonState.success
          ? Icons.check_rounded
          : Icons.auto_awesome_rounded,
      loading: state == AiActionButtonState.loading,
      onPressed: state == AiActionButtonState.disabled
          ? null
          : insufficient
          ? onInsufficientCredits
          : onPressed,
      semanticLabel: insufficient
          ? '$label. Requires $creditCost credits. Not enough credits.'
          : '$label. Uses $creditCost credits.',
    );
  }
}

Future<void> showInsufficientCreditsSheet({
  required BuildContext context,
  required String operation,
  required int requiredCredits,
  required int availableCredits,
  required VoidCallback onViewPlans,
  DateTime? resetDate,
}) => showModalBottomSheet<void>(
  context: context,
  showDragHandle: true,
  isScrollControlled: true,
  builder: (sheetContext) => SafeArea(
    child: Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.screen,
        AppSpacing.sm,
        AppSpacing.screen,
        AppSpacing.xl + MediaQuery.viewInsetsOf(sheetContext).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(
            Icons.bolt_rounded,
            size: 40,
            color: AppColors.of(sheetContext).warning,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Not enough AI credits',
            textAlign: TextAlign.center,
            style: Theme.of(sheetContext).textTheme.titleLarge,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '$operation needs $requiredCredits credits, but you have $availableCredits remaining.${resetDate == null ? '' : ' Your credits reset ${DateFormat('MMM d').format(resetDate.toLocal())}.'}',
            textAlign: TextAlign.center,
            style: Theme.of(sheetContext).textTheme.bodyMedium?.copyWith(
              color: AppColors.of(sheetContext).textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          AppPrimaryButton(
            label: 'View plans',
            onPressed: () {
              Navigator.pop(sheetContext);
              onViewPlans();
            },
          ),
          const SizedBox(height: AppSpacing.xs),
          AppButton(
            label: 'Maybe later',
            variant: AppButtonVariant.text,
            onPressed: () => Navigator.pop(sheetContext),
          ),
        ],
      ),
    ),
  ),
);

class CreditNotice extends StatelessWidget {
  const CreditNotice({
    super.key,
    required this.account,
    required this.onViewPlans,
  });
  final AiCreditAccount account;
  final VoidCallback onViewPlans;
  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final empty = account.availableCredits == 0;
    if (!empty && account.availableCredits > account.monthlyAllocation * .25) {
      return const SizedBox.shrink();
    }
    return AppCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            empty ? Icons.info_outline_rounded : Icons.warning_amber_rounded,
            color: empty ? colors.info : colors.warning,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  empty
                      ? "You've used all your AI credits"
                      : '${account.availableCredits} credits remaining',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  empty
                      ? 'Your normal resume tools are still available. Upgrade or wait for the next reset to use AI features.'
                      : "You're running low on AI credits.",
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: colors.textSecondary),
                ),
                const SizedBox(height: AppSpacing.xs),
                TextButton(
                  onPressed: onViewPlans,
                  child: const Text('View plans'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({
    required this.label,
    required this.color,
    required this.background,
  });
  final String label;
  final Color color;
  final Color background;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(
      horizontal: AppSpacing.xs,
      vertical: AppSpacing.xxs,
    ),
    decoration: BoxDecoration(
      color: background,
      borderRadius: BorderRadius.circular(AppRadius.pill),
    ),
    child: Text(
      label,
      style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color),
    ),
  );
}

IconData _operationIcon(String operation) => switch (operation) {
  'summary' => Icons.subject_rounded,
  'improve_bullet' => Icons.edit_note_rounded,
  'skills' => Icons.psychology_outlined,
  'ats' => Icons.fact_check_outlined,
  'jd_optimization' => Icons.tune_rounded,
  'cover_letter' => Icons.mail_outline_rounded,
  'interview' => Icons.record_voice_over_outlined,
  _ => Icons.auto_awesome_rounded,
};

String _titleCase(String value) =>
    value.isEmpty ? value : '${value[0].toUpperCase()}${value.substring(1)}';
