import 'package:flutter/material.dart';

import '../../../../config/theme.dart';

class ResumeStepIndicator extends StatelessWidget {
  final int currentStep;
  final int totalSteps;
  final ValueChanged<int> onStepTapped;

  const ResumeStepIndicator({
    super.key,
    required this.currentStep,
    required this.totalSteps,
    required this.onStepTapped,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    if (totalSteps == 0) return const SizedBox.shrink();
    return SizedBox(
      height: 30,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: totalSteps,
        separatorBuilder: (_, __) => Container(
          width: 18,
          height: 2,
          color: colors.border,
        ),
        itemBuilder: (context, index) {
          final completed = index < currentStep;
          final active = index == currentStep;
          return InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => onStepTapped(index),
            child: CircleAvatar(
              radius: 13,
              backgroundColor: completed || active ? colors.primary : colors.mutedBackground,
              child: Icon(
                completed ? Icons.check : Icons.circle,
                size: completed ? 16 : 9,
                color: completed || active ? colors.cardBackground : colors.textSecondary,
              ),
            ),
          );
        },
      ),
    );
  }
}
