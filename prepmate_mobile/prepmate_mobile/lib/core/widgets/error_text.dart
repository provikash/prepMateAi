import 'package:flutter/material.dart';

class ErrorText extends StatelessWidget {
  final String? message;

  const ErrorText({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    if (message == null) return const SizedBox();

    return Column(
      children: [
        const SizedBox(height: 16),
        Text(
          message!,
          style: const TextStyle(
            color: Colors.red,
            fontSize: 14,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}