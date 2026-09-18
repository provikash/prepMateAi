import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/theme.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/error_text.dart';
import '../authWidgets/auth_field.dart';
import '../authWidgets/auth_shell.dart';
import '../state/auth_state.dart';
import '../viewmodel/auth_viewmodel.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  Future<void> _onSignInPressed() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    await ref
        .read(authViewModelProvider.notifier)
        .login(_emailController.text.trim(), _passwordController.text);
  }

  Future<void> _onGoogleTap() async {
    await ref.read(authViewModelProvider.notifier).signInWithGoogle();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(authProvider, (previous, next) {
      if (next.status == AuthStatus.authenticated) {
        if (next.infoMessage?.isNotEmpty ?? false) {
          Fluttertoast.showToast(msg: next.infoMessage!);
          ref.read(authProvider.notifier).clearMessages();
        }
        final intended = GoRouterState.of(context).uri.queryParameters['from'];
        context.go(intended ?? '/home');
      } else if (next.status == AuthStatus.error &&
          next.errorMessage != null &&
          next.errorMessage != previous?.errorMessage) {
        Fluttertoast.showToast(msg: next.errorMessage!);
      }
    });
    final state = ref.watch(authProvider);
    final loading = state.status == AuthStatus.loading;
    final colors = AppColors.of(context);

    return AuthShell(
      title: 'Welcome back',
      subtitle: 'Sign in to continue building your professional future.',
      showBack: false,
      footer: Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(
            "Don't have an account?",
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: colors.textSecondary),
          ),
          TextButton(
            onPressed: () => context.push('/signup'),
            child: const Text('Create account'),
          ),
        ],
      ),
      child: AutofillGroup(
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
              AuthField(
                controller: _emailController,
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
                isPassword: false,
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Password',
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                  ),
                  TextButton(
                    onPressed: () => context.push('/forgot-password'),
                    child: const Text('Forgot password?'),
                  ),
                ],
              ),
              AuthField(
                controller: _passwordController,
                hint: 'Enter your password',
                prefixIcon: Icons.lock_outline_rounded,
                isPassword: true,
                validator: (value) =>
                    (value?.isEmpty ?? true) ? 'Enter your password' : null,
              ),
              ErrorText(message: state.errorMessage),
              const SizedBox(height: AppSpacing.lg),
              AppPrimaryButton(
                label: 'Sign in',
                icon: Icons.arrow_forward_rounded,
                loading: loading,
                onPressed: _onSignInPressed,
              ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                children: [
                  const Expanded(child: Divider()),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                    ),
                    child: Text(
                      'OR',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                  ),
                  const Expanded(child: Divider()),
                ],
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
      ),
    );
  }
}
