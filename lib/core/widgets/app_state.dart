import 'package:flutter/material.dart';

import '../../config/theme.dart';
import 'app_button.dart';
import 'app_loading.dart';

class AppLoadingState extends StatelessWidget {
  const AppLoadingState({
    super.key,
    this.label = 'Loading your content',
    this.compact = false,
  });

  final String label;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final child = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const AppLoading(),
        const SizedBox(height: AppSpacing.md),
        Text(
          label,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppColors.of(context).textSecondary,
          ),
        ),
      ],
    );
    return Semantics(
      liveRegion: true,
      label: label,
      child: compact ? child : Center(child: child),
    );
  }
}

class AppEmptyState extends StatelessWidget {
  const AppEmptyState({
    super.key,
    required this.title,
    required this.message,
    this.icon = Icons.inbox_outlined,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String message;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => _AppMessageState(
    icon: icon,
    iconColor: AppColors.of(context).primary,
    iconBackground: AppColors.of(context).primarySoft,
    title: title,
    message: message,
    actionLabel: actionLabel,
    onAction: onAction,
  );
}

class AppErrorState extends StatelessWidget {
  const AppErrorState({
    super.key,
    this.title = 'Something went wrong',
    required this.message,
    this.actionLabel = 'Try again',
    this.onAction,
  });

  final String title;
  final String message;
  final String actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => _AppMessageState(
    icon: Icons.error_outline_rounded,
    iconColor: AppColors.of(context).error,
    iconBackground: AppColors.of(context).errorSoft,
    title: title,
    message: message,
    actionLabel: onAction == null ? null : actionLabel,
    onAction: onAction,
  );
}

class _AppMessageState extends StatelessWidget {
  const _AppMessageState({
    required this.icon,
    required this.iconColor,
    required this.iconBackground,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final Color iconColor;
  final Color iconBackground;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 360),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: iconBackground,
                borderRadius: BorderRadius.circular(AppRadius.xl),
              ),
              child: Icon(icon, color: iconColor, size: 30),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.of(context).textSecondary,
              ),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: AppSpacing.lg),
              AppPrimaryButton(
                label: actionLabel!,
                onPressed: onAction,
                expand: false,
              ),
            ],
          ],
        ),
      ),
    ),
  );
}
