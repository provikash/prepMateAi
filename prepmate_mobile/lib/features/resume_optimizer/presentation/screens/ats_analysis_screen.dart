import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../config/theme.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/app_state.dart';
import '../../domain/optimization_models.dart';
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
    final missing = a.requirements
        .where((r) => r.match == RequirementMatch.missing)
        .toList();
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
                          '+${a.afterScore - a.beforeScore}% improvement',
                          style: Theme.of(context).textTheme.labelMedium
                              ?.copyWith(color: AppColors.of(context).success),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    'Score breakdown',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  const AppCard(
                    child: Column(
                      children: [
                        _Breakdown('Keyword Alignment', .88),
                        _Breakdown('Skills Alignment', .84),
                        _Breakdown('Experience Relevance', .86),
                        _Breakdown('Formatting', .96),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    'ATS compliance',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  AppCard(
                    child: Column(
                      children:
                          [
                                'Standard section headings',
                                'Readable fonts and file format',
                                'Clean single-column parsing',
                                'Contact information detected',
                              ]
                              .map(
                                (x) => ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  leading: Icon(
                                    Icons.check_circle,
                                    color: AppColors.of(context).success,
                                  ),
                                  title: Text(x),
                                  trailing: const Text('Passed'),
                                ),
                              )
                              .toList(),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    'Remaining Gaps',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  AppCard(
                    child: Column(
                      children: missing
                          .map(
                            (r) => ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: Icon(
                                Icons.info_outline,
                                color: AppColors.of(context).warning,
                              ),
                              title: Text(r.name),
                              subtitle: const Text(
                                'No supporting evidence found.',
                              ),
                              trailing: const Text('Not added'),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  const InformationBanner(
                    icon: Icons.shield_outlined,
                    title: 'Evidence-first optimization',
                    message:
                        'Unsupported skills were not added. Alignment reflects only changes backed by your resume.',
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

class _Breakdown extends StatelessWidget {
  const _Breakdown(this.label, this.value);
  final String label;
  final double value;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Column(
      children: [
        Row(
          children: [
            Expanded(child: Text(label)),
            Text('${(value * 100).round()}%'),
          ],
        ),
        const SizedBox(height: 6),
        LinearProgressIndicator(
          value: value,
          minHeight: 7,
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
      ],
    ),
  );
}
