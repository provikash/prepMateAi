import 'package:flutter/material.dart';

import 'app_button.dart';

/// Backward-compatible adapter for screens awaiting component migration.
class NeuButton extends StatelessWidget {
  const NeuButton({
    super.key,
    required this.isLoading,
    required this.onPressed,
    required this.text,
    this.icon,
  });

  final bool isLoading;
  final VoidCallback? onPressed;
  final String text;
  final IconData? icon;

  @override
  Widget build(BuildContext context) => AppPrimaryButton(
    label: text,
    icon: icon,
    loading: isLoading,
    onPressed: onPressed,
  );
}
