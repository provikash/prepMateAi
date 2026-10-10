import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../config/theme.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/app_state.dart';
import '../../domain/optimization_models.dart';
import '../providers/optimization_provider.dart';

/// Screen 51: Suggestions Workspace — Populated
class AiSuggestionsScreen extends ConsumerStatefulWidget {
  const AiSuggestionsScreen({super.key});

  @override
  ConsumerState<AiSuggestionsScreen> createState() => _AiSuggestionsState();
}

class _AiSuggestionsState extends ConsumerState<AiSuggestionsScreen> {
  String _activeFilter = 'All'; // All, Not reviewed, Accepted, Edited, Skipped
  bool _groupBySection = true;

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

  @override
  Widget build(BuildContext context) {
    final optState = ref.watch(optimizationProvider);
    final analysis = optState.analysis;
    final colors = AppColors.of(context);

    if (analysis == null) {
      return AppScaffold(
        title: 'Review Suggestions',
        body: AppErrorState(
          message: 'Analyze a job to view suggestions.',
          actionLabel: 'Go to setup',
          onAction: () => context.go('/resume/optimize'),
        ),
      );
    }

    final allSuggestions = analysis.suggestions;
    final total = allSuggestions.length;
    final accepted = allSuggestions
        .where((s) => s.status == SuggestionStatus.accepted)
        .length;
    final edited = allSuggestions
        .where((s) => s.status == SuggestionStatus.edited)
        .length;
    final skipped = allSuggestions
        .where((s) => s.status == SuggestionStatus.rejected)
        .length;
    final pending = allSuggestions
        .where((s) => s.status == SuggestionStatus.pending)
        .length;
    final reviewed = accepted + edited + skipped;
    final progress = total > 0 ? (reviewed / total) : 0.0;

    // Filtered suggestions
    final filtered = allSuggestions.where((s) {
      return switch (_activeFilter) {
        'Not reviewed' => s.status == SuggestionStatus.pending,
        'Accepted' => s.status == SuggestionStatus.accepted,
        'Edited' => s.status == SuggestionStatus.edited,
        'Skipped' => s.status == SuggestionStatus.rejected,
        _ => true,
      };
    }).toList();

    // Grouping by section
    final Map<String, List<OptimizationSuggestion>> groups = {};
    for (final s in filtered) {
      final sec = s.section.isNotEmpty ? s.section : 'General';
      groups.putIfAbsent(sec, () => []).add(s);
    }

    final displayRole = optState.jobTitle.isNotEmpty
        ? optState.jobTitle
        : 'Senior Flutter Developer';
    final displayCompany = optState.company.isNotEmpty
        ? optState.company
        : 'Acme Technologies';

    return AppScaffold(
      title: 'Review Suggestions',
      actions: [
        IconButton(
          tooltip: 'Toggle Grouping',
          icon: Icon(_groupBySection ? Icons.view_agenda : Icons.view_list),
          onPressed: () => setState(() => _groupBySection = !_groupBySection),
        ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert),
          onSelected: (val) {
            switch (val) {
              case 'analysis':
                context.push('/resume/optimize/analysis');
                break;
              case 'generate':
                ref.read(optimizationProvider.notifier).generateSuggestions();
                break;
            }
          },
          itemBuilder: (ctx) => [
            const PopupMenuItem(
              value: 'analysis',
              child: Text('View Job Analysis'),
            ),
            const PopupMenuItem(
              value: 'generate',
              child: Text('Re-synthesize Suggestions'),
            ),
          ],
        ),
      ],
      body: Column(
        children: [
          // Sticky / Top Progress Card
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.xs,
            ),
            child: AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.fact_check,
                            size: 18,
                            color: colors.primary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '$reviewed of $total reviewed',
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      Text(
                        '${(progress * 100).toInt()}% completed',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: colors.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Multi-segment progress bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    child: SizedBox(
                      height: 6,
                      child: Row(
                        children: [
                          if (accepted > 0)
                            Expanded(
                              flex: accepted,
                              child: Container(color: const Color(0xFF087E78)),
                            ),
                          if (edited > 0)
                            Expanded(
                              flex: edited,
                              child: Container(color: colors.primary),
                            ),
                          if (skipped > 0)
                            Expanded(
                              flex: skipped,
                              child: Container(color: colors.border),
                            ),
                          if (pending > 0)
                            Expanded(
                              flex: pending,
                              child: Container(color: const Color(0xFFFFDAD6)),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Counts breakdown chips
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      _buildCountBadge(
                        context,
                        '$accepted accepted',
                        const Color(0xFF087E78),
                        const Color(0xFFE1F4F1),
                      ),
                      _buildCountBadge(
                        context,
                        '$edited edited',
                        colors.primary,
                        colors.primarySoft,
                      ),
                      _buildCountBadge(
                        context,
                        '$skipped skipped',
                        colors.textSecondary,
                        colors.mutedBackground,
                      ),
                      _buildCountBadge(
                        context,
                        '$pending remaining',
                        const Color(0xFFBA1A1A),
                        const Color(0xFFFFDAD6),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Review each suggestion and keep only changes that are accurate to your actual experience.',
                    style: TextStyle(fontSize: 11, color: colors.textSecondary),
                  ),
                ],
              ),
            ),
          ),

          // Horizontal Filter Chips Toolbar
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: 4,
            ),
            child: Row(
              children: [
                _buildFilterChip('All', total),
                const SizedBox(width: 6),
                _buildFilterChip('Not reviewed', pending),
                const SizedBox(width: 6),
                _buildFilterChip('Accepted', accepted),
                const SizedBox(width: 6),
                _buildFilterChip('Edited', edited),
                const SizedBox(width: 6),
                _buildFilterChip('Skipped', skipped),
              ],
            ),
          ),

          // Suggestions List
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.md),
              children: [
                if (filtered.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.xl),
                      child: Text(
                        'No suggestions match "$_activeFilter".',
                        style: TextStyle(color: colors.textSecondary),
                      ),
                    ),
                  )
                else if (_groupBySection)
                  ...groups.entries.map((entry) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: AppSpacing.sm,
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 4,
                                height: 16,
                                decoration: BoxDecoration(
                                  color: colors.primary,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                entry.key.toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.8,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '(${entry.value.length})',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: colors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        ...entry.value.map(
                          (s) => _buildSuggestionCard(context, s),
                        ),
                      ],
                    );
                  })
                else
                  ...filtered.map((s) => _buildSuggestionCard(context, s)),
                const SizedBox(height: 80),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: colors.surface,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 8,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$reviewed of $total Decisions Made',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      '$accepted accepted · $edited edited',
                      style: TextStyle(
                        fontSize: 11,
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              FilledButton.icon(
                onPressed: () => context.push('/resume/optimize/summary'),
                icon: const Icon(Icons.arrow_forward, size: 16),
                label: const Text('Create Tailored Resume'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCountBadge(
    BuildContext context,
    String text,
    Color textColor,
    Color bgColor,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, int count) {
    final isSelected = _activeFilter == label;
    return ChoiceChip(
      selected: isSelected,
      onSelected: (_) => setState(() => _activeFilter = label),
      label: Text('$label ($count)', style: const TextStyle(fontSize: 11)),
    );
  }

  Widget _buildSuggestionCard(
    BuildContext context,
    OptimizationSuggestion item,
  ) {
    final colors = AppColors.of(context);
    final isAccepted = item.status == SuggestionStatus.accepted;
    final isEdited = item.status == SuggestionStatus.edited;
    final isSkipped = item.status == SuggestionStatus.rejected;
    final isPending = item.status == SuggestionStatus.pending;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: isAccepted
              ? const Color(0xFF087E78).withOpacity(0.5)
              : isEdited
              ? colors.primary.withOpacity(0.5)
              : isSkipped
              ? colors.border
              : colors.border,
          width: isAccepted || isEdited ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card Header
          Padding(
            padding: const EdgeInsets.all(AppSpacing.sm),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: colors.mutedBackground,
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                      child: Text(
                        item.section.toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: colors.textSecondary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    if (item.highImpact)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE1F4F1),
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                        ),
                        child: const Text(
                          'High Impact',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF087E78),
                          ),
                        ),
                      ),
                  ],
                ),
                // Status badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: isAccepted
                        ? const Color(0xFFE1F4F1)
                        : isEdited
                        ? colors.primarySoft
                        : isSkipped
                        ? colors.mutedBackground
                        : const Color(0xFFFFDAD6),
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  child: Text(
                    isAccepted
                        ? 'Accepted'
                        : isEdited
                        ? 'Edited'
                        : isSkipped
                        ? 'Skipped'
                        : 'Pending',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: isAccepted
                          ? const Color(0xFF087E78)
                          : isEdited
                          ? colors.primary
                          : isSkipped
                          ? colors.textSecondary
                          : const Color(0xFFBA1A1A),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Content comparison block
          Padding(
            padding: const EdgeInsets.all(AppSpacing.sm),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (item.current.isNotEmpty) ...[
                  const Text(
                    'Baseline Text:',
                    style: TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '“${item.current}”',
                    style: TextStyle(
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                      decoration: isSkipped ? null : TextDecoration.lineThrough,
                      color: isSkipped
                          ? colors.textPrimary
                          : colors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                const Text(
                  'Proposed Tailored Statement:',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 2),
                Text(
                  item.proposed,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: isSkipped
                        ? colors.textSecondary
                        : colors.textPrimary,
                  ),
                ),
                if (item.reason.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.info_outline, size: 14, color: colors.primary),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          item.reason,
                          style: TextStyle(
                            fontSize: 11,
                            color: colors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          // Actions Toolbar
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: 6,
            ),
            color: colors.mutedBackground,
            child: Row(
              children: [
                if (isPending) ...[
                  FilledButton.tonalIcon(
                    onPressed: () =>
                        _review(item.id, SuggestionStatus.accepted),
                    icon: const Icon(Icons.check, size: 16),
                    label: const Text('Accept', style: TextStyle(fontSize: 12)),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      minimumSize: Size.zero,
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: () => context.push(
                      '/resume/optimize/suggestions/${item.id}/edit',
                    ),
                    icon: const Icon(Icons.edit, size: 14),
                    label: const Text('Edit', style: TextStyle(fontSize: 12)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      minimumSize: Size.zero,
                    ),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: () =>
                        _review(item.id, SuggestionStatus.rejected),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      minimumSize: Size.zero,
                    ),
                    child: const Text(
                      'Skip',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ),
                ] else ...[
                  OutlinedButton.icon(
                    onPressed: () => _review(item.id, SuggestionStatus.pending),
                    icon: const Icon(Icons.undo, size: 14),
                    label: const Text(
                      'Undo Decision',
                      style: TextStyle(fontSize: 12),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      minimumSize: Size.zero,
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: () => context.push(
                      '/resume/optimize/suggestions/${item.id}/edit',
                    ),
                    icon: const Icon(Icons.edit, size: 14),
                    label: const Text(
                      'Edit Further',
                      style: TextStyle(fontSize: 12),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      minimumSize: Size.zero,
                    ),
                  ),
                ],
                const Spacer(),
                IconButton(
                  tooltip: 'Refine with AI',
                  icon: const Icon(Icons.auto_fix_high, size: 18),
                  onPressed: () => _regenerate(item.id),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
