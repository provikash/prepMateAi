import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:prepmate_mobile/core/widgets/top_circle_button.dart';

import '../../../../config/theme.dart';
import '../../../../core/widgets/error_text.dart';
import '../../../../core/widgets/gradient_button.dart';
import '../../../../core/widgets/rounded_input_field.dart';
import '../../../../core/widgets/socialButton.dart';
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
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submitSignup() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    await ref
        .read(authViewModelProvider.notifier)
        .signup(
          name: _nameController.text.trim(),
          email: _emailController.text.trim(),
          password: _passwordController.text,
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
        context.go('/home');
      }
    });

    final authState = ref.watch(authViewModelProvider);
    final isLoading = authState.status == AuthStatus.loading;
    final colors = AppColors.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
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
                    const SizedBox(height: 18),
                    Center(
                      child: Container(
                          width: 148,
                          height: 148,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(30),
                            gradient:  LinearGradient(
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

                          
                      
                      
                          
                      
                      const SizedBox(height: 28),
                      Center(
                        child: Column(
                          children: [
                            Text(
                              'Create Your',
                              style: Theme.of(context).textTheme.headlineLarge
                                  ?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 32,
                                  ),
                            ),
                            Text(
                              'Account',
                              style: Theme.of(context).textTheme.headlineLarge
                                  ?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 32,
                                    color: colors.primary,
                                  ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Start building your professional future today',
                              style: Theme.of(
                                context,
                              ).textTheme.bodyMedium?.copyWith(fontSize: 15),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 26),
                      _fieldLabel(context, 'Full Name'),
                      const SizedBox(height: 10),
                      RoundedInputField(
                        hintText: 'Jane Doe',
                        prefixIcon: Icon(
                          Icons.person_outline,
                          color: colors.primary,
                        ),
                        controller: _nameController,
                        textCapitalization: TextCapitalization.words,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter your full name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      _fieldLabel(context, 'Email'),
                      const SizedBox(height: 10),
                      RoundedInputField(
                        hintText: 'jane@example.com',
                        prefixIcon: Icon(
                          Icons.email_outlined,
                          color: colors.primary,
                        ),
                        controller: _emailController,
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
                      ),
                      const SizedBox(height: 16),
                      _fieldLabel(context, 'Password'),
                      const SizedBox(height: 10),
                      RoundedInputField(
                        hintText: 'Create a password',
                        prefixIcon: Icon(
                          Icons.lock_outline,
                          color: colors.primary,
                        ),
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        suffix: IconButton(
                          onPressed: () => setState(
                            () => _obscurePassword = !_obscurePassword,
                          ),
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: colors.textSecondary,
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a password';
                          }
                          if (value.length < 6) {
                            return 'Password must be at least 6 characters';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      _fieldLabel(context, 'Confirm Password'),
                      const SizedBox(height: 10),
                      RoundedInputField(
                        hintText: 'Repeat password',
                        prefixIcon: Icon(
                          Icons.lock_outline,
                          color: colors.primary,
                        ),
                        controller: _confirmPasswordController,
                        obscureText: _obscureConfirmPassword,
                        suffix: IconButton(
                          onPressed: () => setState(
                            () => _obscureConfirmPassword =
                                !_obscureConfirmPassword,
                          ),
                          icon: Icon(
                            _obscureConfirmPassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: colors.textSecondary,
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please confirm your password';
                          }
                          if (value != _passwordController.text) {
                            return 'Passwords do not match';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 22),
                      GradientButton(
                        onPressed: isLoading ? null : _submitSignup,
                        text: 'Create Account',
                        trailing: const Icon(
                          Icons.arrow_forward,
                          color: Colors.white,
                        ),
                        borderRadius: 22,
                        height: 56,
                      ),
                      const SizedBox(height: 10),
                      ErrorText(message: authState.errorMessage),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          Expanded(child: Divider(color: colors.border)),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            child: Text(
                              'OR SIGN UP WITH',
                              style: TextStyle(
                                color: colors.textSecondary,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ),
                          Expanded(child: Divider(color: colors.border)),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          const SizedBox(width: 12),
                          Expanded(
                            child: SocialButton(
                              text: 'Google',
                              icon: Icons.g_mobiledata,
                              onTap: isLoading ? () {} : _onGoogleTap,
                            ),
                          ),
                        ],
                      ),
                      
                      
                      
                        ],
                      ),
                    )
                    ,
                    const SizedBox(height: 18),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Already have an account? ',
                          style: TextStyle(color: colors.textSecondary),
                        ),
                        TextButton(
                          onPressed: () => context.go('/login'),
                          child: Text(
                            'Log In',
                            style: TextStyle(
                              color: colors.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _fieldLabel(BuildContext context, String label) {
    final colors = AppColors.of(context);
    return Text(
      label,
      style: TextStyle(fontWeight: FontWeight.w600, color: colors.textPrimary),
    );
  }
}
