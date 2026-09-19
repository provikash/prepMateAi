import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../config/theme.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/app_state.dart';
import '../providers/optimization_provider.dart';
import '../widgets/optimization_widgets.dart';

class AtsAnalysisScreen extends ConsumerWidget {
  const AtsAnalysisScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final a = ref.watch(optimizationProvider).analysis;
    if (a == null) {
      return AppScaffold(
        title: 'ATS Analysis',
        body: const AppErrorState(
          message: 'Create an optimized version to view ATS results.',
        ),
      );
    }
    final delta = a.afterScore - a.beforeScore;
    return AppScaffold(
      title: 'ATS Analysis',
      body: ResponsiveContent(
        child: Column(
          children: [
            const OptimizationStepHeader(step: 4),
            const SizedBox(height: AppSpacing.md),
            Expanded(
              child: ListView(
                children: [
                  AppCard(
                    child: Column(
                      children: [
                        Text(
                          'Job Description Alignment',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Column(
                              children: [
                                Text(
                                  '${a.beforeScore}%',
                                  style: Theme.of(
                                    context,
                                  ).textTheme.headlineSmall,
                                ),
                                const Text('Before'),
                              ],
                            ),
                            const Icon(Icons.arrow_forward),
                            ScoreRing(score: a.afterScore, label: 'After'),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          '${delta > 0 ? '+' : ''}$delta points change',
                          style: Theme.of(context).textTheme.labelMedium
                              ?.copyWith(color: AppColors.of(context).success),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  if (a.beforeAtsScore != null && a.afterAtsScore != null) ...[
                    AppCard(child: Text(
                      'ATS analysis: ${a.beforeAtsScore}% before → ${a.afterAtsScore}% after. '
                      'This uses the existing resume analyzer on the saved JSON snapshot.',
                    )),
                    const SizedBox(height: AppSpacing.lg),
                  ],
                  const InformationBanner(
                    icon: Icons.shield_outlined,
                    title: 'JD alignment, not a hiring probability',
                    message:
                        'The primary scores come from requirement matching before and after approved changes. ATS analysis uses structured resume data, not a PDF parser.',
                  ),
                  const SizedBox(height: AppSpacing.xl),
                ],
              ),
            ),
            AppPrimaryButton(
              label: 'View Optimized Resume',
              icon: Icons.description_outlined,
              onPressed: () => context.push('/resume/optimize/preview'),
            ),
          ],
        ),
      ),
    );
  }
}
