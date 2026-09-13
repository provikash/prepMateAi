import 'package:flutter/material.dart';
import '../../config/theme.dart';

class SocialButton extends StatelessWidget {
  final String text;
  final IconData icon;
  final VoidCallback onTap;

  const SocialButton({
    super.key,
    required this.text,
    required this.icon,
    required this.onTap,
  });

  BoxDecoration _decoration(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BoxDecoration(
      color: isDark
          ? AppTheme.darkSurface
          : Theme.of(context).scaffoldBackgroundColor,
      borderRadius: BorderRadius.circular(16),
      boxShadow: isDark ? AppTheme.darkShadow : AppTheme.lightShadow,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 50,
        decoration: _decoration(context),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20, color: theme.textTheme.labelMedium?.color),
            const SizedBox(width: 10),
            Text(text, style: theme.textTheme.labelMedium),
          ],
        ),
      ),
    );
  }
}
