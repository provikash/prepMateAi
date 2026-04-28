import 'package:flutter/material.dart';
import '../../config/theme.dart';

class GradientButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String text;
  final double borderRadius;
  final double height;
  final Widget? trailing;

  const GradientButton({
    super.key,
    required this.onPressed,
    required this.text,
    this.borderRadius = 22,
    this.height = 52,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = AppColors.of(context);
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        height: height,
        // decoration: BoxDecoration(
        //   gradient: AppTheme.buttonGradient,
        //   borderRadius: BorderRadius.circular(borderRadius),
        //   boxShadow: [
        //     BoxShadow(
        //       color: theme.primaryColor.withOpacity(0.18),
        //       blurRadius: 18,
        //       offset: const Offset(0, 8),
        //     )
        //   ],
        // ),

        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [colors.primary, colors.primary.withValues(alpha: 0.75)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          boxShadow: [
            BoxShadow(
              color: colors.primary.withValues(alpha: 0.3),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 18),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              text,
              style: theme.textTheme.labelMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: 8),
              trailing!,
            ]
          ],
        ),
      ),
    );
  }
}
