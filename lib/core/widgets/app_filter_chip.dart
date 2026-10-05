import 'package:flutter/material.dart';
import '../../config/theme.dart';

/// Reusable filter chip matching Stitch screen 02, 11, and 12.
class AppFilterChip extends StatelessWidget {
  const AppFilterChip({
    super.key,
    required this.label,
    bool? selected,
    bool? isSelected,
    required this.onSelected,
    this.icon,
    this.count,
  }) : selected = selected ?? isSelected ?? false;

  final String label;
  final bool selected;
  final ValueChanged<bool> onSelected;
  final IconData? icon;
  final int? count;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    final displayLabel = count != null ? '$label ($count)' : label;

    return Semantics(
      button: true,
      selected: selected,
      label: displayLabel,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => onSelected(!selected),
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: AnimatedContainer(
            duration: AppMotion.fast,
            constraints: const BoxConstraints(minHeight: 44),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
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
              mainAxisSize: MainAxisSize.min,
              children: [
                if (selected) ...[
                  Icon(Icons.check, size: 16, color: colors.primary),
                  const SizedBox(width: 6),
                ] else if (icon != null) ...[
                  Icon(icon, size: 16, color: colors.textSecondary),
                  const SizedBox(width: 6),
                ],
                Text(
                  displayLabel,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                    color: selected ? colors.primary : colors.textPrimary,
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
