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

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submitSignup() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    await ref
        .read(authViewModelProvider.notifier)
        .signup(
          name: _nameController.text.trim(),
          email: _emailController.text.trim(),
          password: _passwordController.text,
          passwordConfirm: _confirmPasswordController.text,
        );
  }

  Future<void> _onGoogleTap() async {
    await ref.read(authViewModelProvider.notifier).signInWithGoogle();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(authViewModelProvider, (previous, next) {
      if (next.status == AuthStatus.success && next.email != null) {
        context.push('/verify-otp', extra: next.email);
      } else if (next.status == AuthStatus.authenticated) {
        final intended = GoRouterState.of(context).uri.queryParameters['from'];
        context.go(intended ?? '/home');
      }
    });
    final state = ref.watch(authViewModelProvider);
    final loading = state.status == AuthStatus.loading;
    final colors = AppColors.of(context);

    Widget label(String text) => Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Text(text, style: Theme.of(context).textTheme.labelLarge),
    );

    return AuthShell(
      title: 'Create your account',
      subtitle: 'Start building a stronger career profile today.',
      footer: Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(
            'Already have an account?',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: colors.textSecondary),
          ),
          TextButton(
            onPressed: () => context.go('/login'),
            child: const Text('Sign in'),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            label('Full name'),
            AppInputField(
              controller: _nameController,
              label: 'Full name',
              hint: 'Jane Doe',
              prefixIcon: Icons.person_outline_rounded,
              capitalization: TextCapitalization.words,
              validator: (value) => (value?.trim().isEmpty ?? true)
                  ? 'Enter your full name'
                  : null,
            ),
            const SizedBox(height: AppSpacing.md),
            label('Email address'),
            AppInputField(
              controller: _emailController,
              label: 'Email address',
              hint: 'jane@example.com',
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
            const SizedBox(height: AppSpacing.md),
            label('Password'),
            AppInputField(
              controller: _passwordController,
              label: 'Password',
              hint: 'At least 8 characters',
              prefixIcon: Icons.lock_outline_rounded,
              isPassword: true,
              validator: (value) {
                if (value?.isEmpty ?? true) return 'Create a password';
                if (value!.length < 8) return 'Use at least 8 characters';
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.md),
            label('Confirm password'),
            AppInputField(
              controller: _confirmPasswordController,
              label: 'Confirm password',
              hint: 'Repeat your password',
              prefixIcon: Icons.lock_outline_rounded,
              isPassword: true,
              validator: (value) {
                if (value?.isEmpty ?? true) return 'Confirm your password';
                if (value != _passwordController.text) {
                  return 'Passwords do not match';
                }
                return null;
              },
            ),
            ErrorText(message: state.errorMessage),
            const SizedBox(height: AppSpacing.lg),
            AppPrimaryButton(
              label: 'Create account',
              icon: Icons.arrow_forward_rounded,
              loading: loading,
              onPressed: _submitSignup,
            ),
            const SizedBox(height: AppSpacing.md),
            AppSecondaryButton(
              label: 'Continue with Google',
              icon: Icons.g_mobiledata_rounded,
              onPressed: loading ? null : _onGoogleTap,
            ),
          ],
        ),
      ),
    );
  }
}
