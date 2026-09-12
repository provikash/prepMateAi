import 'package:flutter/material.dart';

class AIButton extends StatelessWidget {
  final VoidCallback onPressed;
  final String label;

  const AIButton({Key? key, required this.onPressed, required this.label}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      icon: const Icon(Icons.smart_toy_outlined),
      label: Text(label),
      style: ElevatedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
      onPressed: onPressed,
    );
  }
}
