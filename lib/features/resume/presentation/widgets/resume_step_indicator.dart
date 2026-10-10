import 'package:flutter/material.dart';

import '../../../../config/theme.dart';

class ResumeStepIndicator extends StatelessWidget {
  const ResumeStepIndicator({
    super.key,
    required this.currentStep,
    required this.totalSteps,
    required this.sectionTitles,
    required this.onStepTapped,
    this.completedSteps = const {},
    this.completionPercent,
  });

  final int currentStep;
  final int totalSteps;
  final List<String> sectionTitles;
  final ValueChanged<int> onStepTapped;
  final Set<int> completedSteps;
  final int? completionPercent;

  @override
  Widget build(BuildContext context) {
    if (totalSteps <= 0) return const SizedBox.shrink();
    final colors = AppColors.of(context);
    final safeStep = currentStep.clamp(0, totalSteps - 1);
    final navigationProgress = (safeStep + 1) / totalSteps;
    final completionProgress = completionPercent == null
        ? completedSteps.length.clamp(0, totalSteps) / totalSteps
        : completionPercent!.clamp(0, 100) / 100;
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final duration = reduceMotion
        ? Duration.zero
        : const Duration(milliseconds: 320);
    final title = safeStep < sectionTitles.length
        ? sectionTitles[safeStep]
        : 'Resume section';

    return Semantics(
      container: true,
      label:
          '$title. Step ${safeStep + 1} of $totalSteps. ${(completionProgress * 100).round()} percent complete.',
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.cardBackground,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: colors.border),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Step ${safeStep + 1} of $totalSteps',
                        style: TextStyle(
                          color: colors.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                      Text(
                        '${(completionProgress * 100).round()}% complete',
                        style: TextStyle(
                          color: colors.primary,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TweenAnimationBuilder<double>(
                tween: Tween(end: navigationProgress),
                duration: duration,
                curve: Curves.easeOutCubic,
                builder: (context, value, _) => ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: LinearProgressIndicator(
                    value: value,
                    minHeight: 6,
                    color: colors.primary,
                    backgroundColor: colors.mutedBackground,
                    semanticsLabel: 'Resume journey progress',
                    semanticsValue: '${(value * 100).round()}',
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
