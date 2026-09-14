import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:go_router/go_router.dart';
import 'package:prepmate_mobile/config/theme.dart';
import 'package:prepmate_mobile/core/widgets/error_text.dart';
import 'package:prepmate_mobile/core/widgets/top_circle_button.dart';
import 'package:prepmate_mobile/features/auth/presentation/authWidgets/sign_in_button.dart';

import 'package:prepmate_mobile/features/auth/presentation/state/auth_state.dart';
import 'package:prepmate_mobile/core/widgets/socialButton.dart';
import 'package:prepmate_mobile/features/auth/presentation/viewmodel/auth_viewmodel.dart';

import '../authWidgets/auth_field.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();

  final _passwordController = TextEditingController();

  Future<void> _onSignInPressed() async {
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
        if (next.infoMessage != null && next.infoMessage!.isNotEmpty) {
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
    final authState = ref.watch(authProvider);
    final colors = AppColors.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isLoading = authState.status == AuthStatus.loading;

    return Scaffold(
      backgroundColor: colors.screenBackground,
      body: Stack(
        children: [
          Positioned(
            top: -80,
            right: -80,
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colors.primarySoft.withValues(
                  alpha: isDark ? 0.25 : 0.9,
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -110,
            left: -70,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colors.primarySoft.withValues(
                  alpha: isDark ? 0.16 : 0.7,
                ),
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
              child: Column(
                children: [
                  Row(
                    children: [
                      topCircleButton(
                        context: context,
                        icon: Icons.arrow_back_ios_new,
                        onTap: () {
                          if (context.canPop()) {
                            context.pop();
                          }
                        },
                      ),
                      const Spacer(),
                      Center(
                        child: RichText(
                          text: TextSpan(
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w700,
                              fontSize: 24,
                              color: colors.textPrimary,
                            ),
                            children: [
                              TextSpan(text: 'Prep'),
                              TextSpan(
                                text: 'Mate',
                                style: TextStyle(color: colors.primary),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const Spacer(flex: 2),
                    ],
                  ),
                  const SizedBox(height: 26),
                  Container(
                    width: 148,
                    height: 148,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(30),
                      gradient: LinearGradient(
                        colors: [
                          colors.primary,
                          colors.primary.withValues(alpha: 0.82),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: colors.primary.withValues(alpha: 0.25),
                          blurRadius: 24,
                          offset: const Offset(0, 14),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.description_outlined,
                      size: 64,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 22),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(18, 24, 18, 18),
                    decoration: BoxDecoration(
                      color: colors.cardBackground,
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(
                            alpha: isDark ? 0.28 : 0.08,
                          ),
                          blurRadius: 30,
                          offset: const Offset(0, 16),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Text(
                            'Welcome Back',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w800,
                              fontSize: 28,
                              color: colors.textPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Center(
                          child: Text(
                            'Sign in to continue building your future.',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 15,
                              color: colors.textSecondary,
                            ),
                          ),
                        ),
                        const SizedBox(height: 26),
                        Text(
                          'Email Address',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                            color: colors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 10),
                        AuthField(
                          controller: _emailController,
                          hint: 'name@company.com',
                          prefixIcon: Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress,

                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter your email';
                            }
                            final email = value.trim();
                            if (!RegExp(
                              r'^[\w\-.]+@([\w-]+\.)+[\w-]{2,}$',
                            ).hasMatch(email)) {
                              return 'Please enter a valid email';
                            }
                            return null;
                          },
                          isPassword: false,
                        ),
                        const SizedBox(height: 18),
                        Row(
                          children: [
                            Text(
                              'Password',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                                color: colors.textPrimary,
                              ),
                            ),
                            const Spacer(),
                            TextButton(
                              onPressed: () => context.push('/forgot-password'),
                              child: Text(
                                'Forgot Password?',
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontWeight: FontWeight.w600,
                                  color: colors.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        AuthField(
                          controller: _passwordController,
                          hint: 'Enter your password',
                          prefixIcon: Icons.lock_outline,
                          isPassword: true,
                          validator: (String? value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your password';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 18),
                        SignInButton(
                          context: context,
                          isLoading: authState.status == AuthStatus.loading,
                          onTap: _onSignInPressed,
                        ),
                        const SizedBox(height: 12),
                        ErrorText(message: authState.errorMessage),
                        const SizedBox(height: 22),
                        Row(
                          children: [
                            Expanded(child: Divider(color: colors.border)),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                              ),
                              child: Text(
                                'OR CONTINUE WITH',
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  color: colors.textSecondary,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ),
                            Expanded(child: Divider(color: colors.border)),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: SocialButton(
                                text: 'Google',
                                icon: Icons.g_mobiledata,
                                onTap: isLoading ? () {} : _onGoogleTap,
                              ),
                            ),
                            const SizedBox(width: 12),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Don't have an account? ",
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          color: colors.textSecondary,
                        ),
                      ),
                      TextButton(
                        onPressed: () => context.push('/signup'),
                        child: Text(
                          'Sign Up',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w700,
                            color: colors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
