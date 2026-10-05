import 'package:flutter/material.dart';
import '../../../../config/theme.dart';

/// Modal bottom sheet matching Stitch screen 24: Resume Builder — Unsaved Changes Modal.
///
/// Prompts the user when attempting to navigate away from uncommitted form edits,
/// assuring them of already cloud-synced sections and providing clear
/// 'Save draft and leave', 'Keep editing form', and 'Discard' actions.
class UnsavedChangesModal extends StatelessWidget {
  const UnsavedChangesModal({
    super.key,
    this.sectionName = 'Personal details',
    required this.onSaveDraftAndLeave,
    required this.onDiscardChanges,
    this.onKeepEditing,
    this.isSaving = false,
  });

  final String sectionName;
  final Future<void> Function() onSaveDraftAndLeave;
  final VoidCallback onDiscardChanges;
  final VoidCallback? onKeepEditing;
  final bool isSaving;

  static Future<bool?> show(
    BuildContext context, {
    String sectionName = 'Personal details',
    required Future<void> Function() onSaveDraftAndLeave,
    required VoidCallback onDiscardChanges,
    VoidCallback? onKeepEditing,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => UnsavedChangesModal(
        sectionName: sectionName,
        onSaveDraftAndLeave: onSaveDraftAndLeave,
        onDiscardChanges: onDiscardChanges,
        onKeepEditing: onKeepEditing,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF121B2E).withValues(alpha: 0.16),
            blurRadius: 32,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag Handle
          Center(
            child: Container(
              width: 44,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: colors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header with Icon
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: colors.surfaceContainer,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Icon(Icons.edit_document, color: colors.primary, size: 26),
                    Positioned(
                      top: 4,
                      right: 4,
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: colors.secondary,
                          shape: BoxShape.circle,
                          border: Border.all(color: colors.surface, width: 1.5),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Unsaved changes',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'You modified $sectionName. What would you like to do before navigating away?',
                      style: TextStyle(
                        fontSize: 13,
                        color: colors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Recent Document Activity Tracker
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.surfaceContainer,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Recent document activity',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: colors.textSecondary,
                      ),
                    ),
                    Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: colors.secondary,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Draft in memory',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: colors.secondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: colors.surface,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.verified,
                              size: 16,
                              color: colors.secondary,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'Experience & Skills',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: colors.textPrimary,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: colors.surface,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.cloud_done,
                              size: 16,
                              color: colors.secondary,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'Cloud Synced',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: colors.textPrimary,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // Primary: Save draft and leave
          SizedBox(
            height: 48,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              onPressed: isSaving
                  ? null
                  : () async {
                      Navigator.of(context).pop(true);
                      await onSaveDraftAndLeave();
                    },
              icon: isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.save, size: 18),
              label: const Text(
                'Save draft and leave',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Secondary: Keep editing form
          SizedBox(
            height: 44,
            child: TextButton.icon(
              style: TextButton.styleFrom(
                backgroundColor: colors.surfaceContainer,
                foregroundColor: colors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop(false);
                onKeepEditing?.call();
              },
              icon: const Icon(Icons.edit, size: 16),
              label: const Text(
                'Keep editing form',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ),
          ),
          const SizedBox(height: 4),

          // Tertiary: Discard changes
          SizedBox(
            height: 40,
            child: TextButton.icon(
              style: TextButton.styleFrom(foregroundColor: colors.error),
              onPressed: () {
                Navigator.of(context).pop(false);
                onDiscardChanges();
              },
              icon: const Icon(Icons.delete_sweep, size: 16),
              label: Text(
                'Discard $sectionName changes',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
