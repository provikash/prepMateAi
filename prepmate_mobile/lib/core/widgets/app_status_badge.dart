import 'package:flutter/material.dart';

import '../../config/theme.dart';

enum AppStatus { neutral, info, success, warning, error }

class AppStatusBadge extends StatelessWidget {
  const AppStatusBadge({
    super.key,
    required this.label,
    this.status = AppStatus.neutral,
    this.icon,
  });

  final String label;
  final AppStatus status;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final (foreground, background) = switch (status) {
      AppStatus.info => (colors.info, colors.infoSoft),
      AppStatus.success => (colors.success, colors.successSoft),
      AppStatus.warning => (colors.warning, colors.warningSoft),
      AppStatus.error => (colors.error, colors.errorSoft),
      AppStatus.neutral => (colors.textSecondary, colors.mutedBackground),
    };

    return Semantics(
      label: '$label, ${status.name}',
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, color: foreground, size: 16),
              const SizedBox(width: AppSpacing.xxs),
            ],
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.labelMedium?.copyWith(color: foreground),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
