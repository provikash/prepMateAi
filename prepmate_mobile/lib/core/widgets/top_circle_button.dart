
import 'package:flutter/material.dart';
import '../../config/theme.dart';


class topCircleButton extends StatelessWidget {
  const topCircleButton({
    super.key,
    required this.context,
    required this.icon,
    required this.onTap,
  });

  final BuildContext context;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: colors.cardBackground,
            border: Border.all(color: colors.border),
          ),
          child: Icon(icon, size: 20, color: colors.primary),
        ),
      ),
    );
  }
}
