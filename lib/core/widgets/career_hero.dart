import 'package:flutter/material.dart';

import '../../config/theme.dart';

class CareerHero extends StatelessWidget {
  const CareerHero({super.key, required this.onBuild, required this.onAnalyze});

  final VoidCallback onBuild;
  final VoidCallback onAnalyze;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final onPrimary = Theme.of(context).colorScheme.onPrimary;
    return Container(
      margin: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        0,
        AppSpacing.md,
        AppSpacing.lg,
      ),
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: colors.primary,
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome_rounded, color: onPrimary, size: 18),
              const SizedBox(width: AppSpacing.xs),
              Flexible(
                child: Text(
                  'MAKE YOUR NEXT MOVE',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: onPrimary,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'A stronger resume.\nA clearer next step.',
            style: Theme.of(
              context,
            ).textTheme.headlineMedium?.copyWith(color: onPrimary),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Build your story, understand your strengths, and learn what comes next.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: onPrimary.withValues(alpha: 0.88),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              FilledButton.icon(
                onPressed: onBuild,
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Build resume'),
                style: FilledButton.styleFrom(
                  backgroundColor: onPrimary,
                  foregroundColor: colors.primary,
                ),
              ),
              OutlinedButton(
                onPressed: onAnalyze,
                style: OutlinedButton.styleFrom(
                  foregroundColor: onPrimary,
                  side: BorderSide(color: onPrimary.withValues(alpha: 0.75)),
                ),
                child: const Text('Check my resume'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
