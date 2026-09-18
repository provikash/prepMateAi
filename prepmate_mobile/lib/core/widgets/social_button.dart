import 'package:flutter/material.dart';

import 'app_button.dart';

class SocialButton extends StatelessWidget {
  const SocialButton({
    super.key,
    required this.text,
    required this.icon,
    required this.onTap,
  });

  final String text;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) =>
      AppSecondaryButton(label: text, icon: icon, onPressed: onTap);
}
