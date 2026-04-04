import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pinput/pinput.dart';
import 'package:prepmate_mobile/core/widgets/loading_button.dart';
import 'package:prepmate_mobile/core/widgets/neo_button.dart';
import 'package:prepmate_mobile/features/auth/providers/auth_provider.dart';
import 'package:go_router/go_router.dart';

class OtpVerificationScreen extends ConsumerStatefulWidget {
  final String email;

  const OtpVerificationScreen({super.key, required this.email});

  @override
  ConsumerState<OtpVerificationScreen> createState() =>
      _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends ConsumerState<OtpVerificationScreen> {
  final TextEditingController otpController = TextEditingController();

  int secondsRemaining = 59;
  Timer? timer;

  @override
  void initState() {
    super.initState();
    startTimer();
  }

  void startTimer() {
    timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (secondsRemaining == 0) {
        timer.cancel();
      } else {
        setState(() {
          secondsRemaining--;
        });
      }
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    otpController.dispose();
    super.dispose();
  }

  void verifyOtp() async {
    final otp = otpController.text.trim();

    if (otp.length != 6) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Enter valid OTP")));
      return;
    }

    try {
      final success = await ref
          .read(authNotifierProvider.notifier)
          .verifyOtp(otp, widget.email, "register");

      if (success) {
        if (!context.mounted) return;
           context.go('/login');




      } else {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text("Invalid OTP")));
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {

    final authState = ref.watch(authNotifierProvider);
    final defaultPinTheme = PinTheme(
      width: 50,
      height: 55,
      textStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300),
      ),
    );

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),

      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 25),
        child: Column(
          children: [
            const SizedBox(height: 20),

            /// Image
            CircleAvatar(
              radius: 70,
              backgroundColor: Colors.blue.withOpacity(0.1),
              child: Image.asset(
                "assets/otp.png", // replace with your image
                height: 80,
              ),
            ),

            const SizedBox(height: 30),

            const Text(
              "Verification Code",
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 10),

            const Text(
              "Please enter the 6-digit code sent to your email address.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),

            const SizedBox(height: 30),

            /// OTP Field
            Pinput(
              controller: otpController,
              length: 6,
              defaultPinTheme: defaultPinTheme,
            ),

            const SizedBox(height: 40),

            /// Verify Button
            // SizedBox(
            //   width: double.infinity,
            //   height: 55,
            //   child: ElevatedButton(
            //     onPressed: verifyOtp,
            //     style: ElevatedButton.styleFrom(
            //       backgroundColor: Colors.blue,
            //       shape: RoundedRectangleBorder(
            //         borderRadius: BorderRadius.circular(12),
            //       ),
            //     ),
            //     child: const Text("Verify", style: TextStyle(fontSize: 18)),
            //   ),
            // )
            NeuButton(isLoading: authState.status == AuthStatus.loading, onPressed: verifyOtp, text: "Verify", ),

            const SizedBox(height: 30),

            /// Resend Section
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text("Didn't receive code? "),
                secondsRemaining == 0
                    ? GestureDetector(
                        onTap: () {
                          setState(() {
                            secondsRemaining = 59;
                          });
                          startTimer();

                        },
                        child: const Text(
                          "Resend",
                          style: TextStyle(
                            color: Colors.blue,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      )
                    : Text(
                        "Resend 00:${secondsRemaining.toString().padLeft(2, '0')}",
                        style: const TextStyle(color: Colors.grey),
                      ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
