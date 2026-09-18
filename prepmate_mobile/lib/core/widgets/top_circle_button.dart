import 'package:flutter/material.dart';

import '../../config/theme.dart';

class TopCircleButton extends StatelessWidget {
  const TopCircleButton({
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
    return IconButton(
      tooltip: icon == Icons.arrow_back || icon == Icons.arrow_back_ios_new
          ? 'Back'
          : null,
      onPressed: onTap,
      style: IconButton.styleFrom(
        backgroundColor: colors.cardBackground,
        foregroundColor: colors.primary,
        side: BorderSide(color: colors.border),
      ),
      icon: Icon(icon, size: AppSizes.iconSmall),
    );
  }
}
