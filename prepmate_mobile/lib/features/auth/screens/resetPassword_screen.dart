import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ResetPasswordScreen extends ConsumerStatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  ConsumerState<ResetPasswordScreen> createState() =>
      _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {

  final passwordController = TextEditingController();
  final confirmController = TextEditingController();

  bool obscurePassword = true;
  bool obscureConfirm = true;

  bool has8Char = false;
  bool hasSpecial = false;
  bool hasUppercase = false;

  void checkPassword(String password) {

    setState(() {
      has8Char = password.length >= 8;
      hasSpecial = RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password);
      hasUppercase = RegExp(r'[A-Z]').hasMatch(password);
    });
  }

  Widget requirement(bool valid, String text) {
    return Row(
      children: [
        Icon(
          valid ? Icons.check_circle : Icons.radio_button_unchecked,
          size: 18,
          color: valid ? Colors.blue : Colors.grey,
        ),
        const SizedBox(width: 8),
        Text(text),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: const Text("Reset Password"),
        centerTitle: true,
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [

            const SizedBox(height: 10),

            CircleAvatar(
              radius: 40,
              backgroundColor: Colors.blue.withOpacity(0.1),
              child: const Icon(
                Icons.lock_reset,
                size: 35,
                color: Colors.blue,
              ),
            ),

            const SizedBox(height: 20),

            const Text(
              "Set a New Password",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              "Your new password must be different from previous passwords.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),

            const SizedBox(height: 30),

            /// New Password
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "New Password",
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),

            const SizedBox(height: 8),

            TextField(
              controller: passwordController,
              obscureText: obscurePassword,
              onChanged: checkPassword,
              decoration: InputDecoration(
                hintText: "Enter new password",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                suffixIcon: IconButton(
                  icon: Icon(
                    obscurePassword
                        ? Icons.visibility_off
                        : Icons.visibility,
                  ),
                  onPressed: () {
                    setState(() {
                      obscurePassword = !obscurePassword;
                    });
                  },
                ),
              ),
            ),

            const SizedBox(height: 20),

            /// Confirm Password
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Confirm Password",
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),

            const SizedBox(height: 8),

            TextField(
              controller: confirmController,
              obscureText: obscureConfirm,
              decoration: InputDecoration(
                hintText: "Re-enter new password",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                suffixIcon: IconButton(
                  icon: Icon(
                    obscureConfirm
                        ? Icons.visibility_off
                        : Icons.visibility,
                  ),
                  onPressed: () {
                    setState(() {
                      obscureConfirm = !obscureConfirm;
                    });
                  },
                ),
              ),
            ),

            const SizedBox(height: 25),

            /// Password Requirements
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "PASSWORD REQUIREMENTS",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
            ),

            const SizedBox(height: 10),

            requirement(has8Char, "At least 8 characters"),
            const SizedBox(height: 6),

            requirement(hasSpecial,
                "Include a special character (e.g. !@#\$)"),
            const SizedBox(height: 6),

            requirement(hasUppercase, "One uppercase letter"),

            const SizedBox(height: 35),

            /// Update Button
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  "Update Password →",
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),

            const SizedBox(height: 15),

            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text("Cancel and return to login"),
            )
          ],
        ),
      ),
    );
  }
}