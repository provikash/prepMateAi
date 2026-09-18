import 'package:flutter/material.dart';

import '../../config/theme.dart';

/// Backward-compatible primary action without the legacy decorative gradient.
class GradientButton extends StatelessWidget {
  const GradientButton({
    super.key,
    required this.onPressed,
    required this.text,
    this.borderRadius = AppRadius.md,
    this.height = AppSizes.buttonHeight,
    this.trailing,
  });

  final VoidCallback? onPressed;
  final String text;
  final double borderRadius;
  final double height;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    height: height,
    child: FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(child: Text(text, overflow: TextOverflow.ellipsis)),
          if (trailing != null) ...[
            const SizedBox(width: AppSpacing.xs),
            trailing!,
          ],
        ],
      ),
    ),
  );
}
