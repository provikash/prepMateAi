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

class OptimizationSummaryScreen extends ConsumerWidget {
  const OptimizationSummaryScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(optimizationProvider);
    final a = state.analysis;
    if (a == null) {
      return AppScaffold(
        title: 'Optimization Summary',
        body: const AppErrorState(
          message: 'No optimization session was found.',
        ),
      );
    }
    int count(SuggestionStatus s) =>
        a.suggestions.where((x) => x.status == s).length;
    final groups = <String, List<OptimizationSuggestion>>{};
    for (final s in a.suggestions) {
      (groups[s.section] ??= []).add(s);
    }
    return AppScaffold(
      title: 'Optimization Summary',
      body: ResponsiveContent(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                children: [
                  const OptimizationStepHeader(step: 3),
                  const SizedBox(height: AppSpacing.lg),
                  Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.task_alt,
                          color: AppColors.of(context).success,
                          size: 52,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Optimization Complete',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  AppCard(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _Count(count(SuggestionStatus.accepted), 'Applied'),
                        _Count(count(SuggestionStatus.edited), 'Edited'),
                        _Count(count(SuggestionStatus.rejected), 'Rejected'),
                        _Count(count(SuggestionStatus.pending), 'Skipped'),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppCard(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '${a.beforeScore}%',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 18),
                          child: Icon(Icons.arrow_forward),
                        ),
                        Text(
                          '${a.afterScore}%',
                          style: Theme.of(context).textTheme.headlineMedium
                              ?.copyWith(color: AppColors.of(context).success),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  const InformationBanner(
                    icon: Icons.copy_all_outlined,
                    title: 'Your original resume has not been modified',
                    message:
                        'A separate job-specific version will be created from the changes you approved.',
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    'Changes',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  ...groups.entries.map(
                    (entry) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: AppCard(
                        child: ExpansionTile(
                          tilePadding: EdgeInsets.zero,
                          title: Text(entry.key),
                          subtitle: Text(
                            '${entry.value.length} change${entry.value.length == 1 ? '' : 's'}',
                          ),
                          children: entry.value
                              .map(
                                (s) => ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  title: Text(
                                    s.proposed,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  trailing: StatusPill(status: s.status),
                                ),
                              )
                              .toList(),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    'Version name',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    initialValue: state.versionName,
                    onChanged: ref
                        .read(optimizationProvider.notifier)
                        .setVersionName,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.drive_file_rename_outline),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                ],
              ),
            ),
            AppPrimaryButton(
              label: 'Create Optimized Resume',
              icon: Icons.add_circle_outline,
              loading: state.busy,
              onPressed: () async {
                final ok = await ref
                    .read(optimizationProvider.notifier)
                    .createVersion();
                if (ok && context.mounted) {
                  context.push('/resume/optimize/ats');
                } else if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        ref.read(optimizationProvider).error ??
                            'Save failed. Try again.',
                      ),
                    ),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _Count extends StatelessWidget {
  const _Count(this.value, this.label);
  final int value;
  final String label;
  @override
  Widget build(BuildContext context) => Column(
    children: [
      Text('$value', style: Theme.of(context).textTheme.titleLarge),
      Text(
        label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: AppColors.of(context).textSecondary,
        ),
      ),
    ],
  );
}
