import 'package:flutter/material.dart';

import '../../../../core/widgets/app_button.dart';

class SignInButton extends StatelessWidget {
  const SignInButton({
    super.key,
    required this.context,
    required this.isLoading,
    required this.onTap,
  });

  final BuildContext context;
  final bool isLoading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => AppPrimaryButton(
    label: 'Sign in',
    icon: Icons.arrow_forward_rounded,
    loading: isLoading,
    onPressed: onTap,
  );
}
