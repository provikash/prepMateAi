import 'package:flutter/material.dart';

import '../../config/theme.dart';
import 'app_loading.dart';

enum AppButtonVariant { primary, secondary, text, destructive }

class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.variant = AppButtonVariant.primary,
    this.loading = false,
    this.expand = true,
    this.semanticLabel,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final AppButtonVariant variant;
  final bool loading;
  final bool expand;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final effectiveOnPressed = loading ? null : onPressed;
    final foreground = switch (variant) {
      AppButtonVariant.primary => Theme.of(context).colorScheme.onPrimary,
      AppButtonVariant.destructive => colors.onStatus,
      _ =>
        variant == AppButtonVariant.text ? colors.primary : colors.textPrimary,
    };
    final content = AnimatedSwitcher(
      duration: AppMotion.fast,
      child: loading
          ? AppLoading(key: const ValueKey('loading'), color: foreground)
          : Row(
              key: const ValueKey('content'),
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: AppSizes.iconSmall),
                  const SizedBox(width: AppSpacing.xs),
                ],
                Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
              ],
            ),
    );

    final button = switch (variant) {
      AppButtonVariant.primary => FilledButton(
        onPressed: effectiveOnPressed,
        child: content,
      ),
      AppButtonVariant.secondary => OutlinedButton(
        onPressed: effectiveOnPressed,
        child: content,
      ),
      AppButtonVariant.text => TextButton(
        onPressed: effectiveOnPressed,
        child: content,
      ),
      AppButtonVariant.destructive => FilledButton(
        onPressed: effectiveOnPressed,
        style: FilledButton.styleFrom(
          backgroundColor: colors.error,
          foregroundColor: colors.onStatus,
        ),
        child: content,
      ),
    };

    return Semantics(
      button: true,
      label: semanticLabel ?? label,
      child: SizedBox(width: expand ? double.infinity : null, child: button),
    );
  }
}

class AppPrimaryButton extends StatelessWidget {
  const AppPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.loading = false,
    this.expand = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool loading;
  final bool expand;

  @override
  Widget build(BuildContext context) => AppButton(
    label: label,
    onPressed: onPressed,
    icon: icon,
    loading: loading,
    expand: expand,
  );
}

class AppSecondaryButton extends StatelessWidget {
  const AppSecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.loading = false,
    this.expand = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool loading;
  final bool expand;

  @override
  Widget build(BuildContext context) => AppButton(
    label: label,
    onPressed: onPressed,
    icon: icon,
    loading: loading,
    expand: expand,
    variant: AppButtonVariant.secondary,
  );
}
