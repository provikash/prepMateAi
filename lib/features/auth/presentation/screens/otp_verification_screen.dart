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
  const OtpVerificationScreen({super.key});
  @override
  ConsumerState<OtpVerificationScreen> createState() =>
      _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends ConsumerState<OtpVerificationScreen> {
  final _controller = TextEditingController();
  Timer? _timer;
  int _remaining = 0;
  bool _verifying = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _restart());
  }

  void _restart() {
    _timer?.cancel();
    setState(
      () => _remaining = ref.read(authViewModelProvider).resendAfterSeconds,
    );
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted || _remaining <= 0) {
        timer.cancel();
        return;
      }
      setState(() => _remaining--);
    });
  }

  Future<void> _verify() async {
    if (_verifying || _controller.text.length != 6) return;
    _verifying = true;
    final ok = await ref
        .read(authViewModelProvider.notifier)
        .verifyOtp(_controller.text);
    _verifying = false;
    if (!mounted) return;
    if (ok) {
      final user = ref.read(authViewModelProvider).user;
      context.go(user?.profileCompleted == true ? '/home' : '/profile/edit');
    } else {
      _controller.clear();
    }
  }

  Future<void> _resend() async {
    if (_remaining > 0) return;
    if (await ref.read(authViewModelProvider.notifier).resendOtp() && mounted) {
      _restart();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(authViewModelProvider);
    final phone = state.phoneNumber ?? '';
    final isTestPhone = phone.contains('9999999999');
    final masked = phone.length >= 4
        ? '+91 ******${phone.substring(phone.length - 4)}'
        : '+91 **********';
    return AuthShell(
      title: 'Verify mobile number',
      subtitle: 'Enter the six-digit code sent to $masked.',
      icon: Icons.sms_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (isTestPhone) ...[
            Container(
              margin: const EdgeInsets.only(bottom: AppSpacing.md),
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.vpn_key_outlined, size: 16, color: Theme.of(context).colorScheme.primary),
                      const SizedBox(width: 8),
                      Text(
                        'Test code: 123456',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                      ),
                    ],
                  ),
                  TextButton(
                    key: const Key('autoFillTestOtpButton'),
                    onPressed: () {
                      _controller.text = '123456';
                      _verify();
                    },
                    style: TextButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                    child: const Text('Auto-Fill & Verify'),
                  ),
                ],
              ),
            ),
          ],
          Pinput(
            key: const Key('otpField'),
            controller: _controller,
            length: 6,
            keyboardType: TextInputType.number,
            onCompleted: (_) => _verify(),
          ),
          ErrorText(message: state.errorMessage),
          const SizedBox(height: AppSpacing.xl),
          AppPrimaryButton(
            label: 'Verify code',
            loading: state.status == AuthStatus.loading,
            onPressed: _verify,
          ),
          const SizedBox(height: AppSpacing.md),
          if (_remaining > 0)
            Text(
              'Request another code in 00:${_remaining.toString().padLeft(2, '0')}',
              textAlign: TextAlign.center,
            )
          else
            AppButton(
              label: 'Resend code',
              onPressed: _resend,
              variant: AppButtonVariant.text,
            ),
          TextButton(
            onPressed: () => context.pop(),
            child: const Text('Change mobile number'),
          ),
        ],
      ),
    );
  }
}
