import 'package:flutter/material.dart';
import '../../../../config/theme.dart';
import '../../../../core/widgets/app_button.dart';

/// Screen 52: Suggestion Editor Confirmation & Inspection Sheets
///
/// Multi-mode bottom sheet providing:
/// 1. Final Acceptance Confirmation (target placement, final quote preview, authenticity verification)
/// 2. Diff Inspector (visual inline additions and removals)
/// 3. AI Refine (quick tone adjustments: Executive, Technical, Concise)
class SuggestionEditorConfirmationSheet extends StatefulWidget {
  const SuggestionEditorConfirmationSheet({
    super.key,
    required this.originalText,
    required this.editedText,
    required this.section,
    required this.destinationTitle,
    required this.onConfirmAccept,
    required this.onRefineRequested,
  });

  final String originalText;
  final String editedText;
  final String section;
  final String destinationTitle;
  final VoidCallback onConfirmAccept;
  final ValueChanged<String> onRefineRequested;

  static Future<void> show(
    BuildContext context, {
    required String originalText,
    required String editedText,
    required String section,
    required String destinationTitle,
    required VoidCallback onConfirmAccept,
    required ValueChanged<String> onRefineRequested,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SuggestionEditorConfirmationSheet(
        originalText: originalText,
        editedText: editedText,
        section: section,
        destinationTitle: destinationTitle,
        onConfirmAccept: onConfirmAccept,
        onRefineRequested: onRefineRequested,
      ),
    );
  }

  @override
  State<SuggestionEditorConfirmationSheet> createState() =>
      _SuggestionEditorConfirmationSheetState();
}

class _SuggestionEditorConfirmationSheetState
    extends State<SuggestionEditorConfirmationSheet> {
  int _activeTab = 0; // 0: Confirmation, 1: Diff Inspector, 2: AI Refine

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colors.border,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
              ),
            ),
            // Segmented Header Mode Switcher
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.xs,
              ),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: colors.screenBackground,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(color: colors.border),
                ),
                child: Row(
                  children: [
                    _buildTabButton(0, 'Confirmation', Icons.verified),
                    _buildTabButton(1, 'Diff Inspector', Icons.difference),
                    _buildTabButton(2, 'AI Refine', Icons.auto_fix_high),
                  ],
                ),
              ),
            ),
            const Divider(),
            Expanded(
              child: switch (_activeTab) {
                0 => _buildConfirmationTab(context),
                1 => _buildDiffTab(context),
                _ => _buildRefineTab(context),
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabButton(int index, String title, IconData icon) {
    final colors = AppColors.of(context);
    final isSelected = _activeTab == index;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _activeTab = index),
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? colors.surface : Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadius.sm),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 4,
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 15,
                color: isSelected ? colors.primary : colors.textSecondary,
              ),
              const SizedBox(width: 4),
              Text(
                title,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? colors.primary : colors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildConfirmationTab(BuildContext context) {
    final colors = AppColors.of(context);
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Accept this edited suggestion?',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Review target placement and verify authenticity before merging into your active resume branch.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                color: Color(0xFFE1F4F1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.task_alt,
                color: Color(0xFF087E78),
                size: 20,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        // Placement Target Chip
        Container(
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: colors.screenBackground,
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Row(
            children: [
              Icon(Icons.pin_drop, size: 18, color: colors.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'PLACEMENT TARGET',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: colors.textSecondary,
                      ),
                    ),
                    Text(
                      widget.destinationTitle,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        // Final Output Preview
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: colors.surface,
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
                      Icon(Icons.edit_note, size: 16, color: colors.primary),
                      const SizedBox(width: 4),
                      Text(
                        'Final Output Preview',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: colors.primary,
                        ),
                      ),
                    ],
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
                      'Verified Output',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF087E78),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                widget.editedText,
                style: const TextStyle(fontSize: 14, height: 1.4),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        AppButton(
          label: 'Confirm & Apply to Resume Draft',
          onPressed: () {
            Navigator.pop(context);
            widget.onConfirmAccept();
          },
        ),
        const SizedBox(height: AppSpacing.sm),
        OutlinedButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Keep Editing'),
        ),
      ],
    );
  }

  Widget _buildDiffTab(BuildContext context) {
    final colors = AppColors.of(context);
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        Text(
          'Visual Change Diff',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          'Compare the original baseline with your revised proposal.',
          style: TextStyle(fontSize: 12, color: colors.textSecondary),
        ),
        const SizedBox(height: AppSpacing.md),
        // Original with red strikethrough styling
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: const Color(0xFFFFDAD6).withOpacity(0.4),
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: const Color(0xFFBA1A1A).withOpacity(0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: const [
                  Icon(
                    Icons.remove_circle_outline,
                    color: Color(0xFFBA1A1A),
                    size: 16,
                  ),
                  SizedBox(width: 6),
                  Text(
                    'ORIGINAL BASELINE',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFBA1A1A),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                widget.originalText,
                style: const TextStyle(
                  fontSize: 13,
                  decoration: TextDecoration.lineThrough,
                  color: Color(0xFF434654),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        // Proposed with green highlight
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: const Color(0xFFE1F4F1),
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: const Color(0xFF087E78).withOpacity(0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: const [
                  Icon(
                    Icons.add_circle_outline,
                    color: Color(0xFF087E78),
                    size: 16,
                  ),
                  SizedBox(width: 6),
                  Text(
                    'REVISED PROPOSAL',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF087E78),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                widget.editedText,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF172033),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRefineTab(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        Text(
          'AI Refine & Tone Assistant',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        const Text(
          'Re-craft this statement with specific phrasing guidelines. (1 credit)',
          style: TextStyle(fontSize: 12, color: Colors.grey),
        ),
        const SizedBox(height: AppSpacing.md),
        _buildRefineTile(
          context,
          title: 'Executive & Strategic',
          subtitle:
              'Elevates cross-functional leadership, architectural impact, and delivery milestones.',
          instruction:
              'Make this executive and emphasize cross-functional leadership and architecture.',
        ),
        _buildRefineTile(
          context,
          title: 'Technical & Deep-Dive',
          subtitle:
              'Focuses on tools, libraries, performance profiling, and engineering trade-offs.',
          instruction:
              'Highlight technical depth, engineering tools, and system performance.',
        ),
        _buildRefineTile(
          context,
          title: 'Concise & High-Density',
          subtitle:
              'Trims filler words to achieve high information density in under 25 words.',
          instruction:
              'Make this concise, punchy, and under 25 words with strong action verbs.',
        ),
      ],
    );
  }

  Widget _buildRefineTile(
    BuildContext context, {
    required String title,
    required String subtitle,
    required String instruction,
  }) {
    final colors = AppColors.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: ListTile(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(
          subtitle,
          style: TextStyle(fontSize: 12, color: colors.textSecondary),
        ),
        trailing: OutlinedButton(
          onPressed: () {
            Navigator.pop(context);
            widget.onRefineRequested(instruction);
          },
          child: const Text('Apply Tone'),
        ),
      ),
    );
  }
}
