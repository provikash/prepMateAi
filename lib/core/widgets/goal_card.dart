import 'package:flutter/material.dart';
import '../../config/theme.dart';

/// Reusable goal card matching Stitch screen 02 (Career Preferences & Goals).
class GoalCard extends StatelessWidget {
  const GoalCard({
    super.key,
    required this.title,
    String? description,
    String? subtitle,
    bool? selected,
    bool? isSelected,
    required this.onTap,
    this.icon,
  }) : description = description ?? subtitle ?? '',
       selected = selected ?? isSelected ?? false;

  final String title;
  final String description;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return Semantics(
      button: true,
      selected: selected,
      label: '$title: $description',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: AnimatedContainer(
            duration: AppMotion.fast,
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: selected ? colors.primarySoft : colors.cardBackground,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(
                color: selected ? colors.primary : colors.border,
                width: selected ? 1.5 : 1.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: selected
                      ? colors.primary.withValues(alpha: 0.08)
                      : colors.textPrimary.withValues(alpha: 0.03),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (icon != null) ...[
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: selected
                          ? colors.cardBackground
                          : colors.iconSoftBackground,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: Center(
                      child: Icon(
                        icon,
                        size: 20,
                        color: selected ? colors.primary : colors.textSecondary,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: Theme.of(context).textTheme.titleSmall
                                  ?.copyWith(
                                    fontWeight: selected
                                        ? FontWeight.w700
                                        : FontWeight.w600,
                                    color: selected
                                        ? colors.primary
                                        : colors.textPrimary,
                                  ),
                            ),
                          ),
                          Icon(
                            selected
                                ? Icons.check_circle_rounded
                                : Icons.radio_button_unchecked_rounded,
                            size: 20,
                            color: selected ? colors.primary : colors.border,
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        description,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
