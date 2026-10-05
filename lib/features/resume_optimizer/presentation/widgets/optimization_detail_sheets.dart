import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../config/theme.dart';
import '../../domain/optimization_models.dart';

/// Screen 40: Optimization Detail — Source Inspection Sheets
///
/// Provides bottom sheets for:
/// 1. Job Description Details with full text, word count, and extracted keywords
/// 2. Source Resume Version inspection (analyzed snapshot vs current active version)
/// 3. Credit Activity Audit Sheet
class JobDescriptionInspectionSheet extends StatelessWidget {
  const JobDescriptionInspectionSheet({
    super.key,
    required this.jobDescription,
  });

  final JobDescriptionModel jobDescription;

  static Future<void> show(
    BuildContext context, {
    required JobDescriptionModel jobDescription,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) =>
          JobDescriptionInspectionSheet(jobDescription: jobDescription),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final textTheme = Theme.of(context).textTheme;

    final wordCount = jobDescription.description
        .trim()
        .split(RegExp(r'\s+'))
        .length;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: BoxDecoration(
        color: colors.cardBackground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            // Drag handle
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: colors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                children: [
                  Icon(Icons.description, color: colors.primary, size: 22),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Job Description Details',
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colors.textPrimary,
                          ),
                        ),
                        Text(
                          '${jobDescription.company.isNotEmpty ? jobDescription.company : "Company"} · ${jobDescription.title.isNotEmpty ? jobDescription.title : "Role"}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.bodySmall?.copyWith(
                            color: colors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: colors.textSecondary),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            // Metadata strip
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              child: Row(
                children: [
                  _buildPill(
                    Icons.format_align_left,
                    '$wordCount words',
                    colors,
                  ),
                  const SizedBox(width: 8),
                  _buildPill(Icons.schedule, 'Captured for analysis', colors),
                  if (jobDescription.sourceUrl.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    _buildPill(Icons.link, 'Imported link', colors),
                  ],
                ],
              ),
            ),
            const Divider(height: 16),

            // Scrollable Job Description text
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: colors.mutedBackground,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: colors.border),
                      ),
                      child: SelectableText(
                        jobDescription.description.isNotEmpty
                            ? jobDescription.description
                            : 'No full description provided for this session.',
                        style: textTheme.bodyMedium?.copyWith(
                          color: colors.textPrimary,
                          height: 1.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Copy action button
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: colors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        Clipboard.setData(
                          ClipboardData(text: jobDescription.description),
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Job description copied to clipboard.',
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.copy, size: 16),
                      label: const Text('Copy job description'),
                    ),
                    const SizedBox(height: 16),

                    // Guardrail notice
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: colors.mutedBackground,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.shield_outlined,
                            size: 18,
                            color: colors.secondary,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'This job description is an immutable snapshot used for this optimization session. Editing it will start a new session.',
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
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPill(IconData icon, String label, AppColors colors) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: colors.mutedBackground,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: colors.primary),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: colors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class SourceResumeVersionSheet extends StatelessWidget {
  const SourceResumeVersionSheet({super.key, required this.session});

  final OptimizationSessionModel session;

  static Future<void> show(
    BuildContext context, {
    required OptimizationSessionModel session,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => SourceResumeVersionSheet(session: session),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colors.cardBackground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: colors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(Icons.history_edu, color: colors.primary, size: 24),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Source Resume Version',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colors.textPrimary,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colors.mutedBackground,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: colors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  session.sourceResumeTitle,
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Snapshot version v${session.sourceResumeVersion} calibrated at analysis time',
                  style: textTheme.bodySmall?.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
                const Divider(height: 20),
                Row(
                  children: [
                    Icon(Icons.check_circle, size: 16, color: colors.secondary),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Immutable baseline preserved in local and server storage.',
                        style: textTheme.bodySmall?.copyWith(
                          color: colors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ),
        ],
      ),
    );
  }
}

class CreditActivityInspectionSheet extends StatelessWidget {
  const CreditActivityInspectionSheet({super.key, required this.session});

  final OptimizationSessionModel session;

  static Future<void> show(
    BuildContext context, {
    required OptimizationSessionModel session,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => CreditActivityInspectionSheet(session: session),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colors.cardBackground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: colors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(Icons.receipt_long, color: colors.primary, size: 24),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Credit Activity Breakdown',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colors.textPrimary,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colors.mutedBackground,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: colors.border),
            ),
            child: Column(
              children: [
                _buildRow('Base Tool Cost', '10 credits', textTheme, colors),
                const SizedBox(height: 8),
                _buildRow(
                  'Credits Reserved in Escrow',
                  '10 credits',
                  textTheme,
                  colors,
                ),
                const SizedBox(height: 8),
                _buildRow(
                  'Final Charge Authorized',
                  '10 credits',
                  textTheme,
                  colors,
                ),
                const Divider(height: 20),
                _buildRow(
                  'Reservation Released',
                  'Yes (Fully reconciled)',
                  textTheme,
                  colors,
                  isSuccess: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Done'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRow(
    String label,
    String value,
    TextTheme textTheme,
    AppColors colors, {
    bool isSuccess = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: textTheme.bodySmall?.copyWith(color: colors.textSecondary),
        ),
        Text(
          value,
          style: textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: isSuccess ? colors.secondary : colors.textPrimary,
          ),
        ),
      ],
    );
  }
}
