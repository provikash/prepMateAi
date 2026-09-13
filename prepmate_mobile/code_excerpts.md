# Code Excerpts from CoursesScreen.dart

## Project Overview
This document contains key code excerpts from the `CoursesScreen.dart` file, which is part of a Flutter mobile application called PrepMate AI. The screen provides a personalized course recommendation interface based on skill gap analysis.

## Key Imports
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../config/theme.dart';
import '../providers/course_providers.dart';
import '../../../resume_analyzer/presentation/providers/resume_analyzer_providers.dart';
import '../widgets/section_widget.dart';
import '../widgets/continue_learning_card.dart';
import '../../data/models/ai_course_model.dart';
import 'all_playlists_screen.dart';
```

## Main Class Declaration
```dart
class CoursesScreen extends ConsumerWidget {
  const CoursesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recommendationsAsync = ref.watch(courseRecommendationsProvider);
    final skillGapsAsync = ref.watch(skillGapProvider);
    final colors = AppColors.of(context);

    return Scaffold(
      backgroundColor: colors.screenBackground,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(courseRecommendationsProvider);
            ref.invalidate(allCourseProgressProvider);
            ref.invalidate(historyProvider);
          },
          child: CustomScrollView(
            slivers: [
              // Header Section
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Courses',
                        style: Theme.of(context).textTheme.headlineLarge,
                      ),
                      Text(
                        'Personalized courses based on your Skill Gap',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 20),
                      _buildAICourseFinder(
                        context,
                        ref,
                        skillGapsAsync,
                        colors,
                      ),
                    ],
                  ),
                ),
              ),

              // Recommended Playlists Section
              SliverToBoxAdapter(
                child: _buildRecommendationsSection(
                  context,
                  recommendationsAsync,
                  colors,
                ),
              ),

              // Skill Gap Summary Section
              SliverToBoxAdapter(
                child: _buildSkillGapSummary(
                  context,
                  ref,
                  skillGapsAsync,
                  colors,
                ),
              ),

              // Continue Learning Section
              SliverToBoxAdapter(
                child: _buildContinueLearningSection(context, ref, colors),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
        ),
      ),
    );
  }
```

## AI Course Finder Widget
```dart
Widget _buildAICourseFinder(
  BuildContext context,
  WidgetRef ref,
  List<String> skills,
  AppColors colors,
) {
  final controller = TextEditingController(text: skills.join(', '));
  final primaryColor = colors.primary;
  final secondaryColor = colors.primarySoft;

  return Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: secondaryColor,
      borderRadius: BorderRadius.circular(24),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: primaryColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.psychology,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'AI Course Finder',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: colors.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            filled: true,
            fillColor: colors.cardBackground,
            hintText: 'Find playlists on YouTube for...',
            hintStyle: TextStyle(
              color: colors.textSecondary.withOpacity(0.5),
            ),
            suffixIcon: Icon(Icons.search, color: primaryColor),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton.icon(
            icon: const Icon(Icons.search, color: Colors.white),
            label: const Text(
              'Search',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            onPressed: () {
              final query = controller.text
                  .split(',')
                  .map((s) => s.trim())
                  .where((s) => s.isNotEmpty)
                  .toList();
              ref
                  .read(courseRecommendationsProvider.notifier)
                  .fetchRecommendations(query);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle, size: 14, color: primaryColor),
                  const SizedBox(width: 4),
                  Text(
                    'Powered by Skill Analyzer',
                    style: TextStyle(
                      fontSize: 11,
                      color: primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    ),
  );
}
```

## Skill Gap Summary Widget
```dart
Widget _buildSkillGapSummary(
  BuildContext context,
  WidgetRef ref,
  List<String> skills,
  AppColors colors,
) {
  final analysisAsync = ref.watch(historyProvider);
  final overallScore = analysisAsync.when(
    data: (history) => history.isEmpty ? 0 : history.first.atsScore,
    loading: () => 0,
    error: (_, __) => 0,
  );

  return Container(
    margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: colors.mutedBackground,
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: colors.border),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Your Skill Gap Summary',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: colors.textPrimary.withOpacity(0.5),
          ),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            _buildCircularScore(overallScore, colors),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Top Missing Skills',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: skills
                        .map((s) => _buildSkillChip(s, colors))
                        .toList(),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: colors.primarySoft,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(Icons.lightbulb, color: colors.primary, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Improve your development and advanced coding skills.',
                  style: TextStyle(
                    fontSize: 12,
                    color: colors.textPrimary,
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
```

## Circular Score Widget
```dart
Widget _buildCircularScore(int score, AppColors colors) {
  return Column(
    children: [
      Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            height: 90,
            width: 90,
            child: CircularProgressIndicator(
              value: score / 100,
              strokeWidth: 10,
              backgroundColor: colors.border,
              color: colors.primary,
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$score%',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  color: colors.textPrimary,
                ),
              ),
              Text(
                'Overall',
                style: TextStyle(fontSize: 10, color: colors.textSecondary),
              ),
            ],
          ),
        ],
      ),
      const SizedBox(height: 8),
      Text(
        'Score',
        style: TextStyle(fontSize: 12, color: colors.textSecondary),
      ),
    ],
  );
}
```

## Recommendations Section
```dart
Widget _buildRecommendationsSection(
  BuildContext context,
  AsyncValue<List<AICourse>> asyncRecs,
  AppColors colors,
) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recommended Playlists',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: colors.textPrimary,
              ),
            ),
            GestureDetector(
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const AllPlaylistsScreen(),
                ),
              ),
              child: Text(
                'View all',
                style: TextStyle(
                  color: colors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 5),
      SizedBox(
        height: 260,
        child: asyncRecs.when(
          data: (recs) {
            if (recs.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.search_off,
                      size: 48,
                      color: colors.textSecondary.withOpacity(0.5),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'No recommendations found. Try searching above!',
                      style: TextStyle(color: colors.textSecondary),
                    ),
                  ],
                ),
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              scrollDirection: Axis.horizontal,
              itemCount: recs.length,
              itemBuilder: (context, index) =>
                  _buildRecommendationCard(context, recs[index], colors),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                'Could not load AI recommendations. Make sure backend is running.',
                textAlign: TextAlign.center,
                style: TextStyle(color: colors.textSecondary, fontSize: 12),
              ),
            ),
          ),
        ),
      ),
    ],
  );
}
```

## Conclusion
This code demonstrates advanced Flutter development techniques including:
- State management with Riverpod
- Custom UI components with theming
- Asynchronous data handling
- Complex layout structures using Slivers
- Integration with external services (YouTube API)
- Responsive design patterns

The file showcases a professional mobile application architecture with clean separation of concerns and reusable widget components.</content>
<parameter name="filePath">c:\Users\vacha\Desktop\project\prepMateAi\code_excerpts.md