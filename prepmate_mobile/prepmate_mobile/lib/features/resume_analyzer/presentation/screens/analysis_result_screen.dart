import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../config/theme.dart';
import '../../data/models/resume_analysis_model.dart';

class AnalysisResultScreen extends ConsumerWidget {
  final ResumeAnalysisModel analysis;

  const AnalysisResultScreen({super.key, required this.analysis});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = AppColors.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: colors.screenBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Analysis Result',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: colors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildScoreOverview(colors, isDark),
            const SizedBox(height: 32),
            _buildMetricsGrid(colors, isDark),
            const SizedBox(height: 32),
            _buildBreakdownSection(colors, isDark),
            const SizedBox(height: 32),
            _buildSection(
              colors: colors,
              isDark: isDark,
              title: 'Strengths',
              icon: Icons.auto_awesome,
              iconColor: Colors.green,
              items: _getStrengths(),
            ),
            const SizedBox(height: 16),
            _buildSection(
              colors: colors,
              isDark: isDark,
              title: 'Improvements',
              icon: Icons.trending_up,
              iconColor: Colors.orange,
              items: _getImprovements(),
            ),
            const SizedBox(height: 32),
            if (analysis.suggestions.isNotEmpty) ...[
              Text(
                'AI Recommendations',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: colors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              ...analysis.suggestions.map((s) => _buildSuggestionItem(s, colors)),
            ],
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreOverview(AppColors colors, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? colors.cardBackground : colors.screenBackground,
        borderRadius: BorderRadius.circular(24),
        boxShadow: isDark ? AppTheme.darkShadow : AppTheme.lightShadow,
      ),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 160,
                height: 160,
                child: CircularProgressIndicator(
                  value: analysis.atsScore / 100,
                  strokeWidth: 12,
                  backgroundColor: colors.mutedBackground,
                  valueColor: AlwaysStoppedAnimation<Color>(colors.primary),
                ),
              ),
              Column(
                children: [
                  Text(
                    '${analysis.atsScore}%',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w800,
                      color: colors.textPrimary,
                    ),
                  ),
                  Text(
                    'ATS Score',
                    style: TextStyle(
                      fontSize: 14,
                      color: colors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            _getScoreMessage(),
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Target Role: ${analysis.jobRole}',
            style: TextStyle(
              fontSize: 14,
              color: colors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsGrid(AppColors colors, bool isDark) {
    return Row(
      children: [
        Expanded(
          child: _buildMetricCard(
            'Skill Match',
            '${analysis.skillScore}%',
            analysis.skillScore / 100,
            Colors.teal,
            colors,
            isDark,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildMetricCard(
            'Keywords',
            '${(analysis.keywordAnalysis.matchPercentage * 100).toInt()}%',
            analysis.keywordAnalysis.matchPercentage,
            Colors.orange,
            colors,
            isDark,
          ),
        ),
      ],
    );
  }

  Widget _buildMetricCard(String label, String value, double progress,
      Color color, AppColors colors, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? colors.cardBackground : colors.screenBackground,
        borderRadius: BorderRadius.circular(16),
        boxShadow: isDark ? AppTheme.darkShadow : AppTheme.lightShadow,
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: colors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                height: 48,
                width: 48,
                child: CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 5,
                  backgroundColor: color.withOpacity(0.1),
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: colors.textPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBreakdownSection(AppColors colors, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ATS Factors',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: colors.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? colors.cardBackground : colors.screenBackground,
            borderRadius: BorderRadius.circular(16),
            boxShadow: isDark ? AppTheme.darkShadow : AppTheme.lightShadow,
          ),
          child: Column(
            children: analysis.atsBreakdown.entries.map((e) {
              final val = (e.value as num).toDouble();
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          e.key.replaceAll('_', ' ').toUpperCase(),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: colors.textSecondary,
                          ),
                        ),
                        Text(
                          '${val.toInt()}%',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: colors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: val / 100,
                      backgroundColor: colors.mutedBackground,
                      valueColor: AlwaysStoppedAnimation<Color>(colors.primary),
                      minHeight: 6,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildSection({
    required AppColors colors,
    required bool isDark,
    required String title,
    required IconData icon,
    required Color iconColor,
    required List<String> items,
  }) {
    if (items.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: iconColor, size: 22),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: colors.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? colors.cardBackground : colors.screenBackground,
            borderRadius: BorderRadius.circular(16),
            boxShadow: isDark ? AppTheme.darkShadow : AppTheme.lightShadow,
          ),
          child: Column(
            children: items
                .map((item) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.circle, size: 6, color: iconColor,).paddingOnly(top: 6, right: 10),
                          Expanded(
                            child: Text(
                              item,
                              style: TextStyle(
                                fontSize: 14,
                                color: colors.textSecondary,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ))
                .toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildSuggestionItem(String text, AppColors colors) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.primarySoft.withOpacity(0.4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.primary.withOpacity(0.1)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.lightbulb_outline, size: 20, color: colors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                color: colors.textPrimary,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getScoreMessage() {
    if (analysis.atsScore >= 80) return 'Excellent Match!';
    if (analysis.atsScore >= 60) return 'Good Match!';
    return 'Needs Improvement';
  }

  List<String> _getStrengths() {
    final strengths = <String>[];
    if (analysis.keywordAnalysis.matchPercentage > 0.7) {
      strengths.add('Strong keyword alignment with the job role.');
    }
    if (analysis.matchedSkills.isNotEmpty) {
      final skills = analysis.matchedSkills.values.expand((e) => e).take(3).join(', ');
      strengths.add('High proficiency in key skills: $skills.');
    }
    if (analysis.formatIssues.isEmpty) {
      strengths.add('Professional resume structure and formatting.');
    }
    return strengths;
  }

  List<String> _getImprovements() {
    final improvements = <String>[];
    if (analysis.missingSections.isNotEmpty) {
      improvements.add('Consider adding: ${analysis.missingSections.join(", ")}.');
    }
    if (analysis.missingSkills.isNotEmpty) {
      final skills = analysis.missingSkills.values.expand((e) => e).take(3).join(', ');
      improvements.add('Highly recommended to add skills: $skills.');
    }
    improvements.addAll(analysis.formatIssues);
    return improvements;
  }
}

extension on Widget {
  Widget paddingOnly({double top = 0, double right = 0}) {
    return Padding(
      padding: EdgeInsets.only(top: top, right: right),
      child: this,
    );
  }
}
