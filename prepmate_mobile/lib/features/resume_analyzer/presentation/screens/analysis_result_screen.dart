import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../config/theme.dart';
import '../../data/models/resume_analysis_model.dart';

class AnalysisResultScreen extends ConsumerWidget {
  final ResumeAnalysisModel analysis;

  const AnalysisResultScreen({super.key, required this.analysis});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppTheme.lightBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Analysis Result',
          style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Main Score Card
            _buildScoreCard(),
            const SizedBox(height: 24),

            // Performance Metrics
            const Text(
              'Performance Metrics',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 16),

            // Metrics Row
            Row(
              children: [
                Expanded(child: _buildMetricItem('ATS SCORE', analysis.atsScore, Colors.blue)),
                const SizedBox(width: 12),
                Expanded(child: _buildMetricItem('SKILL MATCH', analysis.skillScore, Colors.teal)),
                const SizedBox(width: 12),
                Expanded(child: _buildMetricItem('KEYWORDS', (analysis.keywordAnalysis.matchPercentage * 100).toInt(), Colors.orange)),
              ],
            ),
            const SizedBox(height: 24),

            // ATS Breakdown
            if (analysis.atsBreakdown.isNotEmpty) ...[
              const Text(
                'Score Breakdown',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1D2939)),
              ),
              const SizedBox(height: 12),
              ...analysis.atsBreakdown.entries.map((entry) {
                final score = (entry.value is num) ? entry.value.toDouble() : 0.0;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(entry.key.replaceAll('_', ' ').toUpperCase(), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                          Text('${score.toInt()}%', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      LinearProgressIndicator(
                        value: score / 100,
                        backgroundColor: Colors.grey.shade100,
                        valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primary.withOpacity(0.7)),
                        minHeight: 6,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 24),
            ],

            // Strengths Section (Matched Skills & Matched Keywords)
            _buildSection(
              title: 'STRENGTHS',
              icon: Icons.check_circle,
              iconColor: Colors.green,
              backgroundColor: const Color(0xFFF0FDF4),
              items: [
                ...analysis.matchedSkills.values.expand((e) => e).take(3).map((s) => 'Strong knowledge in $s'),
                'Matched ${analysis.keywordAnalysis.matchedKeywords.length} key industry terms',
                if (analysis.formatIssues.isEmpty) 'Excellent resume formatting and structure',
              ],
            ),
            const SizedBox(height: 16),

            // Areas for Improvement (Missing Skills, Format Issues)
            _buildSection(
              title: 'AREAS FOR IMPROVEMENT',
              icon: Icons.trending_up,
              iconColor: Colors.orange,
              backgroundColor: const Color(0xFFFFFBEB),
              items: [
                if (analysis.missingSections.isNotEmpty) 
                  'Missing sections: ${analysis.missingSections.join(", ")}',
                ...analysis.missingSkills.values.expand((e) => e).take(2).map((s) => 'Consider adding $s to your skills'),
                ...analysis.formatIssues.take(2),
                ...analysis.contactIssues,
              ],
            ),
            const SizedBox(height: 32),

            // Suggestions / AI Feedback
            if (analysis.suggestions.isNotEmpty) ...[
              const Text(
                'AI Suggestions',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              ...analysis.suggestions.map((s) => Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.lightbulb_outline, size: 20, color: Colors.amber),
                    const SizedBox(width: 8),
                    Expanded(child: Text(s, style: const TextStyle(fontSize: 14, color: Colors.black87))),
                  ],
                ),
              )),
            ],

            const SizedBox(height: 30),

            // Action Button
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: AppTheme.buttonGradient,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primary.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: () {
                  if (Navigator.canPop(context)) {
                    Navigator.pop(context);
                  } else {
                    context.go('/ats-analysis');
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text(
                  'Try Another Analysis',
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 140,
                height: 140,
                child: CircularProgressIndicator(
                  value: analysis.atsScore / 100,
                  strokeWidth: 12,
                  backgroundColor: Colors.grey.shade100,
                  valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primary),
                ),
              ),
              Column(
                children: [
                  Text(
                    '${analysis.atsScore}',
                    style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Color(0xFF1D2939)),
                  ),
                  Text(
                    '/ 100',
                    style: TextStyle(fontSize: 16, color: Colors.grey.shade500),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            analysis.atsScore >= 80 ? 'Great Job!' : analysis.atsScore >= 60 ? 'Good Start!' : 'Needs Work',
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1D2939)),
          ),
          const SizedBox(height: 8),
          Text(
            'Your resume is showing strong alignment with the ${analysis.jobRole} role. Keep optimizing to reach the top 10%.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricItem(String label, int value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 50,
                height: 50,
                child: CircularProgressIndicator(
                  value: value / 100,
                  strokeWidth: 4,
                  backgroundColor: Colors.grey.shade50,
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              ),
              Text(
                '$value%',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey.shade500, letterSpacing: 0.5),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required Color iconColor,
    required Color backgroundColor,
    required List<String> items,
  }) {
    if (items.isEmpty) return const SizedBox.shrink();
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: iconColor,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...items.map((item) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.check_circle, color: iconColor.withOpacity(0.5), size: 16),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    item,
                    style: const TextStyle(fontSize: 14, color: Color(0xFF344054), height: 1.4),
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }
}
