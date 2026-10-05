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
import '../../../ai_credits/presentation/providers/ai_credits_provider.dart';

class SuggestionEditorScreen extends ConsumerStatefulWidget {
  const SuggestionEditorScreen({super.key, required this.suggestionId});
  final String suggestionId;
  @override
  ConsumerState<SuggestionEditorScreen> createState() => _State();
}

class _State extends ConsumerState<SuggestionEditorScreen> {
  TextEditingController? controller;
  bool generating = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(optimizationProvider.notifier).loadCredits();
      ref.read(aiCreditsProvider.notifier).load();
    });
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(optimizationProvider);
    final creditState = ref.watch(aiCreditsProvider);
    final credits = creditState.account?.availableCredits ?? state.credits ?? 0;
    final regenerationCost =
        creditState.operationById('suggestion_regeneration')?.creditCost ??
        state.regenerationCost;
    final matches =
        state.analysis?.suggestions
            .where((s) => s.id == widget.suggestionId)
            .toList() ??
        [];
    if (matches.isEmpty) {
      return AppScaffold(
        title: 'Edit Suggestion',
        body: const AppErrorState(
          message: 'This suggestion is no longer available.',
        ),
      );
    }
    final item = matches.first;
    controller ??= TextEditingController(text: item.proposed);
    final colors = AppColors.of(context);
    return AppScaffold(
      title: 'Edit Suggestion',
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: Center(child: CreditBadge(credits: credits)),
        ),
      ],
      body: ResponsiveContent(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                children: [
                  InformationBanner(
                    icon: Icons.work_outline,
                    title: '${state.jobTitle} · ${state.company}',
                    message:
                        '${item.section} suggestion · Manual editing uses 0 AI credits',
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    'Current Version',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  AppCard(
                    child: Text(
                      item.current,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    'Optimized Version',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  TextField(
                    controller: controller,
                    minLines: 6,
                    maxLines: 12,
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(
                      alignLabelWithHint: true,
                      hintText: 'Edit the optimized version',
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      'Characters: ${controller!.text.characters.length}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Improve with AI',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      Text(
                        'Uses $regenerationCost credit${regenerationCost == 1 ? '' : 's'}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children:
                        [
                              'Make it more concise',
                              'Make it more technical',
                              'Emphasize achievements',
                              'Emphasize relevant skills',
                              'Make it ATS-friendly',
                              'Custom instruction',
                            ]
                            .map(
                              (label) => ActionChip(
                                avatar: const Icon(
                                  Icons.auto_awesome,
                                  size: 16,
                                ),
                                label: Text(label),
                                onPressed:
                                    generating || credits < regenerationCost
                                    ? null
                                    : () => _regenerate(label),
                              ),
                            )
                            .toList(),
                  ),
                  if (generating) ...[
                    const SizedBox(height: AppSpacing.md),
                    const LinearProgressIndicator(),
                    const SizedBox(height: 6),
                    const Text('Generating suggestion...'),
                  ],
                  if (!generating && credits < regenerationCost) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'You need $regenerationCost AI credit${regenerationCost == 1 ? '' : 's'} to regenerate. Manual editing and Apply remain free.',
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: colors.warning),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.xl),
                ],
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: AppSecondaryButton(
                    label: 'Cancel',
                    onPressed: () => context.pop(),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: AppPrimaryButton(
                    label: 'Apply',
                    icon: Icons.check,
                    loading: state.processingSuggestionId == item.id,
                    onPressed:
                        controller!.text.trim().isEmpty ||
                            state.processingSuggestionId != null
                        ? null
                        : () async {
                            final ok = await ref
                                .read(optimizationProvider.notifier)
                                .editSuggestion(
                                  item.id,
                                  controller!.text.trim(),
                                );
                            if (!context.mounted) return;
                            if (ok) {
                              context.pop();
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    ref.read(optimizationProvider).error ??
                                        'Edit failed.',
                                  ),
                                ),
                              );
                            }
                          },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _regenerate(String instruction) async {
    if (instruction == 'Custom instruction') {
      final custom = await showDialog<String>(
        context: context,
        builder: (c) {
          final input = TextEditingController();
          return AlertDialog(
            title: const Text('Custom instruction'),
            content: TextField(
              controller: input,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: 'Describe the change',
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(c),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(c, input.text),
                child: const Text('Generate'),
              ),
            ],
          );
        },
      );
      if (custom == null || custom.trim().isEmpty) return;
      instruction = custom;
    }
    setState(() => generating = true);
    final value = await ref
        .read(optimizationProvider.notifier)
        .regenerate(widget.suggestionId, instruction);
    if (!mounted) return;
    setState(() {
      generating = false;
      if (value != null) {
        controller!.text = value;
        controller!.selection = TextSelection.collapsed(offset: value.length);
      }
    });
    if (value == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('We could not generate a suggestion. Try again.'),
        ),
      );
    } else {
      await ref.read(aiCreditsProvider.notifier).refreshAfterAiOperation();
    }
  }
}
