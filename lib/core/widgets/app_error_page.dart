import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../config/theme.dart';

class AppErrorPage extends StatelessWidget {
  const AppErrorPage({
    super.key,
    this.title = 'Page not found',
    this.message =
        'The page may have moved or the link is no longer available.',
  });

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Semantics(
              container: true,
              header: true,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.explore_off_outlined, size: 64),
                  const SizedBox(height: AppSpacing.lg),
                  Text(title, style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: AppSpacing.sm),
                  Text(message, textAlign: TextAlign.center),
                  const SizedBox(height: AppSpacing.xl),
                  FilledButton.icon(
                    onPressed: () => context.go('/dashboard'),
                    icon: const Icon(Icons.dashboard_outlined),
                    label: const Text('Go to dashboard'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
