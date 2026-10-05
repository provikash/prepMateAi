import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../config/theme.dart';
import '../../domain/optimization_models.dart';
import '../providers/optimization_sessions_provider.dart';
import '../widgets/optimization_detail_sheets.dart';

/// Screen 42: Optimization Detail — Completed
/// Incorporates Screen 40 (Source Inspection Sheets) and
/// Screen 41 (Status Variants & Recovery).
class OptimizationDetailScreen extends ConsumerWidget {
  const OptimizationDetailScreen({super.key, required this.sessionId});

  final String sessionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = AppColors.of(context);
    final textTheme = Theme.of(context).textTheme;
    final sessionAsync = ref.watch(optimizationDetailProvider(sessionId));

    return Scaffold(
      backgroundColor: colors.screenBackground,
      appBar: AppBar(
        backgroundColor: colors.cardBackground,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Optimization Overview',
          style: textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: colors.textPrimary,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: colors.textPrimary),
            onPressed: () =>
                ref.invalidate(optimizationDetailProvider(sessionId)),
          ),
        ],
      ),
      body: sessionAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline, size: 48, color: colors.error),
                const SizedBox(height: 12),
                Text(
                  'Session Not Found',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'We could not load the details for this optimization session.',
                  textAlign: TextAlign.center,
                  style: textTheme.bodySmall?.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.primary,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () =>
                      ref.invalidate(optimizationDetailProvider(sessionId)),
                  child: const Text('Try Again'),
                ),
              ],
            ),
          ),
        ),
        data: (session) {
          final isCompleted = session.status.toUpperCase() == 'COMPLETED';
          final isAnalyzing =
              session.status.toUpperCase() == 'ANALYZING' ||
              session.status.toUpperCase() == 'MATCHING';
          final isFailed = session.status.toUpperCase() == 'FAILED';
          final isDraft = session.status.toUpperCase() == 'DRAFT';

          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Context Cards: Source Resume & Job Description
                      _buildContextCard(context, session, colors, textTheme),
                      const SizedBox(height: 14),

                      // Status View: Completed or Recovery
                      if (isCompleted) ...[
                        _buildCompletedStatusBanner(
                          context,
                          session,
                          colors,
                          textTheme,
                        ),
                        const SizedBox(height: 14),
                        _buildWorkflowTimeline(session, colors, textTheme),
                        const SizedBox(height: 14),
                        _buildJobAnalysisSnapshot(session, colors, textTheme),
                        const SizedBox(height: 14),
                        _buildDecisionsCard(session, colors, textTheme),
                        const SizedBox(height: 14),
                        _buildCreditActivityCard(
                          context,
                          session,
                          colors,
                          textTheme,
                        ),
                      ] else if (isAnalyzing) ...[
                        _buildAnalyzingRecoveryView(
                          context,
                          session,
                          colors,
                          textTheme,
                        ),
                      ] else if (isFailed) ...[
                        _buildFailedRecoveryView(
                          context,
                          session,
                          colors,
                          textTheme,
                          ref,
                        ),
                      ] else if (isDraft) ...[
                        _buildDraftRecoveryView(
                          context,
                          session,
                          colors,
                          textTheme,
                        ),
                      ] else ...[
                        _buildDefaultStatusView(
                          context,
                          session,
                          colors,
                          textTheme,
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              // Sticky Bottom Action Bar
              if (isCompleted) ...[
                _buildStickyBottomBar(context, session, colors),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildContextCard(
    BuildContext context,
    OptimizationSessionModel session,
    AppColors colors,
    TextTheme textTheme,
  ) {
    final jd = session.jobDescription;
    return Container(
      decoration: BoxDecoration(
        color: colors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        children: [
          // Resume row
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: colors.mutedBackground,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.description,
                    color: colors.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        session.sourceResumeTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colors.textPrimary,
                        ),
                      ),
                      Text(
                        'Baseline profile version v${session.sourceResumeVersion}',
                        style: textTheme.bodySmall?.copyWith(
                          color: colors.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () =>
                      SourceResumeVersionSheet.show(context, session: session),
                  child: const Text(
                    'View source',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Job description row
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: colors.mutedBackground,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.link, color: colors.secondary, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        jd != null && jd.title.isNotEmpty
                            ? jd.title
                            : 'Target Job Posting',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colors.textPrimary,
                        ),
                      ),
                      Text(
                        jd != null && jd.company.isNotEmpty
                            ? jd.company
                            : 'Target Company',
                        style: textTheme.bodySmall?.copyWith(
                          color: colors.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                if (jd != null)
                  TextButton(
                    onPressed: () => JobDescriptionInspectionSheet.show(
                      context,
                      jobDescription: jd,
                    ),
                    child: const Text(
                      'View details',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompletedStatusBanner(
    BuildContext context,
    OptimizationSessionModel session,
    AppColors colors,
    TextTheme textTheme,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFD1FAE5).withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF047857).withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.check_circle,
                color: Color(0xFF047857),
                size: 24,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Optimization complete',
                      style: textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF047857),
                      ),
                    ),
                    Text(
                      'Ready for interview dispatch',
                      style: textTheme.bodySmall?.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'All reviewed changes have been merged into an optimized resume version calibrated specifically for ${session.jobDescription?.company ?? "your target job"}.',
            style: textTheme.bodySmall?.copyWith(
              color: colors.textPrimary,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkflowTimeline(
    OptimizationSessionModel session,
    AppColors colors,
    TextTheme textTheme,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.cardBackground,
        borderRadius: BorderRadius.circular(16),
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
                  Icon(Icons.route, color: colors.primary, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Workflow Timeline',
                    style: textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colors.textPrimary,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFD1FAE5),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Text(
                  '5 / 5 Complete',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF047857),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildTimelineStep(
            '1. Setup',
            'Resume & job posting matched',
            colors,
            isLast: false,
          ),
          _buildTimelineStep(
            '2. Job Analysis',
            'Core requirements identified · 92% alignment',
            colors,
            isLast: false,
          ),
          _buildTimelineStep(
            '3. Suggestions',
            'AI Polish suggestions generated',
            colors,
            isLast: false,
          ),
          _buildTimelineStep(
            '4. Review Changes',
            'User validated and confirmed factual claims',
            colors,
            isLast: false,
          ),
          _buildTimelineStep(
            '5. Optimized Resume',
            'Calibrated deliverable version created',
            colors,
            isLast: true,
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineStep(
    String title,
    String subtitle,
    AppColors colors, {
    required bool isLast,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 22,
              height: 22,
              decoration: const BoxDecoration(
                color: Color(0xFF047857),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check, size: 14, color: Colors.white),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 28,
                color: const Color(0xFF047857).withValues(alpha: 0.3),
              ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(fontSize: 11, color: colors.textSecondary),
              ),
              if (!isLast) const SizedBox(height: 10),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildJobAnalysisSnapshot(
    OptimizationSessionModel session,
    AppColors colors,
    TextTheme textTheme,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Job Analysis Snapshot',
            style: textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),

          // Alignment gauge row
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.mutedBackground,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: colors.primary,
                  child: const Text(
                    '92%',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Resume-to-Job Alignment',
                        style: textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colors.textPrimary,
                        ),
                      ),
                      Text(
                        'Evaluated against core requirements in posting',
                        style: textTheme.bodySmall?.copyWith(
                          color: colors.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Strengths
          Text(
            'Key Strengths & Matched Requirements',
            style: textTheme.labelSmall?.copyWith(
              color: colors.textSecondary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _buildTag('Flutter & Dart', colors.secondary, colors),
              _buildTag('REST APIs & WebSocket', colors.secondary, colors),
              _buildTag('Clean Architecture', colors.secondary, colors),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTag(String text, Color accentColor, AppColors colors) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: accentColor.withValues(alpha: 0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: accentColor,
        ),
      ),
    );
  }

  Widget _buildDecisionsCard(
    OptimizationSessionModel session,
    AppColors colors,
    TextTheme textTheme,
  ) {
    final accepted = session.decisionCounts['accepted'] ?? 6;
    final edited = session.decisionCounts['edited'] ?? 2;
    final skipped = session.decisionCounts['rejected'] ?? 3;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Suggestion Decisions',
            style: textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildCounterPill(
                'Accepted',
                '$accepted',
                colors.secondary,
                colors,
              ),
              const SizedBox(width: 8),
              _buildCounterPill('Edited', '$edited', colors.primary, colors),
              const SizedBox(width: 8),
              _buildCounterPill(
                'Skipped',
                '$skipped',
                colors.textSecondary,
                colors,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCounterPill(
    String label,
    String count,
    Color color,
    AppColors colors,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: colors.mutedBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colors.border),
        ),
        child: Column(
          children: [
            Text(
              count,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(fontSize: 11, color: colors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCreditActivityCard(
    BuildContext context,
    OptimizationSessionModel session,
    AppColors colors,
    TextTheme textTheme,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          Icon(Icons.receipt_long, color: colors.primary, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Credit Activity',
                  style: textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colors.textPrimary,
                  ),
                ),
                Text(
                  '10 credits charged · Escrow released',
                  style: textTheme.bodySmall?.copyWith(
                    color: colors.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () =>
                CreditActivityInspectionSheet.show(context, session: session),
            child: const Text('View Activity', style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _buildStickyBottomBar(
    BuildContext context,
    OptimizationSessionModel session,
    AppColors colors,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.cardBackground,
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 10,
            offset: Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: () {
                  context.push('/resume/optimize/preview');
                },
                icon: const Icon(Icons.picture_as_pdf, size: 18),
                label: const Text('Preview PDF'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: () {
                  context.push('/resume/optimize/summary');
                },
                icon: const Icon(Icons.auto_awesome, size: 18),
                label: const Text('Open Summary'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Screen 41: Recovery & Status Variants ---

  Widget _buildAnalyzingRecoveryView(
    BuildContext context,
    OptimizationSessionModel session,
    AppColors colors,
    TextTheme textTheme,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2.5),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Deep Rubric Match in Progress',
                      style: textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colors.textPrimary,
                      ),
                    ),
                    Text(
                      'Comparing qualifications against target rubric',
                      style: textTheme.bodySmall?.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              minHeight: 6,
              color: colors.primary,
              backgroundColor: colors.border,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.mutedBackground,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.verified_user, color: colors.secondary, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Safe to navigate away. Updates run safely in the background. Credits are held in escrow until completed.',
                    style: textTheme.bodySmall?.copyWith(
                      color: colors.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFailedRecoveryView(
    BuildContext context,
    OptimizationSessionModel session,
    AppColors colors,
    TextTheme textTheme,
    WidgetRef ref,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFEE2E2).withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFB91C1C).withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.error_outline,
                color: Color(0xFFB91C1C),
                size: 24,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Analysis Interrupted',
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFFB91C1C),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'The AI optimization could not be finalized. No credits were deducted and reserved credits have been fully refunded to your balance.',
            style: textTheme.bodySmall?.copyWith(
              color: colors.textPrimary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () {
              context.push('/resume/optimize');
            },
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('Restart Optimization'),
          ),
        ],
      ),
    );
  }

  Widget _buildDraftRecoveryView(
    BuildContext context,
    OptimizationSessionModel session,
    AppColors colors,
    TextTheme textTheme,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Setup Incomplete',
            style: textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'This optimization draft is missing complete job details or confirmation. Continue setup to generate AI polish suggestions.',
            style: textTheme.bodySmall?.copyWith(color: colors.textSecondary),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () {
              context.push('/resume/optimize');
            },
            icon: const Icon(Icons.arrow_forward, size: 18),
            label: const Text('Continue Setup'),
          ),
        ],
      ),
    );
  }

  Widget _buildDefaultStatusView(
    BuildContext context,
    OptimizationSessionModel session,
    AppColors colors,
    TextTheme textTheme,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Status: ${session.status}',
            style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () => context.push('/resume/optimize/suggestions'),
            child: const Text('Review Workspace'),
          ),
        ],
      ),
    );
  }
}
