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

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  Future<void> _sendOtp() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final email = _emailController.text.trim();
    final sent = await ref
        .read(authViewModelProvider.notifier)
        .forgotPassword(email);
    if (!mounted || !sent) return;
    context.push(
      Uri(
        path: '/verify-otp',
        queryParameters: {'flow': 'reset', 'email': email},
      ).toString(),
      extra: email,
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(authViewModelProvider);
    return AuthShell(
      title: 'Reset your password',
      subtitle:
          'Enter your email and we’ll send you a six-digit verification code.',
      icon: Icons.lock_reset_rounded,
      footer: TextButton(
        onPressed: () => context.go('/login'),
        child: const Text('Back to sign in'),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Email address',
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const SizedBox(height: AppSpacing.xs),
            AppInputField(
              controller: _emailController,
              label: 'Email address',
              hint: 'name@company.com',
              prefixIcon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                final email = value?.trim() ?? '';
                if (email.isEmpty) return 'Enter your email address';
                if (!RegExp(
                  r'^[\w\-.]+@([\w-]+\.)+[\w-]{2,}$',
                ).hasMatch(email)) {
                  return 'Enter a valid email address';
                }
                return null;
              },
            ),
            ErrorText(message: state.errorMessage),
            const SizedBox(height: AppSpacing.lg),
            AppPrimaryButton(
              label: 'Send verification code',
              icon: Icons.arrow_forward_rounded,
              loading: state.status == AuthStatus.loading,
              onPressed: _sendOtp,
            ),
          ],
        ),
      ),
    );
  }
}
