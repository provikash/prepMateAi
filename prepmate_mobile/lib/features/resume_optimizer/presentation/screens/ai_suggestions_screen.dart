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

class AiSuggestionsScreen extends ConsumerStatefulWidget {
  const AiSuggestionsScreen({super.key});

  @override
  ConsumerState<AiSuggestionsScreen> createState() => _AiSuggestionsState();
}

class _AiSuggestionsState extends ConsumerState<AiSuggestionsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.read(optimizationProvider.notifier).loadCredits();
    });
  }

  Future<void> _review(String id, SuggestionStatus status) async {
    final ok = await ref
        .read(optimizationProvider.notifier)
        .setSuggestionStatus(id, status);
    if (!mounted || ok) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ref.read(optimizationProvider).error ?? 'Review failed.'),
      ),
    );
  }

  Future<void> _regenerate(String id) async {
    var instructionValue = '';
    final instruction = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          'Improve with AI · ${ref.read(optimizationProvider).regenerationCost} credit(s)',
        ),
        content: TextFormField(
          onChanged: (value) => instructionValue = value,
          maxLength: 300,
          decoration: const InputDecoration(hintText: 'Make this more concise'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, instructionValue),
            child: const Text('Generate'),
          ),
        ],
      ),
    );
    if (instruction == null || instruction.trim().isEmpty || !mounted) return;
    final result = await ref
        .read(optimizationProvider.notifier)
        .regenerate(id, instruction);
    if (!mounted || result != null) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ref.read(optimizationProvider).error ?? 'Regeneration failed.',
        ),
      ),
    );
  }

  Future<void> _confirmMissingSkill(JobRequirement requirement) async {
    var skillValue = requirement.name;
    final value = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Add skill to optimized resume'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Only confirm this skill if you genuinely have it. It will be added to the optimized version, not your master resume.',
            ),
            const SizedBox(height: 12),
            TextFormField(
              initialValue: requirement.name,
              onChanged: (value) => skillValue = value,
              autofocus: true,
              maxLength: 100,
              decoration: const InputDecoration(labelText: 'Skill name'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, skillValue),
            child: const Text('Confirm & add'),
          ),
        ],
      ),
    );
    if (value == null || value.trim().isEmpty || !mounted) return;
    final ok = await ref
        .read(optimizationProvider.notifier)
        .confirmMissingSkill(requirement, value);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? 'Skill added to the optimized version.'
              : ref.read(optimizationProvider).error ?? 'Could not add skill.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(optimizationProvider);
    final credits = state.credits ?? 0;
    final analysis = state.analysis;

    if (analysis == null) {
      return AppScaffold(
        title: 'Optimization Workspace',
        body: AppErrorState(
          message:
              'Analysis results are unavailable. Please analyze a job description first.',
          onAction: () => context.go('/resume/optimize'),
        ),
      );
    }

    final matchedList = analysis.requirements
        .where((r) => r.match == RequirementMatch.matched)
        .toList();
    final partialList = analysis.requirements
        .where((r) => r.match == RequirementMatch.partial)
        .toList();
    final missingList = analysis.requirements
        .where((r) => r.match == RequirementMatch.missing)
        .toList();
    final unclearList = analysis.requirements
        .where((r) => r.match == RequirementMatch.unclear)
        .toList();

    final colors = AppColors.of(context);
    bool matchesFilter(OptimizationSuggestion item) =>
        (state.selectedSection.isEmpty ||
            item.section == state.selectedSection) &&
        switch (state.selectedFilter) {
          SuggestionFilter.all => true,
          SuggestionFilter.pending => item.status == SuggestionStatus.pending,
          SuggestionFilter.accepted => item.status == SuggestionStatus.accepted,
          SuggestionFilter.edited => item.status == SuggestionStatus.edited,
          SuggestionFilter.rejected => item.status == SuggestionStatus.rejected,
          SuggestionFilter.critical =>
            item.severity.toUpperCase() == 'CRITICAL' ||
                item.severity.toUpperCase() == 'HIGH',
        };
    final visibleSuggestions = analysis.suggestions
        .where(matchesFilter)
        .toList();
    final hasEvidenceSuggestions = analysis.suggestions.any(
      (item) => item.resumePath != 'skills',
    );

    return AppScaffold(
      title: 'Optimization Workspace',
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: AppSpacing.sm),
          child: Center(child: CreditBadge(credits: credits)),
        ),
      ],
      body: ResponsiveContent(
        maxWidth: 1100,
        child: Column(
          children: [
            const OptimizationStepHeader(step: 3),
            const SizedBox(height: AppSpacing.md),
            if (!hasEvidenceSuggestions &&
                state.credits != null &&
                credits < state.generationCost)
              const Padding(
                padding: EdgeInsets.only(bottom: AppSpacing.sm),
                child: Text(
                  'Not enough AI credits. Resume editing and PDFs remain available.',
                ),
              ),
            if (!hasEvidenceSuggestions)
              AppPrimaryButton(
                label:
                    'Generate evidence-backed suggestions · ${state.generationCost} credits',
                icon: Icons.auto_awesome,
                loading: state.busy,
                onPressed:
                    state.credits != null && credits < state.generationCost
                    ? null
                    : () async {
                        final ok = await ref
                            .read(optimizationProvider.notifier)
                            .generateSuggestions();
                        if (!context.mounted || ok) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              ref.read(optimizationProvider).error ??
                                  'Generation failed.',
                            ),
                          ),
                        );
                      },
              ),
            Expanded(
              child: ListView(
                children: [
                  if (analysis.suggestions.isNotEmpty) ...[
                    Text(
                      'AI suggestions',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: SuggestionFilter.values.map((filter) {
                        final count = analysis.suggestions.where((item) {
                          if (filter == SuggestionFilter.all) return true;
                          if (filter == SuggestionFilter.critical) {
                            return item.severity.toUpperCase() == 'CRITICAL' ||
                                item.severity.toUpperCase() == 'HIGH';
                          }
                          return item.status.name == filter.name;
                        }).length;
                        return FilterChip(
                          label: Text(
                            '${filter.name[0].toUpperCase()}${filter.name.substring(1)} ($count)',
                          ),
                          selected: state.selectedFilter == filter,
                          onSelected: (_) => ref
                              .read(optimizationProvider.notifier)
                              .setFilter(filter),
                        );
                      }).toList(),
                    ),
                    if (analysis.suggestions
                            .map((item) => item.section)
                            .toSet()
                            .length >
                        1) ...[
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        children:
                            <String>{
                                  '',
                                  ...analysis.suggestions.map(
                                    (item) => item.section,
                                  ),
                                }
                                .map(
                                  (section) => ChoiceChip(
                                    label: Text(
                                      section.isEmpty
                                          ? 'All sections'
                                          : section,
                                    ),
                                    selected: state.selectedSection == section,
                                    onSelected: (_) => ref
                                        .read(optimizationProvider.notifier)
                                        .setSectionFilter(section),
                                  ),
                                )
                                .toList(),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.sm),
                    ...visibleSuggestions.map(
                      (suggestion) => Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.md),
                        child: AppCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                suggestion.resumePath,
                                style: Theme.of(context).textTheme.labelMedium,
                              ),
                              const SizedBox(height: 8),
                              Text('Current: ${suggestion.current}'),
                              const SizedBox(height: 8),
                              Text(
                                'Suggested: ${suggestion.proposed}',
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 8),
                              Text('Why: ${suggestion.reason}'),
                              Text(
                                'Severity: ${suggestion.severity.toLowerCase()}',
                              ),
                              if (suggestion.requiresConfirmation)
                                const Padding(
                                  padding: EdgeInsets.only(top: 6),
                                  child: Text(
                                    'Confirm this factual claim before accepting it.',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              if (suggestion.keywords.isNotEmpty)
                                Text(
                                  'Keywords: ${suggestion.keywords.join(', ')}',
                                ),
                              Text('Evidence: ${suggestion.evidence}'),
                              const SizedBox(height: 8),
                              StatusPill(status: suggestion.status),
                              if (state.processingSuggestionId == suggestion.id)
                                const LinearProgressIndicator(),
                              Wrap(
                                spacing: 8,
                                children: [
                                  if (suggestion.status !=
                                      SuggestionStatus.accepted)
                                    TextButton(
                                      onPressed:
                                          state.processingSuggestionId == null
                                          ? () => _review(
                                              suggestion.id,
                                              SuggestionStatus.accepted,
                                            )
                                          : null,
                                      child: Text(
                                        suggestion.status ==
                                                SuggestionStatus.edited
                                            ? 'Use AI version'
                                            : 'Accept',
                                      ),
                                    ),
                                  TextButton(
                                    onPressed:
                                        state.processingSuggestionId == null
                                        ? () => context.push(
                                            '/resume/optimize/suggestions/${suggestion.id}/edit',
                                          )
                                        : null,
                                    child: Text(
                                      suggestion.status ==
                                              SuggestionStatus.edited
                                          ? 'Edit again'
                                          : 'Edit',
                                    ),
                                  ),
                                  if (suggestion.status !=
                                      SuggestionStatus.rejected)
                                    TextButton(
                                      onPressed:
                                          state.processingSuggestionId == null
                                          ? () => _review(
                                              suggestion.id,
                                              SuggestionStatus.rejected,
                                            )
                                          : null,
                                      child: const Text('Reject'),
                                    ),
                                  if (suggestion.status ==
                                      SuggestionStatus.rejected)
                                    TextButton(
                                      onPressed:
                                          state.processingSuggestionId == null
                                          ? () => _review(
                                              suggestion.id,
                                              SuggestionStatus.pending,
                                            )
                                          : null,
                                      child: const Text('Undo'),
                                    ),
                                  if (suggestion.status ==
                                      SuggestionStatus.pending)
                                    TextButton(
                                      onPressed:
                                          state.processingSuggestionId ==
                                                  null &&
                                              credits >= state.regenerationCost
                                          ? () => _regenerate(suggestion.id)
                                          : null,
                                      child: Text(
                                        'Improve with AI · ${state.regenerationCost} credit(s)',
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                  ],
                  // Step 4 Milestone Banner
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.fact_check_outlined,
                              color: colors.primary,
                              size: 28,
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Text(
                                'Requirement & Evidence Workspace',
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          'Suggestions are grounded in the matched evidence below. Review every change before creating an optimized version; your master resume stays untouched.',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: colors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // Section 1: High-Value Matched Areas
                  _WorkspaceSection(
                    title:
                        '1. Verified Matched Experience (${matchedList.length})',
                    subtitle:
                        'Genuine evidence found in your resume. Ready for summary and bullet alignment.',
                    color: colors.success,
                    items: matchedList,
                    icon: Icons.check_circle_outline,
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // Section 2: Partial Alignment Areas
                  if (partialList.isNotEmpty) ...[
                    _WorkspaceSection(
                      title:
                          '2. Partial Alignment Areas (${partialList.length})',
                      subtitle:
                          'Related skills or responsibilities found, but specific JD scope can be articulated more clearly.',
                      color: colors.warning,
                      items: partialList,
                      icon: Icons.timelapse,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                  ],

                  // Section 3: Missing Requirements (Guardrail)
                  if (missingList.isNotEmpty || unclearList.isNotEmpty) ...[
                    _WorkspaceSection(
                      title:
                          '3. Missing & Unclear Skills (${missingList.length + unclearList.length})',
                      subtitle:
                          'No evidence found in your resume. PrepMateAI will never fabricate experience for these.',
                      color: colors.error,
                      items: [...missingList, ...unclearList],
                      icon: Icons.shield_outlined,
                      onAddSkill: _confirmMissingSkill,
                      processingId: state.processingSuggestionId,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                  ],

                  const InformationBanner(
                    icon: Icons.verified_user_outlined,
                    title: 'Evidence-backed changes only',
                    message:
                        'Your master resume remains 100% untouched. All evidence references link to exact resume JSON paths for complete auditability.',
                  ),
                  const SizedBox(height: AppSpacing.xl),
                ],
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: AppSecondaryButton(
                    label: 'Back to Match Analysis',
                    icon: Icons.arrow_back,
                    onPressed: () => context.pop(),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                if (analysis.suggestions.any(
                  (s) =>
                      s.status == SuggestionStatus.accepted ||
                      s.status == SuggestionStatus.edited,
                ))
                  Expanded(
                    child: AppPrimaryButton(
                      label: 'Review & create version',
                      icon: Icons.arrow_forward,
                      onPressed: () => context.push('/resume/optimize/summary'),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _WorkspaceSection extends StatelessWidget {
  const _WorkspaceSection({
    required this.title,
    required this.subtitle,
    required this.color,
    required this.items,
    required this.icon,
    this.onAddSkill,
    this.processingId,
  });

  final String title;
  final String subtitle;
  final Color color;
  final List<JobRequirement> items;
  final IconData icon;
  final Future<void> Function(JobRequirement requirement)? onAddSkill;
  final String? processingId;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: colors.textSecondary),
        ),
        const SizedBox(height: AppSpacing.sm),
        ...items.map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.xs),
            child: AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        item.name,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                        ),
                        child: Text(
                          '${item.importance} · ${item.category}',
                          style: TextStyle(
                            color: color,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.explanation,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  if (item.evidence != null || item.evidencePath != null) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          Icons.inventory_2_outlined,
                          size: 14,
                          color: colors.primary,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            '${item.evidenceContext ?? ''} ${item.evidence != null ? '("${item.evidence}")' : ''}',
                            style: TextStyle(
                              color: colors.primary,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    if (item.evidencePath != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 2, left: 18),
                        child: Text(
                          'Path: ${item.evidencePath}',
                          style: TextStyle(
                            color: colors.textSecondary,
                            fontSize: 11,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ),
                  ],
                  if (onAddSkill != null) ...[
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: OutlinedButton.icon(
                        onPressed: processingId == null
                            ? () => onAddSkill!(item)
                            : null,
                        icon: processingId == item.id
                            ? const SizedBox.square(
                                dimension: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.add),
                        label: const Text('Add if I have this skill'),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
