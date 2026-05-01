import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/course_providers.dart';

class SkillGapSummary extends ConsumerWidget {
  const SkillGapSummary({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final skillGapAsync = ref.watch(skillGapProvider);
    final historyAsync = ref.watch(historyProvider);

    final score = historyAsync.when(
      data: (history) => history.isEmpty ? 0 : history.first.atsScore,
      loading: () => 0,
      error: (_, __) => 0,
    );

    final skills = skillGapAsync; // Since skillGapProvider returns List<String> directly

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Color(0xFFFFF3E0),
        border: Border.all(
          color: Color(0xFFFFE0B2),
          width: 1,
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Text(
            'Your Skill Gap Summary',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),

          // Main content row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Overall Score Circle
              Column(
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox.expand(
                          child: CircularProgressIndicator(
                            value: score / 100,
                            backgroundColor: Colors.grey[300],
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Color(0xFFE53935),
                            ),
                            strokeWidth: 8,
                          ),
                        ),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '$score%',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFE53935),
                              ),
                            ),
                            Text(
                              'Overall',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Score',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 20),

              // Missing Skills
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Top Missing Skills',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (skills.isEmpty)
                      Text(
                        'Analyze a resume to see missing skills.',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      )
                    else
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: skills.map((s) => _SkillChip(s)).toList(),
                      ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Recommended Focus
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Color(0xFFFFE0B2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.lightbulb, color: Color(0xFFF57C00), size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    skills.isEmpty 
                      ? 'Upload your resume to get personalized recommendations.'
                      : 'Focus on mastering ${skills.take(2).join(' and ')} to improve your match score.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFFF57C00),
                      fontWeight: FontWeight.w500,
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
}

class _SkillChip extends StatelessWidget {
  final String skill;

  const _SkillChip(this.skill);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Color(0xFFFFB74D),
          width: 1,
        ),
      ),
      child: Text(
        skill,
        style: TextStyle(
          fontSize: 11,
          color: Color(0xFFF57C00),
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
