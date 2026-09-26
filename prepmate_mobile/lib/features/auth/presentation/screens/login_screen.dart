import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/theme.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/error_text.dart';
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
  final _phoneController = TextEditingController();

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _continue() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final sent = await ref
        .read(authViewModelProvider.notifier)
        .requestOtp(_phoneController.text);
    if (sent && mounted) context.push('/verify-otp');
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(authViewModelProvider);
    return AuthShell(
      title: 'Continue with mobile',
      subtitle: 'Sign in or create your account with a one-time code.',
      showBack: false,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Indian mobile number',
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const SizedBox(height: AppSpacing.xs),
            TextFormField(
              key: const Key('mobileNumberField'),
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.telephoneNumberNational],
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(10),
              ],
              decoration: const InputDecoration(
                prefixText: '+91  ',
                hintText: '9876543210',
              ),
              validator: (value) {
                final digits = value ?? '';
                if (digits.length != 10) {
                  return 'Enter exactly 10 mobile digits';
                }
                if (!RegExp(r'^[6-9][0-9]{9}$').hasMatch(digits)) {
                  return 'Enter a valid Indian mobile number';
                }
                return null;
              },
              onFieldSubmitted: (_) => _continue(),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'By continuing, you consent to receive an authentication SMS. Message rates may apply.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            ErrorText(message: state.errorMessage),
            const SizedBox(height: AppSpacing.lg),
            AppPrimaryButton(
              label: 'Continue',
              icon: Icons.arrow_forward_rounded,
              loading: state.status == AuthStatus.loading,
              onPressed: _continue,
            ),
            const SizedBox(height: AppSpacing.md),
            OutlinedButton.icon(
              key: const Key('useTestAccountButton'),
              onPressed: () {
                _phoneController.text = '9999999999';
                _continue();
              },
              icon: const Icon(Icons.developer_mode, size: 16),
              label: const Text('Use Test Account (9999999999)'),
              style: OutlinedButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
