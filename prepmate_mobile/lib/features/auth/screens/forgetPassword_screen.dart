import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:prepmate_mobile/features/auth/providers/auth_provider.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {

  final emailController = TextEditingController();
  final formKey = GlobalKey<FormState>();

  Future<void> sendOtp() async {

    if (!formKey.currentState!.validate()) return;

    final email = emailController.text.trim();

    await ref.read(authNotifierProvider.notifier).forgotPassword(email);

    final state = ref.read(authNotifierProvider);

    if (state.status != AuthStatus.error) {

      if (!context.mounted) return;

      context.push("/verify-otp?flow=reset&email=$email", extra: email);
    }
  }

  @override
  Widget build(BuildContext context) {

    final authState = ref.watch(authNotifierProvider);
    final isLoading = authState.status == AuthStatus.loading;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Forgot Password"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),

      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: formKey,
          child: Column(
            children: [

              const SizedBox(height: 40),

              const Icon(
                Icons.lock_reset,
                size: 120,
                color: Colors.blue,
              ),

              const SizedBox(height: 30),

              const Text(
                "Forgot Password?",
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 10),

              const Text(
                "Enter your email address to receive a 6-digit OTP.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),

              const SizedBox(height: 40),

              TextFormField(
                controller: emailController,
                decoration: const InputDecoration(
                  labelText: "Email Address",
                  prefixIcon: Icon(Icons.email),
                ),
                validator: (value) {

                  if (value == null || value.isEmpty) {
                    return "Enter email";
                  }

                  if (!RegExp(
                      r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                      .hasMatch(value)) {
                    return "Invalid email";
                  }

                  return null;
                },
              ),

              const SizedBox(height: 30),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(

                  onPressed: isLoading ? null : sendOtp,

                  child: isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text("Send OTP"),

                ),
              ),

              const SizedBox(height: 20),

              TextButton(
                onPressed: () => context.go("/login"),
                child: const Text("Back to Login"),
              ),

              if (authState.errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Text(
                    authState.errorMessage!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}