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
import '../widgets/suggestion_editor_inspection_sheets.dart';
import '../widgets/suggestion_editor_recovery_modals.dart';
import '../widgets/suggestion_editor_variants.dart';
import '../../../ai_credits/presentation/providers/ai_credits_provider.dart';

/// Screen 55: Suggestion Editor — Main Experience Bullet
/// Screen 54: Suggestion Editor — Tool-Specific Variants
/// Screen 52: Suggestion Editor — Confirmation & Inspection Sheets
/// Screen 53: Suggestion Editor — Edge States & Recovery Modals
class SuggestionEditorScreen extends ConsumerStatefulWidget {
  const SuggestionEditorScreen({super.key, required this.suggestionId});

  final String suggestionId;

  @override
  ConsumerState<SuggestionEditorScreen> createState() =>
      _SuggestionEditorScreenState();
}

class _SuggestionEditorScreenState
    extends ConsumerState<SuggestionEditorScreen> {
  TextEditingController? _controller;
  bool _showRestoredDraftBanner = false;
  bool _showConflictAlert = false;
  bool _factCheck1 = true;
  bool _factCheck2 = true;
  bool _factCheck3 = true;
  bool _isVariantsMode = false;

  final List<String> _actionVerbs = [
    'Architected',
    'Accelerated',
    'Spearheaded',
    'Orchestrated',
    'Engineered',
    'Modernized',
  ];

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
    _controller?.dispose();
    super.dispose();
  }

  void _insertVerb(String verb) {
    if (_controller == null) return;
    final current = _controller!.text;
    final words = current.split(' ');
    if (words.isNotEmpty) {
      words[0] = verb;
      _controller!.text = words.join(' ');
    } else {
      _controller!.text = '$verb ';
    }
    setState(() {});
  }

  Future<void> _handleAccept(OptimizationSuggestion item) async {
    final text = _controller?.text.trim() ?? item.proposed;
    await ref.read(optimizationProvider.notifier).editSuggestion(item.id, text);
    if (!mounted) return;
    context.pop();
  }

  Future<void> _handleRefine(
    String instruction,
    OptimizationSuggestion item,
  ) async {
    final result = await ref
        .read(optimizationProvider.notifier)
        .regenerate(item.id, instruction);
    if (result != null && mounted) {
      _controller?.text = result;
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Suggestion re-crafted with selected tone.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(optimizationProvider);
    final creditState = ref.watch(aiCreditsProvider);
    final colors = AppColors.of(context);
    final credits = creditState.account?.availableCredits ?? state.credits ?? 0;

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
    _controller ??= TextEditingController(text: item.proposed);

    final displayRole = state.jobTitle.isNotEmpty
        ? state.jobTitle
        : 'Senior Flutter Developer';
    final displayCompany = state.company.isNotEmpty
        ? state.company
        : 'Acme Technologies Inc.';
    final destination =
        'Experience • Flutter Developer • Example Labs (Bullet 2)';

    return AppScaffold(
      title: 'Edit Suggestion',
      actions: [
        IconButton(
          tooltip: _isVariantsMode
              ? 'Switch to Experience'
              : 'Tool Variants (P24)',
          icon: Icon(
            _isVariantsMode ? Icons.work_outline : Icons.auto_awesome_motion,
          ),
          onPressed: () => setState(() => _isVariantsMode = !_isVariantsMode),
        ),
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: Center(child: CreditBadge(credits: credits)),
        ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert),
          onSelected: (val) {
            switch (val) {
              case 'restore_ai':
                _controller?.text = item.proposed;
                setState(() {});
                break;
              case 'restore_baseline':
                _controller?.text = item.current;
                setState(() {});
                break;
              case 'toggle_conflict':
                setState(() => _showConflictAlert = !_showConflictAlert);
                break;
              case 'toggle_draft':
                setState(
                  () => _showRestoredDraftBanner = !_showRestoredDraftBanner,
                );
                break;
            }
          },
          itemBuilder: (ctx) => [
            const PopupMenuItem(
              value: 'restore_ai',
              child: Text('Restore AI Suggestion'),
            ),
            const PopupMenuItem(
              value: 'restore_baseline',
              child: Text('Restore Baseline Resume Text'),
            ),
            const PopupMenuItem(
              value: 'toggle_conflict',
              child: Text('Simulate Fact Conflict Warning'),
            ),
            const PopupMenuItem(
              value: 'toggle_draft',
              child: Text('Simulate Auto-Recovered Draft'),
            ),
          ],
        ),
      ],
      body: _isVariantsMode
          ? SuggestionEditorVariantsWidget(
              initialSection: item.section,
              onSave: (val) {
                _controller?.text = val;
                setState(() => _isVariantsMode = false);
              },
            )
          : ListView(
              padding: const EdgeInsets.all(AppSpacing.md),
              children: [
                // Restored Draft Banner (Edge state)
                if (_showRestoredDraftBanner)
                  RestoredDraftBanner(
                    onKeepEditing: () =>
                        setState(() => _showRestoredDraftBanner = false),
                    onDiscardDraft: () {
                      _controller?.text = item.proposed;
                      setState(() => _showRestoredDraftBanner = false);
                    },
                  ),

                // Fact Conflict Warning (Edge state)
                if (_showConflictAlert)
                  FactConflictAlertBanner(
                    claimText: 'Led a squad of 6 engineers',
                    explanation:
                        'The baseline resume indicates Associate Mobile Engineer. Verify seniority claims to prevent vulnerability in interview loops.',
                    onResolve: () => setState(() => _showConflictAlert = false),
                  ),

                // Target Role Banner
                Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: colors.primarySoft.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: colors.primary,
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                        ),
                        child: const Text(
                          'TARGET ROLE',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '$displayRole · $displayCompany',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE1F4F1),
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                        ),
                        child: const Text(
                          '94% Match',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF087E78),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),

                // Destination Card
                AppCard(
                  child: Row(
                    children: [
                      Icon(Icons.near_me, color: colors.primary, size: 20),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'DESTINATION',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: colors.primary,
                                letterSpacing: 0.8,
                              ),
                            ),
                            Text(
                              destination,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            Text(
                              'Optimized draft based on saved resume snapshot v2.4',
                              style: TextStyle(
                                fontSize: 11,
                                color: colors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),

                // Comparison Accordion Block
                // 1. Baseline Text
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: colors.screenBackground,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(color: colors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.history_edu,
                                size: 16,
                                color: colors.textSecondary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Baseline Resume Text',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: colors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                          const Text(
                            'v2.4 Snapshot',
                            style: TextStyle(fontSize: 10, color: Colors.grey),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '“${item.current}”',
                        style: TextStyle(
                          fontSize: 13,
                          fontStyle: FontStyle.italic,
                          color: colors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),

                // 2. Original AI Suggestion
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: colors.primarySoft.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(color: colors.primary.withOpacity(0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.auto_awesome,
                                size: 16,
                                color: colors.primary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Original AI Proposal',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: colors.primary,
                                ),
                              ),
                            ],
                          ),
                          TextButton.icon(
                            onPressed: () {
                              _controller?.text = item.proposed;
                              setState(() {});
                            },
                            icon: const Icon(
                              Icons.settings_backup_restore,
                              size: 14,
                            ),
                            label: const Text(
                              'Restore',
                              style: TextStyle(fontSize: 11),
                            ),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              minimumSize: Size.zero,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(item.proposed, style: const TextStyle(fontSize: 13)),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),

                // Editable Working Version
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Your Working Version',
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE1F4F1),
                              borderRadius: BorderRadius.circular(
                                AppRadius.pill,
                              ),
                            ),
                            child: const Text(
                              'Draft saved locally',
                              style: TextStyle(
                                fontSize: 10,
                                color: Color(0xFF087E78),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _controller,
                        maxLines: 4,
                        decoration: const InputDecoration(
                          hintText: 'Edit your achievement statement...',
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: 10),

                      // Action Verbs Helper Chips
                      Text(
                        'Power Action Verbs',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: colors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: _actionVerbs.map((verb) {
                          return ActionChip(
                            label: Text(
                              verb,
                              style: const TextStyle(fontSize: 11),
                            ),
                            onPressed: () => _insertVerb(verb),
                            visualDensity: VisualDensity.compact,
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: AppSpacing.md),

                      // Factual Integrity Verification
                      Text(
                        'Factual Verification (Confirm before accepting)',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: colors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      CheckboxListTile(
                        value: _factCheck1,
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        onChanged: (v) =>
                            setState(() => _factCheck1 = v ?? false),
                        title: const Text(
                          'I genuinely performed this responsibility.',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                      CheckboxListTile(
                        value: _factCheck2,
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        onChanged: (v) =>
                            setState(() => _factCheck2 = v ?? false),
                        title: const Text(
                          'I collaborated with QA and cross-functional teams.',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                      CheckboxListTile(
                        value: _factCheck3,
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        onChanged: (v) =>
                            setState(() => _factCheck3 = v ?? false),
                        title: const Text(
                          'I did not fabricate metrics, numbers, or dates.',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                // Bottom Buttons
                AppButton(
                  label: 'Accept & Apply to Draft',
                  onPressed: _factCheck1 && _factCheck2 && _factCheck3
                      ? () {
                          SuggestionEditorConfirmationSheet.show(
                            context,
                            originalText: item.current,
                            editedText:
                                _controller?.text.trim() ?? item.proposed,
                            section: item.section,
                            destinationTitle: destination,
                            onConfirmAccept: () => _handleAccept(item),
                            onRefineRequested: (instruction) =>
                                _handleRefine(instruction, item),
                          );
                        }
                      : null,
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => context.pop(),
                        child: const Text('Discard Changes'),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Working draft saved locally.'),
                            ),
                          );
                          context.pop();
                        },
                        child: const Text('Save Working Draft'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
    );
  }
}
