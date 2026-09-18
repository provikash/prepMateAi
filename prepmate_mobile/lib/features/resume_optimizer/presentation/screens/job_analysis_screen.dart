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

class JobAnalysisScreen extends ConsumerStatefulWidget {
  const JobAnalysisScreen({super.key});
  @override
  ConsumerState<JobAnalysisScreen> createState() => _State();
}

class _State extends ConsumerState<JobAnalysisScreen> {
  RequirementMatch? filter;
  @override
  Widget build(BuildContext context) {
    final analysis = ref.watch(optimizationProvider).analysis;
    if (analysis == null) {
      return AppScaffold(
        title: 'Job Analysis',
        body: AppErrorState(
          message: 'Run a job analysis before viewing results.',
          actionLabel: 'Start analysis',
          onAction: () => context.go('/resume/optimize'),
        ),
      );
    }
    final shown = filter == null
        ? analysis.requirements
        : analysis.requirements.where((r) => r.match == filter).toList();
    int count(RequirementMatch value) =>
        analysis.requirements.where((r) => r.match == value).length;
    return AppScaffold(
      title: 'Job Analysis',
      body: ResponsiveContent(
        child: Column(
          children: [
            const OptimizationStepHeader(step: 2),
            const SizedBox(height: AppSpacing.lg),
            Expanded(
              child: ListView(
                children: [
                  AppCard(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final metrics = Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Resume / Job Alignment',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Wrap(
                              spacing: AppSpacing.md,
                              runSpacing: AppSpacing.xs,
                              children: [
                                _Metric(
                                  '${count(RequirementMatch.matched)}',
                                  'matched',
                                ),
                                _Metric(
                                  '${count(RequirementMatch.partial)}',
                                  'partial',
                                ),
                                _Metric(
                                  '${count(RequirementMatch.missing)}',
                                  'missing',
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Text(
                              '+14% potential improvement',
                              style: Theme.of(context).textTheme.labelMedium
                                  ?.copyWith(
                                    color: AppColors.of(context).success,
                                  ),
                            ),
                          ],
                        );
                        return constraints.maxWidth > 540
                            ? Row(
                                children: [
                                  ScoreRing(
                                    score: analysis.beforeScore,
                                    label: 'Job Description\nAlignment',
                                  ),
                                  const SizedBox(width: AppSpacing.xl),
                                  Expanded(child: metrics),
                                ],
                              )
                            : Column(
                                children: [
                                  ScoreRing(
                                    score: analysis.beforeScore,
                                    label: 'Job Description\nAlignment',
                                  ),
                                  const SizedBox(height: AppSpacing.md),
                                  metrics,
                                ],
                              );
                      },
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    'Requirements',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        ChoiceChip(
                          label: const Text('All'),
                          selected: filter == null,
                          onSelected: (_) => setState(() => filter = null),
                        ),
                        const SizedBox(width: 8),
                        ...RequirementMatch.values.expand(
                          (v) => [
                            ChoiceChip(
                              label: Text('${_label(v)} (${count(v)})'),
                              selected: filter == v,
                              onSelected: (_) => setState(() => filter = v),
                            ),
                            const SizedBox(width: 8),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  ...shown.map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: _RequirementCard(item: item),
                    ),
                  ),
                  const InformationBanner(
                    icon: Icons.lightbulb_outline,
                    title: 'Recruiter insight',
                    message:
                        'Specific evidence is more persuasive than keyword repetition. Missing skills are never added without your confirmation.',
                  ),
                  const SizedBox(height: AppSpacing.xl),
                ],
              ),
            ),
            AppPrimaryButton(
              label: 'Review AI Suggestions',
              icon: Icons.arrow_forward,
              onPressed: () => context.push('/resume/optimize/suggestions'),
            ),
          ],
        ),
      ),
    );
  }

  String _label(RequirementMatch v) => switch (v) {
    RequirementMatch.matched => 'Matched',
    RequirementMatch.partial => 'Partial',
    RequirementMatch.missing => 'Missing',
  };
}

class _Metric extends StatelessWidget {
  const _Metric(this.value, this.label);
  final String value, label;
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(value, style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(width: 4),
      Text(
        label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: AppColors.of(context).textSecondary,
        ),
      ),
    ],
  );
}

class _RequirementCard extends StatelessWidget {
  const _RequirementCard({required this.item});
  final JobRequirement item;
  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final (label, icon, color) = switch (item.match) {
      RequirementMatch.matched => (
        'Strong match',
        Icons.check_circle,
        colors.success,
      ),
      RequirementMatch.partial => (
        'Partial match',
        Icons.error_outline,
        colors.warning,
      ),
      RequirementMatch.missing => (
        'Missing',
        Icons.cancel_outlined,
        colors.error,
      ),
    };
    return AppCard(
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        childrenPadding: const EdgeInsets.only(top: AppSpacing.sm),
        leading: Icon(icon, color: color),
        title: Text(item.name),
        subtitle: Text(
          '$label · ${item.importance}',
          style: TextStyle(color: color),
        ),
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.explanation),
                if (item.evidence != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  TextButton.icon(
                    onPressed: () => showModalBottomSheet<void>(
                      context: context,
                      builder: (_) => Padding(
                        padding: const EdgeInsets.all(AppSpacing.xl),
                        child: SafeArea(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Evidence',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              const SizedBox(height: AppSpacing.md),
                              Text(item.evidence!),
                              const SizedBox(height: AppSpacing.md),
                            ],
                          ),
                        ),
                      ),
                    ),
                    icon: const Icon(Icons.find_in_page_outlined),
                    label: const Text('View Evidence'),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
