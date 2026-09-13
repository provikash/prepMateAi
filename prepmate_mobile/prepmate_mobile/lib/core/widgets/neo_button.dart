import 'package:flutter/material.dart';
import '../../config/theme.dart';

class NeuButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback? onPressed;
  final String text;
  final IconData? icon;

  const NeuButton({
    super.key,
    required this.isLoading,
    required this.onPressed,
    required this.text,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: isLoading ? null : onPressed,
      child: Container(
        width: double.infinity,
        height: 55,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),

          // gradient comes from theme
          gradient: AppTheme.buttonGradient,

          boxShadow: [
            BoxShadow(
              color: theme.primaryColor.withOpacity(.35),
              blurRadius: 20,
              offset: const Offset(0, 10),
            )
          ],
        ),
        child: Center(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: isLoading
                ? const SizedBox(
              key: ValueKey("loading"),
              height: 22,
              width: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: Colors.white,
              ),
            )
                : Row(
              key: const ValueKey("text"),
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  text,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                if (icon != null) ...[
                  const SizedBox(width: 8),
                  Icon(icon, color: Colors.white, size: 20),
                ]
              ],
            ),
          ),
        ),
      ),
    );
  }
}