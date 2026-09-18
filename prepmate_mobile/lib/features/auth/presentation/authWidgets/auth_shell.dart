import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/theme.dart';
import '../../../../core/widgets/app_card.dart';

class AuthShell extends StatelessWidget {
  const AuthShell({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
    this.icon = Icons.description_outlined,
    this.footer,
    this.showBack = true,
  });

  final String title;
  final String subtitle;
  final Widget child;
  final IconData icon;
  final Widget? footer;
  final bool showBack;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.screen,
              AppSpacing.sm,
              AppSpacing.screen,
              AppSpacing.xl,
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight - 36,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          if (showBack)
                            IconButton(
                              tooltip: 'Back',
                              onPressed: () {
                                if (context.canPop()) context.pop();
                              },
                              icon: const Icon(Icons.arrow_back_rounded),
                            )
                          else
                            const SizedBox(width: AppSizes.tapTarget),
                          Expanded(
                            child: Text(
                              'PrepMate',
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                          ),
                          const SizedBox(width: AppSizes.tapTarget),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Center(
                        child: Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            color: colors.primarySoft,
                            borderRadius: BorderRadius.circular(AppRadius.xl),
                          ),
                          child: Icon(icon, size: 34, color: colors.primary),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Text(
                        title,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        subtitle,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: colors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      AppCard(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        child: child,
                      ),
                      if (footer != null) ...[
                        const SizedBox(height: AppSpacing.md),
                        footer!,
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
