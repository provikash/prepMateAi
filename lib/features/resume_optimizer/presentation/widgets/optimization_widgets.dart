import 'package:flutter/material.dart';
import '../../../../config/theme.dart';
import '../../../../core/widgets/app_card.dart';
import '../../domain/optimization_models.dart';

class OptimizationStepHeader extends StatelessWidget {
  const OptimizationStepHeader({super.key, required this.step});
  final int step;
  static const labels = ['Target', 'Analysis', 'Suggest', 'ATS Score'];
  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Semantics(
      label: 'Optimization progress, step $step of 4',
      child: Row(
        children: List.generate(4, (index) {
          final active = index < step;
          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: index == 3 ? 0 : AppSpacing.xs),
              child: Column(
                children: [
                  AnimatedContainer(
                    duration: AppMotion.fast,
                    height: 4,
                    decoration: BoxDecoration(
                      color: active ? colors.primary : colors.border,
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    '${index + 1}. ${labels[index]}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: active ? colors.primary : colors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}

class CreditBadge extends StatelessWidget {
  const CreditBadge({super.key, required this.credits});
  final int credits;
  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Semantics(
      label: '$credits AI credits remaining',
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: colors.primarySoft,
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.auto_awesome, size: 15, color: colors.primary),
            const SizedBox(width: 5),
            Text(
              '$credits AI',
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

class ScoreRing extends StatelessWidget {
  const ScoreRing({super.key, required this.score, this.label = 'Alignment'});
  final int score;
  final String label;
  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return SizedBox.square(
      dimension: 132,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox.square(
            dimension: 124,
            child: CircularProgressIndicator(
              value: score / 100,
              strokeWidth: 10,
              strokeCap: StrokeCap.round,
              backgroundColor: colors.primarySoft,
              color: colors.secondary,
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$score%',
                style: Theme.of(
                  context,
                ).textTheme.headlineMedium?.copyWith(color: colors.secondary),
              ),
              Text(
                label,
                style: Theme.of(
                  context,
                ).textTheme.labelSmall?.copyWith(color: colors.textSecondary),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class StatusPill extends StatelessWidget {
  const StatusPill({super.key, required this.status});
  final SuggestionStatus status;
  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final (label, icon, color, bg) = switch (status) {
      SuggestionStatus.accepted => (
        'Accepted',
        Icons.check_circle_outline,
        colors.success,
        colors.successSoft,
      ),
      SuggestionStatus.rejected => (
        'Rejected',
        Icons.cancel_outlined,
        colors.error,
        colors.errorSoft,
      ),
      SuggestionStatus.edited => (
        'Edited',
        Icons.edit_outlined,
        colors.info,
        colors.infoSoft,
      ),
      SuggestionStatus.pending => (
        'Pending',
        Icons.schedule,
        colors.warning,
        colors.warningSoft,
      ),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.labelSmall?.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}

class InformationBanner extends StatelessWidget {
  const InformationBanner({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
  });
  final IconData icon;
  final String title;
  final String message;
  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return AppCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: colors.infoSoft,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Icon(icon, color: colors.info, size: 20),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 3),
                Text(
                  message,
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

class ResponsiveContent extends StatelessWidget {
  const ResponsiveContent({
    super.key,
    required this.child,
    this.maxWidth = 920,
  });
  final Widget child;
  final double maxWidth;
  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.topCenter,
    child: ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: child,
    ),
  );
}
