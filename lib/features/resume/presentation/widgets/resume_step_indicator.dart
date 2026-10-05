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
    final navigationProgress = totalSteps == 1
        ? 1.0
        : safeStep / (totalSteps - 1);
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
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Step ${safeStep + 1} of $totalSteps',
                          style: TextStyle(color: colors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '${(completionProgress * 100).round()}% complete',
                    style: TextStyle(
                      color: colors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TweenAnimationBuilder<double>(
                tween: Tween(end: navigationProgress),
                duration: duration,
                curve: Curves.easeOutCubic,
                builder: (context, value, _) => ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: LinearProgressIndicator(
                    value: value,
                    minHeight: 9,
                    color: colors.primary,
                    backgroundColor: colors.mutedBackground,
                    semanticsLabel: 'Resume journey progress',
                    semanticsValue: '${(value * 100).round()}',
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 42,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: totalSteps,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final active = index == safeStep;
                    final complete = completedSteps.contains(index);
                    final itemTitle = index < sectionTitles.length
                        ? sectionTitles[index]
                        : 'Step ${index + 1}';
                    return Semantics(
                      button: true,
                      selected: active,
                      label:
                          '$itemTitle, step ${index + 1} of $totalSteps${complete ? ', complete' : ', incomplete'}',
                      child: AnimatedContainer(
                        duration: duration,
                        decoration: BoxDecoration(
                          color: active
                              ? colors.primary
                              : complete
                              ? colors.mutedBackground
                              : colors.cardBackground,
                          borderRadius: BorderRadius.circular(99),
                          border: Border.all(
                            color: active || complete
                                ? colors.primary
                                : colors.border,
                          ),
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(99),
                          onTap: () => onStepTapped(index),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Row(
                              children: [
                                Icon(
                                  complete ? Icons.check_circle : Icons.circle,
                                  size: 16,
                                  color: active
                                      ? colors.cardBackground
                                      : complete
                                      ? colors.primary
                                      : colors.textSecondary,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '${index + 1}',
                                  style: TextStyle(
                                    color: active
                                        ? colors.cardBackground
                                        : colors.textPrimary,
                                    fontWeight: active
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
