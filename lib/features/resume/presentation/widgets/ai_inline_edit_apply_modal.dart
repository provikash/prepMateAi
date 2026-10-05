import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../config/theme.dart';
import '../providers/ai_provider.dart';

/// Screen 33: AI Result — Inline Edit and Apply Modal
///
/// Presents a high-fidelity Material 3 diff inspection bottom sheet
/// allowing review of existing vs. new AI draft, optional inline editing,
/// choice between replacing or saving as an alternative, and safe conflict-free application.
class ApplySummaryModalSheet extends ConsumerStatefulWidget {
  const ApplySummaryModalSheet({
    super.key,
    required this.existingContent,
    required this.newContent,
    this.targetResumeTitle = 'Software Engineer Resume',
    this.targetSection = 'Professional summary',
    this.onApplied,
  });

  final String existingContent;
  final String newContent;
  final String targetResumeTitle;
  final String targetSection;
  final VoidCallback? onApplied;

  static Future<bool?> show(
    BuildContext context, {
    required String existingContent,
    required String newContent,
    String targetResumeTitle = 'Software Engineer Resume',
    String targetSection = 'Professional summary',
    VoidCallback? onApplied,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ApplySummaryModalSheet(
        existingContent: existingContent,
        newContent: newContent,
        targetResumeTitle: targetResumeTitle,
        targetSection: targetSection,
        onApplied: onApplied,
      ),
    );
  }

  @override
  ConsumerState<ApplySummaryModalSheet> createState() =>
      _ApplySummaryModalSheetState();
}

class _ApplySummaryModalSheetState
    extends ConsumerState<ApplySummaryModalSheet> {
  late TextEditingController _editController;
  String _applyMode = 'replace'; // 'replace' or 'note'
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _editController = TextEditingController(text: widget.newContent);
  }

  @override
  void dispose() {
    _editController.dispose();
    super.dispose();
  }

  int _countWords(String text) {
    if (text.trim().isEmpty) return 0;
    return text.trim().split(RegExp(r'\s+')).length;
  }

  void _confirmAndApply() {
    final edited = _editController.text.trim();
    if (edited.isNotEmpty) {
      ref.read(aiProvider.notifier).updateUserEdit(edited);
    }
    ref.read(aiProvider.notifier).applyToResume(mode: _applyMode);
    widget.onApplied?.call();
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final textTheme = Theme.of(context).textTheme;
    final currentText = _editController.text;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.92,
      ),
      decoration: BoxDecoration(
        color: colors.cardBackground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x2E121B2E),
            blurRadius: 32,
            offset: Offset(0, -8),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: colors.mutedBackground,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.description_outlined,
                                size: 14,
                                color: colors.primary,
                              ),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  '${widget.targetResumeTitle} · ${widget.targetSection}',
                                  overflow: TextOverflow.ellipsis,
                                  style: textTheme.labelSmall?.copyWith(
                                    color: colors.textSecondary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Apply this summary to resume?',
                          style: textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: colors.textSecondary),
                    onPressed: () => Navigator.of(context).pop(false),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            // Scrollable diff body
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Diff Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Content Review & Diff',
                          style: textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colors.textPrimary,
                          ),
                        ),
                        Row(
                          children: [
                            Icon(
                              Icons.trending_up,
                              size: 16,
                              color: colors.secondary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '+34% recruiter appeal',
                              style: textTheme.labelSmall?.copyWith(
                                color: colors.secondary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Existing draft card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: colors.screenBackground,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: colors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: colors.border.withValues(alpha: 0.5),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.history,
                                      size: 13,
                                      color: colors.textSecondary,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Existing draft',
                                      style: textTheme.labelSmall?.copyWith(
                                        color: colors.textSecondary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                '${_countWords(widget.existingContent)} words',
                                style: textTheme.labelSmall?.copyWith(
                                  color: colors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            widget.existingContent.isNotEmpty
                                ? widget.existingContent
                                : 'No existing summary found on source resume.',
                            style: textTheme.bodyMedium?.copyWith(
                              color: colors.textSecondary,
                              decoration: widget.existingContent.isNotEmpty
                                  ? TextDecoration.lineThrough
                                  : null,
                              decorationColor: colors.error.withValues(
                                alpha: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Diff replacement connector badge
                    Center(
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: colors.cardBackground,
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: colors.primarySoft),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x0A000000),
                              blurRadius: 4,
                              offset: Offset(0, 1),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.arrow_downward,
                              size: 14,
                              color: colors.primary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'REPLACING WITH AI POLISH',
                              style: textTheme.labelSmall?.copyWith(
                                color: colors.primary,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // New AI-Generated Version Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: colors.mutedBackground,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: colors.primary.withValues(alpha: 0.5),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
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
                                      color: colors.primary,
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.auto_awesome,
                                          size: 13,
                                          color: Colors.white,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Selected new version',
                                          style: textTheme.labelSmall?.copyWith(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (_isEditing ||
                                      currentText != widget.newContent) ...[
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: colors.primarySoft,
                                        borderRadius: BorderRadius.circular(
                                          999,
                                        ),
                                      ),
                                      child: Text(
                                        'Edited by you',
                                        style: textTheme.labelSmall?.copyWith(
                                          color: colors.primary,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              Text(
                                '${_countWords(currentText)} words',
                                style: textTheme.labelSmall?.copyWith(
                                  color: colors.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          if (_isEditing)
                            TextField(
                              controller: _editController,
                              maxLines: 5,
                              onChanged: (_) => setState(() {}),
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: colors.cardBackground,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: colors.primary),
                                ),
                              ),
                            )
                          else
                            Text(
                              currentText,
                              style: textTheme.bodyMedium?.copyWith(
                                color: colors.textPrimary,
                                height: 1.45,
                              ),
                            ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${currentText.length} characters',
                                style: textTheme.bodySmall?.copyWith(
                                  color: colors.textSecondary,
                                ),
                              ),
                              TextButton.icon(
                                icon: Icon(
                                  _isEditing ? Icons.check : Icons.edit,
                                  size: 16,
                                  color: colors.primary,
                                ),
                                label: Text(
                                  _isEditing ? 'Done Editing' : 'Edit Text',
                                  style: TextStyle(
                                    color: colors.primary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                onPressed: () {
                                  setState(() => _isEditing = !_isEditing);
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // How would you like to apply this?
                    Text(
                      'How would you like to apply this?',
                      style: textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Option A: Replace
                    _buildApplyOption(
                      colors,
                      textTheme,
                      value: 'replace',
                      title: 'Replace current summary with this version',
                      subtitle:
                          'Your previous summary will be safely archived in resume version history.',
                      icon: Icons.verified,
                    ),
                    const SizedBox(height: 10),

                    // Option B: Note
                    _buildApplyOption(
                      colors,
                      textTheme,
                      value: 'note',
                      title: 'Save as alternative draft in notes',
                      subtitle:
                          'Keeps existing summary active; stores new text in section notes for later tailoring.',
                      icon: Icons.bookmark_border,
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),

            // Sticky Bottom Action Buttons
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              decoration: BoxDecoration(
                color: colors.cardBackground,
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x10000000),
                    blurRadius: 16,
                    offset: Offset(0, -4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colors.primary,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(0, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 2,
                      ),
                      icon: const Icon(Icons.check, size: 20),
                      label: const Text('Confirm and apply'),
                      onPressed: _confirmAndApply,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildApplyOption(
    AppColors colors,
    TextTheme textTheme, {
    required String value,
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    final isSelected = _applyMode == value;
    return GestureDetector(
      onTap: () => setState(() => _applyMode = value),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected ? colors.mutedBackground : colors.screenBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? colors.primary : colors.border,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 20,
              height: 20,
              margin: const EdgeInsets.only(top: 2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? colors.primary : colors.border,
                  width: isSelected ? 6 : 1.5,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          title,
                          style: textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colors.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(icon, size: 16, color: colors.primary),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: textTheme.bodySmall?.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
