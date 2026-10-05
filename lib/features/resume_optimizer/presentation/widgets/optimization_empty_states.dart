import 'package:flutter/material.dart';
import '../../../../config/theme.dart';

/// Screen 38: Optimization History — Search and Empty States
class OptimizationZeroState extends StatelessWidget {
  const OptimizationZeroState({
    super.key,
    required this.onStartOptimization,
    this.onHowItWorks,
  });

  final VoidCallback onStartOptimization;
  final VoidCallback? onHowItWorks;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final textTheme = Theme.of(context).textTheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Column(
        children: [
          // Illustration / Icon Hero
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: colors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.auto_awesome, size: 48, color: colors.primary),
          ),
          const SizedBox(height: 20),

          // Title & Subtitle
          Text(
            'Optimize your resume for any target job',
            textAlign: TextAlign.center,
            style: textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Upload your resume and paste a job description. PrepMate AI aligns your qualifications, recommends high-impact keywords, and optimizes for ATS filters.',
            textAlign: TextAlign.center,
            style: textTheme.bodyMedium?.copyWith(
              color: colors.textSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),

          // Credit transparency card
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: colors.mutedBackground,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: colors.border),
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: colors.cardBackground,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.token, color: colors.primary, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Transparent Credits',
                        style: textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Each optimization uses 3 AI credits only after you confirm submission.',
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
          const SizedBox(height: 24),

          // Action buttons
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              onPressed: onStartOptimization,
              icon: const Icon(Icons.auto_awesome, size: 20),
              label: const Text(
                'Start your first optimization',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: onHowItWorks,
            icon: Icon(Icons.help_outline, size: 18, color: colors.primary),
            label: Text(
              'How optimization works',
              style: TextStyle(
                color: colors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Pro tip card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colors.mutedBackground,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Pro tip from PrepMate',
                      style: textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colors.textPrimary,
                      ),
                    ),
                    Icon(Icons.lightbulb, color: colors.secondary, size: 18),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Upload resumes in PDF format with recognizable work experience sections. Job descriptions paste directly from LinkedIn, Indeed, or Greenhouse for highest match precision.',
                  style: textTheme.bodySmall?.copyWith(
                    color: colors.textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class OptimizationNoSearchResultsState extends StatelessWidget {
  const OptimizationNoSearchResultsState({
    super.key,
    required this.query,
    required this.onClearSearch,
    required this.onViewAll,
  });

  final String query;
  final VoidCallback onClearSearch;
  final VoidCallback onViewAll;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: colors.mutedBackground,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.manage_search,
                size: 40,
                color: colors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'No matching sessions found',
              textAlign: TextAlign.center,
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'We couldn’t find any optimization sessions matching "$query". Try searching by resume title, company, or clearing active filters.',
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium?.copyWith(
                color: colors.textSecondary,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: colors.textPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: onClearSearch,
                    child: const Text('Clear search'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: onViewAll,
                    child: const Text('View all sessions'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
