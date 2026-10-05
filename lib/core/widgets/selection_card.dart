import 'package:flutter/material.dart';
import '../../config/theme.dart';

/// Reusable selection card matching Stitch screen 06 (Experience level)
/// and multi-option selection flows.
class SelectionCard extends StatelessWidget {
  const SelectionCard({
    super.key,
    required this.title,
    String? description,
    String? subtitle,
    bool? selected,
    bool? isSelected,
    required this.onTap,
    this.icon,
    String? badgeText,
    String? badge,
    this.badgeColor,
  }) : description = description ?? subtitle ?? '',
       selected = selected ?? isSelected ?? false,
       badgeText = badgeText ?? badge;

  final String title;
  final String description;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;
  final String? badgeText;
  final Color? badgeColor;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return Semantics(
      selected: selected,
      button: true,
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
              color: selected
                  ? colors.primarySoft.withValues(alpha: 0.5)
                  : colors.cardBackground,
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
                  blurRadius: selected ? 8 : 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                if (icon != null) ...[
                  AnimatedContainer(
                    duration: AppMotion.fast,
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: selected
                          ? colors.primary
                          : colors.iconSoftBackground,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: Center(
                      child: Icon(
                        icon,
                        size: 24,
                        color: selected ? colors.onStatus : colors.primary,
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
                          Flexible(
                            child: Text(
                              title,
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(
                                    fontWeight: selected
                                        ? FontWeight.w700
                                        : FontWeight.w600,
                                    color: colors.textPrimary,
                                  ),
                            ),
                          ),
                          if (badgeText != null) ...[
                            const SizedBox(width: AppSpacing.xs),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: badgeColor ?? colors.secondary,
                                borderRadius: BorderRadius.circular(
                                  AppRadius.pill,
                                ),
                              ),
                              child: Text(
                                badgeText!,
                                style: Theme.of(context).textTheme.labelSmall
                                    ?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        description,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                // Radio indicator
                AnimatedContainer(
                  duration: AppMotion.fast,
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: selected ? colors.primary : Colors.transparent,
                    border: Border.all(
                      color: selected ? colors.primary : colors.border,
                      width: 2,
                    ),
                  ),
                  child: selected
                      ? const Center(
                          child: Icon(
                            Icons.check,
                            size: 16,
                            color: Colors.white,
                          ),
                        )
                      : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
