import 'package:flutter/material.dart';
import '../../../../config/theme.dart';

/// Screen 53: Suggestion Editor Edge States & Recovery Modals
///
/// Provides:
/// 1. RestoredDraftBanner
/// 2. FactConflictAlertBanner
/// 3. ResumeVersionMismatchBanner
/// 4. OfflineNoticeBanner
/// 5. LeaveEditorConfirmationDialog
class RestoredDraftBanner extends StatelessWidget {
  const RestoredDraftBanner({
    super.key,
    required this.onKeepEditing,
    required this.onDiscardDraft,
  });

  final VoidCallback onKeepEditing;
  final VoidCallback onDiscardDraft;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: colors.primary.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: colors.primarySoft,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.restore_page,
                  color: colors.primary,
                  size: 16,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Auto-Recovered Draft Session',
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              Text(
                '10m ago',
                style: TextStyle(
                  fontSize: 11,
                  color: colors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Your unsaved edits from earlier were safely restored from local draft memory.',
            style: TextStyle(fontSize: 12, color: colors.textSecondary),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: onDiscardDraft,
                child: const Text('Discard draft'),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: onKeepEditing,
                child: const Text('Keep editing'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class FactConflictAlertBanner extends StatelessWidget {
  const FactConflictAlertBanner({
    super.key,
    required this.claimText,
    required this.explanation,
    required this.onResolve,
  });

  final String claimText;
  final String explanation;
  final VoidCallback onResolve;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: const Color(0xFFFFDAD6).withOpacity(0.4),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: const Color(0xFFBA1A1A).withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFDAD6),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: const Text(
                  'Integrity Guard',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFBA1A1A),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              const Text(
                'Potential Fact Conflict',
                style: TextStyle(
                  fontSize: 11,
                  color: Color(0xFFBA1A1A),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Unsupported Claim: “$claimText”',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: Color(0xFF172033),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            explanation,
            style: const TextStyle(fontSize: 12, color: Color(0xFF434654)),
          ),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: onResolve,
              icon: const Icon(Icons.edit, size: 14),
              label: const Text('Modify Claim'),
            ),
          ),
        ],
      ),
    );
  }
}

class ResumeVersionMismatchBanner extends StatelessWidget {
  const ResumeVersionMismatchBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF4E5),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: const Color(0xFFA15C00).withOpacity(0.3)),
      ),
      child: Row(
        children: const [
          Icon(Icons.history_toggle_off, color: Color(0xFFA15C00), size: 20),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Resume Changed: Your master resume has recent edits since this snapshot was created. Edits will apply to the optimized branch.',
              style: TextStyle(fontSize: 12, color: Color(0xFF172033)),
            ),
          ),
        ],
      ),
    );
  }
}

class LeaveEditorConfirmationDialog extends StatelessWidget {
  const LeaveEditorConfirmationDialog({
    super.key,
    required this.onSaveDraft,
    required this.onDiscard,
    required this.onKeepEditing,
  });

  final VoidCallback onSaveDraft;
  final VoidCallback onDiscard;
  final VoidCallback onKeepEditing;

  static Future<bool> show(
    BuildContext context, {
    required VoidCallback onSaveDraft,
    required VoidCallback onDiscard,
    required VoidCallback onKeepEditing,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => LeaveEditorConfirmationDialog(
        onSaveDraft: onSaveDraft,
        onDiscard: onDiscard,
        onKeepEditing: onKeepEditing,
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text('Leave with unsaved edits?'),
      content: const Text(
        'You have edited this suggestion. Would you like to save your working draft or discard the recent changes?',
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context, false);
            onDiscard();
          },
          child: const Text(
            'Discard Edits',
            style: TextStyle(color: Color(0xFFBA1A1A)),
          ),
        ),
        TextButton(
          onPressed: () {
            Navigator.pop(context, false);
            onKeepEditing();
          },
          child: const Text('Keep Editing'),
        ),
        FilledButton(
          onPressed: () {
            Navigator.pop(context, true);
            onSaveDraft();
          },
          child: const Text('Save Working Draft'),
        ),
      ],
    );
  }
}
