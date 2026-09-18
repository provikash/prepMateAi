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
import '../../../ai_credits/presentation/providers/ai_credits_provider.dart';

class AiSuggestionsScreen extends ConsumerStatefulWidget {
  const AiSuggestionsScreen({super.key});
  @override
  ConsumerState<AiSuggestionsScreen> createState() => _AiSuggestionsState();
}

class _AiSuggestionsState extends ConsumerState<AiSuggestionsScreen> {
  SuggestionStatus? filter;
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(optimizationProvider);
    final credits = ref.watch(aiCreditsProvider).account?.availableCredits ?? 0;
    final suggestions = state.analysis?.suggestions;
    if (suggestions == null) {
      return AppScaffold(
        title: 'AI Suggestions',
        body: AppErrorState(
          message: 'Analysis results are unavailable.',
          onAction: () => context.go('/resume/optimize'),
        ),
      );
    }
    final shown = filter == null
        ? suggestions
        : suggestions.where((item) => item.status == filter).toList();
    final accepted = suggestions
        .where(
          (item) =>
              item.status == SuggestionStatus.accepted ||
              item.status == SuggestionStatus.edited,
        )
        .length;
    return AppScaffold(
      title: 'AI Suggestions',
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
            Row(
              children: [
                Expanded(
                  child: Text(
                    '$accepted of ${suggestions.length} changes selected',
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                ),
                TextButton.icon(
                  onPressed: ref
                      .read(optimizationProvider.notifier)
                      .acceptRecommended,
                  icon: const Icon(Icons.done_all),
                  label: const Text('Accept recommended'),
                ),
              ],
            ),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final option in <SuggestionStatus?>[
                    null,
                    ...SuggestionStatus.values,
                  ])
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(option == null ? 'All' : _label(option)),
                        selected: filter == option,
                        onSelected: (_) => setState(() => filter = option),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final list = ListView.separated(
                    itemCount: shown.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: AppSpacing.sm),
                    itemBuilder: (_, index) =>
                        _SuggestionCard(item: shown[index]),
                  );
                  if (constraints.maxWidth < 760) return list;
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: AppCard(
                          child: SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  state.resume?.title ?? 'Resume context',
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                                const SizedBox(height: AppSpacing.md),
                                Text(
                                  suggestions
                                      .map(
                                        (item) =>
                                            '${item.section}\n${item.current}',
                                      )
                                      .join('\n\n'),
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(
                                        color: AppColors.of(
                                          context,
                                        ).textSecondary,
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(child: list),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            AppPrimaryButton(
              label: 'Continue to Review Summary',
              icon: Icons.arrow_forward,
              onPressed: () => context.push('/resume/optimize/summary'),
            ),
          ],
        ),
      ),
    );
  }

  String _label(SuggestionStatus status) =>
      '${status.name[0].toUpperCase()}${status.name.substring(1)}';
}

class _SuggestionCard extends ConsumerWidget {
  const _SuggestionCard({required this.item});
  final OptimizationSuggestion item;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = AppColors.of(context);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  item.section.toUpperCase(),
                  style: Theme.of(
                    context,
                  ).textTheme.labelSmall?.copyWith(color: colors.primary),
                ),
              ),
              StatusPill(status: item.status),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Current',
            style: Theme.of(
              context,
            ).textTheme.labelMedium?.copyWith(color: colors.textSecondary),
          ),
          const SizedBox(height: 4),
          Text(item.current),
          const SizedBox(height: AppSpacing.md),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: colors.primarySoft,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AI Suggestion',
                  style: Theme.of(
                    context,
                  ).textTheme.labelMedium?.copyWith(color: colors.primary),
                ),
                const SizedBox(height: 5),
                Text(item.proposed),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Why this change?',
            style: Theme.of(context).textTheme.labelMedium,
          ),
          Text(
            item.reason,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: colors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: item.keywords
                .map((keyword) => Chip(label: Text(keyword)))
                .toList(),
          ),
          TextButton.icon(
            onPressed: () => showDialog<void>(
              context: context,
              builder: (dialogContext) => AlertDialog(
                title: const Text('Evidence'),
                content: Text(item.evidence),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    child: const Text('Close'),
                  ),
                ],
              ),
            ),
            icon: const Icon(Icons.find_in_page_outlined),
            label: const Text('Evidence'),
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: item.status == SuggestionStatus.pending
                ? [
                    FilledButton.icon(
                      onPressed: () => ref
                          .read(optimizationProvider.notifier)
                          .setSuggestionStatus(
                            item.id,
                            SuggestionStatus.accepted,
                          ),
                      icon: const Icon(Icons.check),
                      label: const Text('Accept'),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => context.push(
                        '/resume/optimize/suggestions/${item.id}/edit',
                      ),
                      icon: const Icon(Icons.edit_outlined),
                      label: const Text('Edit'),
                    ),
                    TextButton.icon(
                      onPressed: () => ref
                          .read(optimizationProvider.notifier)
                          .setSuggestionStatus(
                            item.id,
                            SuggestionStatus.rejected,
                          ),
                      icon: const Icon(Icons.close),
                      label: const Text('Reject'),
                    ),
                  ]
                : [
                    TextButton.icon(
                      onPressed: () => ref
                          .read(optimizationProvider.notifier)
                          .setSuggestionStatus(
                            item.id,
                            SuggestionStatus.pending,
                          ),
                      icon: const Icon(Icons.undo),
                      label: const Text('Undo'),
                    ),
                  ],
          ),
        ],
      ),
    );
  }
}
