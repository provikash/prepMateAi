import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/theme.dart';
import '../../../../core/widgets/app_button.dart';
import '../authWidgets/auth_shell.dart';

class PasswordChangedScreen extends StatelessWidget {
  const PasswordChangedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return AuthShell(
      title: 'Password updated',
      subtitle: 'Your password was changed successfully.',
      icon: Icons.check_circle_outline_rounded,
      showBack: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: colors.successSoft,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.verified_user_outlined, color: colors.success),
                const SizedBox(width: AppSpacing.sm),
                const Expanded(
                  child: Text(
                    'You can now sign in using your new credentials.',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          AppPrimaryButton(
            label: 'Back to sign in',
            onPressed: () => context.go('/login'),
          ),
        ],
      ),
    );
  }
}
