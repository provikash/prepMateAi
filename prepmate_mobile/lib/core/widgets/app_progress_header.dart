import 'package:flutter/material.dart';

import '../../config/theme.dart';

class AppProgressHeader extends StatelessWidget {
  const AppProgressHeader({
    super.key,
    required this.title,
    required this.currentStep,
    required this.totalSteps,
    this.subtitle,
  }) : assert(currentStep >= 0),
       assert(totalSteps > 0),
       assert(currentStep <= totalSteps);

  final String title;
  final String? subtitle;
  final int currentStep;
  final int totalSteps;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final progress = currentStep / totalSteps;
    return Semantics(
      label: '$title, step $currentStep of $totalSteps',
      value: '${(progress * 100).round()} percent',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              Text(
                '$currentStep / $totalSteps',
                style: Theme.of(
                  context,
                ).textTheme.labelMedium?.copyWith(color: colors.textSecondary),
              ),
            ],
          ),
          if (subtitle != null) ...[
            const SizedBox(height: AppSpacing.xxs),
            Text(
              subtitle!,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: colors.textSecondary),
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            child: TweenAnimationBuilder<double>(
              tween: Tween(end: progress),
              duration: MediaQuery.disableAnimationsOf(context)
                  ? Duration.zero
                  : AppMotion.standard,
              builder: (context, value, _) =>
                  LinearProgressIndicator(value: value, minHeight: 8),
            ),
          ),
        ],
      ),
    );
  }
}
