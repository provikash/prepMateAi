import 'package:flutter/material.dart';

import '../../../../config/theme.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_scaffold.dart';

/// Lightweight placeholder retained for old deep links while monetization is
/// intentionally outside the lean MVP.
class AiPlansScreen extends StatelessWidget {
  const AiPlansScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return AppScaffold(
      title: 'AI plans',
      description: 'Purchases are not part of the current product scope.',
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: AppCard(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.hourglass_empty_rounded,
                  size: 42,
                  color: colors.primary,
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Payments are coming later',
                  style: Theme.of(context).textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'You can continue building, editing, and exporting resumes. '
                  'Paid subscriptions and credit packs will be enabled after '
                  'the core experience has been validated.',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: colors.textSecondary),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
