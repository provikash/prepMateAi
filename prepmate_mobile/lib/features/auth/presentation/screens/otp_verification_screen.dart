import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pinput/pinput.dart';

import '../../../../config/theme.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/error_text.dart';
import '../authWidgets/auth_shell.dart';
import '../state/auth_state.dart';
import '../viewmodel/auth_viewmodel.dart';

class OtpVerificationScreen extends ConsumerStatefulWidget {
  const OtpVerificationScreen({
    super.key,
    required this.email,
    this.flow = 'register',
  });

  final String email;
  final String flow;

  @override
  ConsumerState<OtpVerificationScreen> createState() =>
      _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends ConsumerState<OtpVerificationScreen> {
  final _otpController = TextEditingController();
  int _secondsRemaining = 59;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted || _secondsRemaining == 0) {
        timer.cancel();
      } else {
        setState(() => _secondsRemaining--);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _verifyOtp() async {
    final otp = _otpController.text.trim();
    if (otp.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter the complete six-digit code.')),
      );
      return;
    }
    if (widget.flow == 'reset') {
      context.pushReplacement(
        '/reset-password',
        extra: {'email': widget.email, 'otp': otp},
      );
      return;
    }
    await ref
        .read(authViewModelProvider.notifier)
        .verifyOtp(widget.email, otp, 'register');
    if (!mounted) return;
    if (ref.read(authViewModelProvider).status == AuthStatus.success) {
      context.go('/login');
    }
  }

  Future<void> _resend() async {
    final notifier = ref.read(authViewModelProvider.notifier);
    final sent = widget.flow == 'reset'
        ? await notifier.forgotPassword(widget.email)
        : await notifier.resendVerification(widget.email);
    if (!mounted || !sent) return;
    setState(() => _secondsRemaining = 59);
    _startTimer();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('A new verification code was sent.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(authViewModelProvider);
    final colors = AppColors.of(context);
    return AuthShell(
      title: 'Check your email',
      subtitle: 'Enter the six-digit code sent to ${widget.email}.',
      icon: Icons.mark_email_read_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final width = ((constraints.maxWidth - 40) / 6).clamp(38.0, 52.0);
              final pinTheme = PinTheme(
                width: width,
                height: AppSizes.buttonHeight,
                textStyle: Theme.of(context).textTheme.titleLarge,
                decoration: BoxDecoration(
                  color: colors.cardBackground,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(color: colors.border),
                ),
              );
              return Pinput(
                controller: _otpController,
                length: 6,
                defaultPinTheme: pinTheme,
                focusedPinTheme: pinTheme.copyWith(
                  decoration: pinTheme.decoration?.copyWith(
                    border: Border.all(color: colors.primary, width: 1.5),
                  ),
                ),
                errorPinTheme: pinTheme.copyWith(
                  decoration: pinTheme.decoration?.copyWith(
                    border: Border.all(color: colors.error),
                  ),
                ),
                onCompleted: (_) => _verifyOtp(),
              );
            },
          ),
          ErrorText(message: state.errorMessage),
          const SizedBox(height: AppSpacing.xl),
          AppPrimaryButton(
            label: 'Verify code',
            loading: state.status == AuthStatus.loading,
            onPressed: _verifyOtp,
          ),
          const SizedBox(height: AppSpacing.md),
          if (_secondsRemaining == 0)
            AppButton(
              label: 'Resend code',
              onPressed: _resend,
              variant: AppButtonVariant.text,
            )
          else
            Text(
              'You can request another code in 00:${_secondsRemaining.toString().padLeft(2, '0')}',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: colors.textSecondary),
            ),
        ],
      ),
    );
  }
}
