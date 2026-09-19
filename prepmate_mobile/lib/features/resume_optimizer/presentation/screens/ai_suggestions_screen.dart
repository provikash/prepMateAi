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
    final ok = await ref.read(optimizationProvider.notifier).setSuggestionStatus(id, status);
    if (!mounted || ok) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(ref.read(optimizationProvider).error ?? 'Review failed.'),
    ));
  }

  Future<void> _edit(String id, String initial) async {
    final controller = TextEditingController(text: initial);
    final value = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Edit suggestion'),
        content: TextField(controller: controller, maxLines: 5, maxLength: 1500),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(dialogContext, controller.text), child: const Text('Save')),
        ],
      ),
    );
    controller.dispose();
    if (value == null || value.trim().isEmpty || !mounted) return;
    final ok = await ref.read(optimizationProvider.notifier).editSuggestion(id, value);
    if (!mounted || ok) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(ref.read(optimizationProvider).error ?? 'Edit failed.'),
    ));
  }

  Future<void> _regenerate(String id) async {
    final controller = TextEditingController();
    final instruction = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Improve with AI · ${ref.read(optimizationProvider).regenerationCost} credit(s)'),
        content: TextField(controller: controller, maxLength: 300,
          decoration: const InputDecoration(hintText: 'Make this more concise')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(dialogContext, controller.text), child: const Text('Generate')),
        ],
      ),
    );
    controller.dispose();
    if (instruction == null || instruction.trim().isEmpty || !mounted) return;
    final result = await ref.read(optimizationProvider.notifier).regenerate(id, instruction);
    if (!mounted || result != null) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(ref.read(optimizationProvider).error ?? 'Regeneration failed.'),
    ));
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
          message: 'Analysis results are unavailable. Please analyze a job description first.',
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
            if (analysis.suggestions.isEmpty && state.credits != null &&
                credits < state.generationCost)
              const Padding(
                padding: EdgeInsets.only(bottom: AppSpacing.sm),
                child: Text('Not enough AI credits. Resume editing and PDFs remain available.'),
              ),
            if (analysis.suggestions.isEmpty) AppPrimaryButton(
              label: 'Generate evidence-backed suggestions · ${state.generationCost} credits',
              icon: Icons.auto_awesome,
              loading: state.busy,
              onPressed: state.credits != null && credits < state.generationCost ? null : () async {
                final ok = await ref.read(optimizationProvider.notifier).generateSuggestions();
                if (!context.mounted || ok) return;
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(ref.read(optimizationProvider).error ?? 'Generation failed.'),
                ));
              },
            ),
            Expanded(
              child: ListView(
                children: [
                  if (analysis.suggestions.isNotEmpty) ...[
                    Text('AI suggestions', style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: AppSpacing.sm),
                    ...analysis.suggestions.map((suggestion) => Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: AppCard(child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(suggestion.resumePath, style: Theme.of(context).textTheme.labelMedium),
                          const SizedBox(height: 8),
                          Text('Current: ${suggestion.current}'),
                          const SizedBox(height: 8),
                          Text('Suggested: ${suggestion.proposed}',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                          const SizedBox(height: 8),
                          Text('Why: ${suggestion.reason}'),
                          if (suggestion.keywords.isNotEmpty) Text('Keywords: ${suggestion.keywords.join(', ')}'),
                          Text('Evidence: ${suggestion.evidence}'),
                          const SizedBox(height: 8),
                          StatusPill(status: suggestion.status),
                          if (suggestion.status == SuggestionStatus.pending) ...[
                            if (state.processingSuggestionId == suggestion.id)
                              const LinearProgressIndicator(),
                            Wrap(spacing: 8, children: [
                              TextButton(onPressed: state.processingSuggestionId == null
                                ? () => _review(suggestion.id, SuggestionStatus.accepted) : null,
                                child: const Text('Accept')),
                              TextButton(onPressed: state.processingSuggestionId == null
                                ? () => _edit(suggestion.id, suggestion.proposed) : null,
                                child: const Text('Edit')),
                              TextButton(onPressed: state.processingSuggestionId == null
                                ? () => _review(suggestion.id, SuggestionStatus.rejected) : null,
                                child: const Text('Reject')),
                              TextButton(onPressed: state.processingSuggestionId == null && credits >= state.regenerationCost
                                ? () => _regenerate(suggestion.id) : null,
                                child: Text('Improve with AI · ${state.regenerationCost} credit(s)')),
                            ]),
                          ],
                        ],
                      )),
                    )),
                    const SizedBox(height: AppSpacing.lg),
                  ],
                  // Step 4 Milestone Banner
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.fact_check_outlined, color: colors.primary, size: 28),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Text(
                                'Requirement & Evidence Workspace',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          'Suggestions are grounded in the matched evidence below. Review every change before creating an optimized version; your master resume stays untouched.',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: colors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // Section 1: High-Value Matched Areas
                  _WorkspaceSection(
                    title: '1. Verified Matched Experience (${matchedList.length})',
                    subtitle: 'Genuine evidence found in your resume. Ready for summary and bullet alignment.',
                    color: colors.success,
                    items: matchedList,
                    icon: Icons.check_circle_outline,
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // Section 2: Partial Alignment Areas
                  if (partialList.isNotEmpty) ...[
                    _WorkspaceSection(
                      title: '2. Partial Alignment Areas (${partialList.length})',
                      subtitle: 'Related skills or responsibilities found, but specific JD scope can be articulated more clearly.',
                      color: colors.warning,
                      items: partialList,
                      icon: Icons.timelapse,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                  ],

                  // Section 3: Missing Requirements (Guardrail)
                  if (missingList.isNotEmpty || unclearList.isNotEmpty) ...[
                    _WorkspaceSection(
                      title: '3. Missing & Unclear Skills (${missingList.length + unclearList.length})',
                      subtitle: 'No evidence found in your resume. PrepMateAI will never fabricate experience for these.',
                      color: colors.error,
                      items: [...missingList, ...unclearList],
                      icon: Icons.shield_outlined,
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
                if (analysis.suggestions.any((s) =>
                    s.status == SuggestionStatus.accepted || s.status == SuggestionStatus.edited)) Expanded(
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
  });

  final String title;
  final String subtitle;
  final Color color;
  final List<JobRequirement> items;
  final IconData icon;

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
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: colors.textSecondary,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        ...items.map((item) => Padding(
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
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                      child: Text(
                        '${item.importance} · ${item.category}',
                        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold),
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
                      Icon(Icons.inventory_2_outlined, size: 14, color: colors.primary),
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
              ],
            ),
          ),
        )),
      ],
    );
  }
}
