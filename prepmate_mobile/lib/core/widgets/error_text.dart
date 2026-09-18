import 'package:flutter/material.dart';
import '../../config/theme.dart';

class ErrorText extends StatelessWidget {
  final String? message;

  const ErrorText({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    if (message == null) return const SizedBox();

    return Column(
      children: [
        const SizedBox(height: 16),
        Semantics(
          liveRegion: true,
          label: 'Error: $message',
          child: Text(
            message!,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.of(context).error),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }
}
