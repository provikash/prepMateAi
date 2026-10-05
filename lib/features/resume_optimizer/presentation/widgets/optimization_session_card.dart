import 'package:flutter/material.dart';
import '../../../../config/theme.dart';
import '../../domain/optimization_models.dart';

/// Screen 36: Optimization History — Status Variants
///
/// Reusable card displaying an optimization run with exhaustive mapping
/// across all 12 states (Draft, Queued, Analyzing, Suggestions Ready,
/// Editing, Ready to Export, Completed, Needs Attention, Failed, Cancelled,
/// Expired, Archived).
class OptimizationSessionCard extends StatelessWidget {
  const OptimizationSessionCard({
    super.key,
    required this.session,
    required this.onTap,
    this.onPrimaryAction,
    this.onRename,
    this.onDuplicate,
    this.onArchive,
    this.onDelete,
  });

  final OptimizationSessionModel session;
  final VoidCallback onTap;
  final VoidCallback? onPrimaryAction;
  final VoidCallback? onRename;
  final VoidCallback? onDuplicate;
  final VoidCallback? onArchive;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final textTheme = Theme.of(context).textTheme;
    final statusConfig = _getStatusConfig(session.status, colors);

    final roleTitle = session.jobDescription?.title.isNotEmpty == true
        ? session.jobDescription!.title
        : 'Target Role Optimization';
    final companyName = session.jobDescription?.company.isNotEmpty == true
        ? session.jobDescription!.company
        : 'Company Unspecified';
    final resumeTitle = session.sourceResumeTitle.isNotEmpty
        ? session.sourceResumeTitle
        : 'Resume Document';

    // Decision metrics
    final accepted = session.decisionCounts['accepted'] ?? 0;
    final edited = session.decisionCounts['edited'] ?? 0;
    final totalSuggestions = session.suggestions.isNotEmpty
        ? session.suggestions.length
        : (session.decisionCounts.values.fold(0, (a, b) => a + b));
    final reviewedCount =
        accepted + edited + (session.decisionCounts['rejected'] ?? 0);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: colors.cardBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top glowing indicator for active/analyzing jobs
              if (session.status.toUpperCase() == 'ANALYZING' ||
                  session.status.toUpperCase() == 'APPLYING') ...[
                LinearProgressIndicator(
                  minHeight: 3,
                  backgroundColor: colors.primary.withValues(alpha: 0.2),
                  color: colors.primary,
                ),
              ],

              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header: Status Badge + Updated Time + Overflow Menu
                    Row(
                      children: [
                        // Status Badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: statusConfig.backgroundColor,
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: statusConfig.foregroundColor.withValues(
                                alpha: 0.2,
                              ),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                statusConfig.icon,
                                size: 13,
                                color: statusConfig.foregroundColor,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                statusConfig.label,
                                style: textTheme.labelSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: statusConfig.foregroundColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _formatRelativeTime(
                            session.updatedAt ?? session.createdAt,
                          ),
                          style: textTheme.bodySmall?.copyWith(
                            color: colors.textSecondary,
                            fontSize: 11,
                          ),
                        ),
                        const Spacer(),
                        PopupMenuButton<String>(
                          icon: Icon(
                            Icons.more_vert,
                            size: 20,
                            color: colors.textSecondary,
                          ),
                          onSelected: (val) {
                            switch (val) {
                              case 'rename':
                                onRename?.call();
                                break;
                              case 'duplicate':
                                onDuplicate?.call();
                                break;
                              case 'archive':
                                onArchive?.call();
                                break;
                              case 'delete':
                                onDelete?.call();
                                break;
                            }
                          },
                          itemBuilder: (ctx) => [
                            const PopupMenuItem(
                              value: 'rename',
                              child: Row(
                                children: [
                                  Icon(Icons.edit_outlined, size: 18),
                                  SizedBox(width: 10),
                                  Text('Rename'),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'duplicate',
                              child: Row(
                                children: [
                                  Icon(Icons.copy_outlined, size: 18),
                                  SizedBox(width: 10),
                                  Text('Duplicate Setup'),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'archive',
                              child: Row(
                                children: [
                                  Icon(Icons.archive_outlined, size: 18),
                                  SizedBox(width: 10),
                                  Text('Archive'),
                                ],
                              ),
                            ),
                            const PopupMenuDivider(),
                            PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.delete_outline,
                                    size: 18,
                                    color: colors.error,
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    'Delete',
                                    style: TextStyle(color: colors.error),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Role Title
                    Text(
                      roleTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),

                    // Company & Source Resume Meta
                    Row(
                      children: [
                        Icon(
                          Icons.domain,
                          size: 14,
                          color: colors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            companyName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: textTheme.bodySmall?.copyWith(
                              color: colors.textSecondary,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          child: Text(
                            '•',
                            style: TextStyle(color: colors.border),
                          ),
                        ),
                        Icon(
                          Icons.description_outlined,
                          size: 14,
                          color: colors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            resumeTitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: textTheme.bodySmall?.copyWith(
                              color: colors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),

                    // Progress / Suggestions Section if applicable
                    if (totalSuggestions > 0) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: colors.mutedBackground,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '$totalSuggestions suggestions generated',
                                  style: textTheme.bodySmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: colors.textPrimary,
                                    fontSize: 11,
                                  ),
                                ),
                                Text(
                                  '$reviewedCount reviewed',
                                  style: textTheme.bodySmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: colors.primary,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(99),
                              child: LinearProgressIndicator(
                                value: totalSuggestions > 0
                                    ? (reviewedCount / totalSuggestions).clamp(
                                        0.0,
                                        1.0,
                                      )
                                    : 0.0,
                                minHeight: 6,
                                backgroundColor: colors.border,
                                color: colors.secondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 12),

                    // Bottom Row: Secondary note & Contextual Primary Action
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Secondary note
                        Row(
                          children: [
                            Icon(
                              statusConfig.accentIcon,
                              size: 14,
                              color: statusConfig.accentColor,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              statusConfig.accentText,
                              style: textTheme.labelSmall?.copyWith(
                                color: statusConfig.accentColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),

                        // Action button
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: onPrimaryAction ?? onTap,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                statusConfig.actionLabel,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(Icons.arrow_forward, size: 14),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  _StatusCardConfig _getStatusConfig(String status, AppColors colors) {
    final s = status.toUpperCase();
    switch (s) {
      case 'DRAFT':
        return _StatusCardConfig(
          label: 'Draft',
          icon: Icons.edit_note,
          backgroundColor: colors.mutedBackground,
          foregroundColor: colors.textSecondary,
          accentText: 'Setup Incomplete',
          accentColor: colors.textSecondary,
          accentIcon: Icons.info_outline,
          actionLabel: 'Continue Setup',
        );
      case 'QUEUED':
        return _StatusCardConfig(
          label: 'Queued',
          icon: Icons.hourglass_top,
          backgroundColor: const Color(0xFFFEF3C7),
          foregroundColor: const Color(0xFFB45309),
          accentText: 'In Escrow (3 cr)',
          accentColor: const Color(0xFFB45309),
          accentIcon: Icons.lock_clock,
          actionLabel: 'View Status',
        );
      case 'ANALYZING':
      case 'MATCHING':
        return _StatusCardConfig(
          label: 'Analyzing',
          icon: Icons.sync,
          backgroundColor: const Color(0xFFDBEAFE),
          foregroundColor: const Color(0xFF1D4ED8),
          accentText: 'Processing rubric...',
          accentColor: const Color(0xFF1D4ED8),
          accentIcon: Icons.psychology,
          actionLabel: 'View Progress',
        );
      case 'ANALYZED':
      case 'READY_FOR_REVIEW':
      case 'SUGGESTIONS_READY':
        return _StatusCardConfig(
          label: 'Suggestions Ready',
          icon: Icons.auto_awesome,
          backgroundColor: const Color(0xFFEDE9FE),
          foregroundColor: const Color(0xFF6D28D9),
          accentText: '+18% ATS boost expected',
          accentColor: colors.secondary,
          accentIcon: Icons.bolt,
          actionLabel: 'Review suggestions',
        );
      case 'EDITING':
        return _StatusCardConfig(
          label: 'Review in Progress',
          icon: Icons.rate_review,
          backgroundColor: const Color(0xFFE0E7FF),
          foregroundColor: const Color(0xFF3730A3),
          accentText: 'Resume when ready',
          accentColor: colors.primary,
          accentIcon: Icons.pending_actions,
          actionLabel: 'Continue Review',
        );
      case 'READY_TO_EXPORT':
      case 'APPLYING':
      case 'GENERATING_PDF':
        return _StatusCardConfig(
          label: 'Ready to Export',
          icon: Icons.task_alt,
          backgroundColor: const Color(0xFFD1FAE5),
          foregroundColor: const Color(0xFF047857),
          accentText: 'Resume optimized',
          accentColor: const Color(0xFF047857),
          accentIcon: Icons.verified,
          actionLabel: 'Preview PDF',
        );
      case 'COMPLETED':
        return _StatusCardConfig(
          label: 'Completed',
          icon: Icons.check_circle,
          backgroundColor: const Color(0xFFD1FAE5),
          foregroundColor: const Color(0xFF047857),
          accentText: 'ATS Calibrated',
          accentColor: const Color(0xFF047857),
          accentIcon: Icons.verified_user,
          actionLabel: 'View Details',
        );
      case 'FAILED':
        return _StatusCardConfig(
          label: 'Failed',
          icon: Icons.error_outline,
          backgroundColor: const Color(0xFFFEE2E2),
          foregroundColor: const Color(0xFFB91C1C),
          accentText: 'Credits refunded',
          accentColor: const Color(0xFFB91C1C),
          accentIcon: Icons.refresh,
          actionLabel: 'Retry Analysis',
        );
      case 'CANCELLED':
      case 'ARCHIVED':
        return _StatusCardConfig(
          label: 'Archived',
          icon: Icons.archive_outlined,
          backgroundColor: colors.mutedBackground,
          foregroundColor: colors.textSecondary,
          accentText: 'Inactive run',
          accentColor: colors.textSecondary,
          accentIcon: Icons.inventory_2_outlined,
          actionLabel: 'Restore',
        );
      default:
        return _StatusCardConfig(
          label: 'Needs Attention',
          icon: Icons.warning_amber,
          backgroundColor: const Color(0xFFFEF3C7),
          foregroundColor: const Color(0xFFB45309),
          accentText: 'Action required',
          accentColor: const Color(0xFFB45309),
          accentIcon: Icons.flag,
          actionLabel: 'Resolve Issues',
        );
    }
  }

  String _formatRelativeTime(DateTime? dt) {
    if (dt == null) return 'Recently';
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'Yesterday';
    return '${diff.inDays}d ago';
  }
}

class _StatusCardConfig {
  const _StatusCardConfig({
    required this.label,
    required this.icon,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.accentText,
    required this.accentColor,
    required this.accentIcon,
    required this.actionLabel,
  });

  final String label;
  final IconData icon;
  final Color backgroundColor;
  final Color foregroundColor;
  final String accentText;
  final Color accentColor;
  final IconData accentIcon;
  final String actionLabel;
}
