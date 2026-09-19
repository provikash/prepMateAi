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
    final optState = ref.watch(optimizationProvider);
    final analysis = optState.analysis;

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

    final overview = analysis.overview;
    final displayTitle = overview?.jobTitle.isNotEmpty == true
        ? overview!.jobTitle
        : (optState.jobTitle.isNotEmpty ? optState.jobTitle : 'Job title not specified');
    final displayCompany = overview?.company.isNotEmpty == true
        ? overview!.company
        : optState.company;
    final displaySeniority = overview?.seniority ?? '';

    return AppScaffold(
      title: 'Job Match Analysis',
      body: ResponsiveContent(
        child: Column(
          children: [
            const OptimizationStepHeader(step: 2),
            const SizedBox(height: AppSpacing.lg),
            Expanded(
              child: ListView(
                children: [
                  // Target Role Banner
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    displayTitle,
                                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '$displayCompany · $displaySeniority',
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: AppColors.of(context).textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.sm,
                                vertical: AppSpacing.xs,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.of(context).primarySoft,
                                borderRadius: BorderRadius.circular(AppRadius.pill),
                              ),
                              child: Text(
                                displaySeniority,
                                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                  color: AppColors.of(context).primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Alignment Score & Match Breakdown
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
                                  'matched (✓)',
                                  AppColors.of(context).success,
                                ),
                                _Metric(
                                  '${count(RequirementMatch.partial)}',
                                  'partial (◐)',
                                  AppColors.of(context).warning,
                                ),
                                _Metric(
                                  '${count(RequirementMatch.missing)}',
                                  'missing (!)',
                                  AppColors.of(context).error,
                                ),
                                _Metric(
                                  '${count(RequirementMatch.unclear)}',
                                  'unclear (?)',
                                  AppColors.of(context).primary,
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Text(
                              '${analysis.requirements.length} structured requirements identified',
                              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                color: AppColors.of(context).textSecondary,
                              ),
                            ),
                          ],
                        );
                        return constraints.maxWidth > 540
                            ? Row(
                                children: [
                                  ScoreRing(
                                    score: analysis.beforeScore,
                                    label: 'JD Evidence\nAlignment',
                                  ),
                                  const SizedBox(width: AppSpacing.xl),
                                  Expanded(child: metrics),
                                ],
                              )
                            : Column(
                                children: [
                                  ScoreRing(
                                    score: analysis.beforeScore,
                                    label: 'JD Evidence\nAlignment',
                                  ),
                                  const SizedBox(height: AppSpacing.md),
                                  metrics,
                                ],
                              );
                      },
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // Filter Chips for 4 States
                  Text(
                    'Extracted Requirements',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        ChoiceChip(
                          label: Text('All (${analysis.requirements.length})'),
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

                  // Requirements List Cards
                  if (shown.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
                      child: Center(
                        child: Text(
                          'No requirements in this category.',
                          style: TextStyle(color: AppColors.of(context).textSecondary),
                        ),
                      ),
                    )
                  else
                    ...shown.map(
                      (item) => Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: _RequirementCard(item: item),
                      ),
                    ),

                  const SizedBox(height: AppSpacing.md),
                  const InformationBanner(
                    icon: Icons.lightbulb_outline,
                    title: 'Auditable Evidence Matching',
                    message:
                      'Requirements are matched directly against structured evidence in your master resume. Missing requirements are clearly flagged and will never be fabricated.',
                  ),
                  const SizedBox(height: AppSpacing.xl),
                ],
              ),
            ),
            AppPrimaryButton(
              label: 'View Optimization Workspace',
              icon: Icons.arrow_forward,
              onPressed: () => context.push('/resume/optimize/suggestions'),
            ),
          ],
        ),
      ),
    );
  }

  String _label(RequirementMatch v) => switch (v) {
    RequirementMatch.matched => 'Matched (✓)',
    RequirementMatch.partial => 'Partial (◐)',
    RequirementMatch.missing => 'Missing (!)',
    RequirementMatch.unclear => 'Unclear (?)',
  };
}

class _Metric extends StatelessWidget {
  const _Metric(this.value, this.label, this.color);

  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(
        value,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
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
        'Matched',
        Icons.check_circle,
        colors.success,
      ),
      RequirementMatch.partial => (
        'Partial Match',
        Icons.timelapse,
        colors.warning,
      ),
      RequirementMatch.missing => (
        'Missing',
        Icons.cancel_outlined,
        colors.error,
      ),
      RequirementMatch.unclear => (
        'Unclear / Ambiguous',
        Icons.help_outline,
        colors.primary,
      ),
    };

    return AppCard(
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        childrenPadding: const EdgeInsets.only(top: AppSpacing.sm),
        leading: Icon(icon, color: color),
        title: Text(
          item.name,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          '$label · ${item.importance} · ${item.category}',
          style: TextStyle(color: color, fontSize: 13),
        ),
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.explanation,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                if (item.evidence != null || item.evidencePath != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: colors.primarySoft,
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                      border: Border.all(color: colors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.link, size: 16, color: colors.primary),
                            const SizedBox(width: 4),
                            Text(
                              'Resume Evidence Grounding',
                              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: colors.primary,
                              ),
                            ),
                          ],
                        ),
                        if (item.evidenceContext != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            item.evidenceContext!,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                        if (item.evidence != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            '"${item.evidence}"',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                        if (item.evidencePath != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            'JSON Path: ${item.evidencePath}',
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: colors.textSecondary,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ],
                      ],
                    ),
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
