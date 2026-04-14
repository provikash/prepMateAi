import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:prepmate_mobile/core/widgets/error_text.dart';

import 'package:prepmate_mobile/core/widgets/neo_button.dart';
import 'package:prepmate_mobile/core/widgets/neu_text_field.dart';
import 'package:prepmate_mobile/core/widgets/socialButton.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    ref.listen(authNotifierProvider, (previous, next) {
      if (next.status == AuthStatus.authenticated) {
        context.go("/home");
      }
    });
    final authState = ref.watch(authNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'PrepMate',
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.description, size: 80, color: Colors.blue),
              const SizedBox(height: 24),
              Center(
                child: const Text(
                  'Welcome Back',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),
              ),

              Center(
                child: const Text('Sign in to continue building your future.'),
              ),
              const SizedBox(height: 40),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  "Email",
                  style: Theme.of(context).textTheme.labelLarge,
                ),
              ),
              SizedBox(height: 8.0),

              NeuTextField(
                controller: _emailController,
                prefixIcon: Icons.email,
                hint: 'Email Address',
                keyboardType: TextInputType.emailAddress,

                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your email';
                  }
                  if (!RegExp(
                    r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                  ).hasMatch(value)) {
                    return 'Please enter a valid email ';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  "Password",
                  style: Theme.of(context).textTheme.labelLarge,
                ),
              ),
              SizedBox(height: 8.0),

              NeuTextField(
                controller: _passwordController,
                prefixIcon: Icons.password,
                hint: 'Password',
                isPassword: true,

                validator: (value) {
                  if (value == null || value.isEmpty)
                    return 'Please enter a password';
                  if (value.length < 6)
                    return 'Password must be at least 6 Characters';
                  return null;
                },
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => context.push('/forgot-password'),
                  child: Text(
                    'Forgot Password?',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              NeuButton(
                isLoading: authState.status == AuthStatus.loading,
                onPressed: () async {
                  await ref
                      .read(authNotifierProvider.notifier)
                      .login(
                        _emailController.text.trim(),
                        _passwordController.text,
                      );

                  if (!mounted) return;

                  final state = ref.read(authNotifierProvider);

                  if (state.status == AuthStatus.authenticated) {
                    context.go('/home');
                  } else if (state.status == AuthStatus.error) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(state.errorMessage ?? "Login failed"),
                      ),
                    );
                  }
                },
                text: 'Sign In',
                icon: Icons.login,
              ),
              SizedBox(child: ErrorText(message: authState.errorMessage)),

              const SizedBox(height: 32),
              const Center(child: Text('OR CONTINUE WITH')),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(width: 16),
                  SocialButton(
                    text: 'Linkedin',
                    icon: Icons.cases,
                    onTap: () {},
                  ),

                  // OutlinedButton.icon(
                  //   icon: const Icon(Icons.business),
                  //   label: const Text('LinkedIn'),
                  //   onPressed: () {},
                  // ),
                  SocialButton(
                    text: 'Google',
                    icon: Icons.g_mobiledata,
                    onTap: () {},
                  ),
                ],
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Don't have an account? "),
                  TextButton(
                    onPressed: () => context.push('/signup'),

                    child: const Text('Sign Up'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
