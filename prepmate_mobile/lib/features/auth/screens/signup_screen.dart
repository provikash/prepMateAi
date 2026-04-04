import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:prepmate_mobile/core/widgets/app_input_field.dart';
import 'package:prepmate_mobile/core/widgets/neo_button.dart';
import 'package:prepmate_mobile/core/widgets/neu_text_field.dart';
import 'package:prepmate_mobile/core/widgets/socialButton.dart';
import 'package:prepmate_mobile/features/auth/providers/auth_provider.dart';
import 'package:prepmate_mobile/core/widgets/loading_button.dart';
import 'package:prepmate_mobile/core/widgets/error_text.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _formkey = GlobalKey<FormState>();

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

  Future<void> _signup() async {
    if (!_formkey.currentState!.validate()) return;

    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    await ref
        .read(authNotifierProvider.notifier)
        .signup(name: name, email: email, password: password);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(authNotifierProvider, (previous, next) {
      if (next.status == AuthStatus.success && next.email != null) {
        context.push('/verify-otp?flow=register', extra: next.email);
      }
    });

    final authState = ref.watch(authNotifierProvider);
    final isLoading = authState.status == AuthStatus.loading;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back),
        ),
        title: const Text('PrapMate'),
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16),
          child: Form(
            key: _formkey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 24),
                Center(
                  child: Text(
                    'Create Your \n Account',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      height: 1.2,
                    ),
                  ),
                ),
                const SizedBox(height: 8.0),
                Center(
                  child: const Text(
                    'Start building your professional future today',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ),
                const SizedBox(height: 40.0),

                //Full_Name
                // TextFormField(
                //   controller: _nameController,
                //   decoration: const InputDecoration(
                //     labelText: 'Full Name',
                //     hintText: 'Tony Stark',
                //   ),
                //   textCapitalization: TextCapitalization.words,
                //   validator:(value){
                //     if(value == null || value.trim().isEmpty){
                //       return 'Please enter your full name';
                //     }
                //     return null;
                //   },
                // ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    "Full Name",
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                ),
                SizedBox(height: 8.0),

                NeuTextField(
                  controller: _nameController,
                  prefixIcon: Icons.person,
                  hint: 'Full Name',
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your full name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24.0),
                //Email
                // TextFormField(
                //   controller: _emailController,
                //   decoration: const InputDecoration(
                //     labelText: 'Email',
                //     hintText: 'tony@exampe.com',
                //   ),
                //
                //   keyboardType: TextInputType.emailAddress,
                //   validator:(value){
                //     if (value == null || value.isEmpty){
                //       return 'Please enter your email';
                //
                //     }
                //     if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)){
                //       return 'Please enter a valid email ';
                //     }
                //     return null;
                //   }
                // ),
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
                  hint: 'tony@example.com',
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
                const SizedBox(height: 24.0),

                //Password
                // TextFormField(
                //   controller: _passwordController,
                //   obscureText: _obscurePassword,
                //   decoration: InputDecoration(
                //     labelText: 'Password',
                //     hintText: 'Create a Password',
                //     suffixIcon: IconButton(
                //       icon: Icon(
                //         _obscurePassword
                //             ? Icons.visibility_off
                //             : Icons.visibility,
                //       ),
                //
                //       onPressed: () =>
                //           setState(() => _obscurePassword = !_obscurePassword),
                //     ),
                //   ),
                //
                //   validator:(value){
                //     if (value == null || value.isEmpty)
                //       return 'Please enter a password';
                //     if (value.length < 6) return 'Password must be at least 6 Characters';
                //     return null;
                //   },
                // ),
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
                  isPassword: true,
                  hint: 'Create a Text',
                  validator: (value) {
                    if (value == null || value.isEmpty)
                      return 'Please enter a password';
                    if (value.length < 6)
                      return 'Password must be at least 6 Characters';
                    return null;
                  },
                ),
                const SizedBox(height: 24.0),

                //confirm password
                // TextFormField(
                //   controller: _confirmPasswordController,
                //   obscureText: _obscureConfirmPassword,
                //   decoration: InputDecoration(
                //     labelText: 'Confirm Password',
                //     hintText: 'Repeat Password',
                //     suffixIcon: IconButton(
                //       onPressed: () => setState(() {
                //         _obscureConfirmPassword = !_obscureConfirmPassword;
                //       }),
                //       icon: Icon(
                //         _obscureConfirmPassword
                //             ? Icons.visibility
                //             : Icons.visibility_off,
                //       ),
                //     ),
                //   ),
                //   validator:(value){
                //     if(value == null || value.isEmpty) return 'Please Enter Confirm Password';
                //     if(value != _passwordController.text) return 'Passwords do not match';
                //   }
                // ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    "Confirm Password",
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                ),
                SizedBox(height: 8.0),

                NeuTextField(
                  controller: _confirmPasswordController,
                  prefixIcon: Icons.password,
                  hint: 'Repeat Password',
                  isPassword: true,
                  validator: (value) {
                    if (value == null || value.isEmpty)
                      return 'Please Enter Confirm Password';
                    if (value != _passwordController.text)
                      return 'Passwords do not match';
                  },
                ),
                const SizedBox(height: 32.0),

                //create Account Button
                // ElevatedButton.icon(
                //   onPressed: isLoading ? null : _signup,
                //
                //   icon: isLoading
                //       ? const SizedBox.shrink()
                //       : const Icon(Icons.arrow_forward, size: 20),
                //   label: isLoading
                //       ? const SizedBox(
                //           height: 20,
                //           width: 20,
                //           child: CircularProgressIndicator(strokeWidth: 2.5),
                //         )
                //       : const Text(
                //           'Create Account ',
                //           style: TextStyle(fontSize: 16),
                //         ),
                //   style: ElevatedButton.styleFrom(
                //     padding: const EdgeInsets.symmetric(vertical: 16),
                //     shape: RoundedRectangleBorder(
                //       borderRadius: BorderRadius.circular(12),
                //     ),
                //
                //   ),
                // ),
                const SizedBox(height: 32),

                NeuButton(
                  isLoading: isLoading,
                  onPressed: _signup,
                  text: 'Create Account',
                  icon: Icons.arrow_forward,
                ),
                SizedBox(child: ErrorText(message: authState.errorMessage)),

                const SizedBox(height: 32),

                // OR section
                const Center(child: Text('OR SIGN UP WITH')),
                const SizedBox(height: 16),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // OutlinedButton.icon(
                    //   icon: const Icon(Icons.business, color: Colors.blue),
                    //   label: const Text('LinkedIn'),
                    //   onPressed: () {
                    //     // TODO: LinkedIn OAuth
                    //   },
                    //   style: OutlinedButton.styleFrom(
                    //     padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    //   ),
                    // ),
                    SocialButton(
                      text: 'LinkedIn',
                      icon: Icons.business,
                      onTap: () {},
                    ),
                    const SizedBox(width: 16),
                    // OutlinedButton.icon(
                    //   icon: const Text('G', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    //   label: const Text('Google'),
                    //   onPressed: () {
                    //     ref.read(authNotifierProvider.notifier).signInWithGoogle();
                    //   },
                    //   style: OutlinedButton.styleFrom(
                    //     padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                    //   ),
                    // ),
                    SocialButton(
                      text: 'Google',
                      icon: Icons.g_mobiledata,
                      onTap: () {
                        ref
                            .read(authNotifierProvider.notifier)
                            .signInWithGoogle();
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 32),

                // Already have account
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Already have an account? "),
                    TextButton(
                      onPressed: () => context.go('/login'),
                      child: const Text('Log In'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
