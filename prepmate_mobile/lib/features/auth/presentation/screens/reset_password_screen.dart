import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/theme.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_input_field.dart';
import '../../../../core/widgets/error_text.dart';
import '../authWidgets/auth_shell.dart';
import '../state/auth_state.dart';
import '../viewmodel/auth_viewmodel.dart';

class ResetPasswordScreen extends ConsumerStatefulWidget {
  const ResetPasswordScreen({
    super.key,
    required this.email,
    required this.otp,
  });

  final String email;
  final String otp;

  @override
  ConsumerState<ResetPasswordScreen> createState() =>
      _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _has8Char = false;
  bool _hasSpecial = false;
  bool _hasUppercase = false;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _updatePassword() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final success = await ref
        .read(authProvider.notifier)
        .resetPassword(widget.email, widget.otp, _passwordController.text);
    if (success && mounted) context.go('/password-changed');
  }

  void _checkPassword(String password) {
    setState(() {
      _has8Char = password.length >= 8;
      _hasSpecial = RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password);
      _hasUppercase = RegExp(r'[A-Z]').hasMatch(password);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(authViewModelProvider);
    return AuthShell(
      title: 'Set a new password',
      subtitle: 'Choose a strong password you haven’t used for this account.',
      icon: Icons.password_rounded,
      footer: TextButton(
        onPressed: () => context.go('/login'),
        child: const Text('Cancel and return to sign in'),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('New password', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: AppSpacing.xs),
            AppInputField(
              controller: _passwordController,
              label: 'New password',
              hint: 'Enter your new password',
              prefixIcon: Icons.lock_outline_rounded,
              isPassword: true,
              onChanged: _checkPassword,
              validator: (_) => (!_has8Char || !_hasUppercase || !_hasSpecial)
                  ? 'Meet all password requirements'
                  : null,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Confirm password',
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const SizedBox(height: AppSpacing.xs),
            AppInputField(
              controller: _confirmController,
              label: 'Confirm password',
              hint: 'Repeat your new password',
              prefixIcon: Icons.lock_outline_rounded,
              isPassword: true,
              validator: (value) => value != _passwordController.text
                  ? 'Passwords do not match'
                  : null,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'PASSWORD REQUIREMENTS',
              style: Theme.of(context).textTheme.labelSmall,
            ),
            const SizedBox(height: AppSpacing.sm),
            _Requirement(valid: _has8Char, text: 'At least 8 characters'),
            _Requirement(valid: _hasSpecial, text: 'One special character'),
            _Requirement(valid: _hasUppercase, text: 'One uppercase letter'),
            ErrorText(message: state.errorMessage),
            const SizedBox(height: AppSpacing.lg),
            AppPrimaryButton(
              label: 'Update password',
              loading: state.status == AuthStatus.loading,
              onPressed: _updatePassword,
            ),
          ],
        ),
      ),
    );
  }
}

class _Requirement extends StatelessWidget {
  const _Requirement({required this.valid, required this.text});

  final bool valid;
  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Semantics(
      label: '$text: ${valid ? 'met' : 'not met'}',
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxs),
        child: Row(
          children: [
            Icon(
              valid ? Icons.check_circle_rounded : Icons.circle_outlined,
              size: AppSizes.iconSmall,
              color: valid ? colors.success : colors.textSecondary,
            ),
            const SizedBox(width: AppSpacing.xs),
            Expanded(child: Text(text)),
          ],
        ),
      ),
    );
  }
}
