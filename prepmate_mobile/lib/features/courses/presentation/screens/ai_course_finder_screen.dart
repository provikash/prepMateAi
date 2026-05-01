import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../data/models/ai_course_model.dart';
import '../providers/course_providers.dart';
import '../widgets/ai_course_card.dart';
import '../widgets/skill_gap_summary.dart';

class AICourseFinderScreen extends ConsumerWidget {
  const AICourseFinderScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recommendationsAsync = ref.watch(courseRecommendationsProvider);
    final continueLearningAsync = ref.watch(continueLearningProvider);

    return RefreshIndicator(
      onRefresh: () async {
        // Fetch recommendations (you'll need to get skills from somewhere)
        ref.read(courseRecommendationsProvider.notifier).fetchRecommendations([
          'React',
          'State Management',
          'Advanced Coding',
        ]);
      },
      child: CustomScrollView(
        slivers: [
          // ════════════════════════════════════════
          // HEADER
          // ════════════════════════════════════════
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Courses',
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Personalized courses based on your Skill Gap',
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ),

          // ════════════════════════════════════════
          // AI COURSE FINDER SEARCH BOX
          // ════════════════════════════════════════
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            sliver: SliverToBoxAdapter(child: _buildAISearchBox(context, ref)),
          ),

          // ════════════════════════════════════════
          // SKILL GAP SUMMARY
          // ════════════════════════════════════════
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            sliver: SliverToBoxAdapter(child: const SkillGapSummary()),
          ),

          // ════════════════════════════════════════
          // CONTINUE LEARNING (If any)
          // ════════════════════════════════════════
          continueLearningAsync.when(
            data: (courses) {
              if (courses.isEmpty) {
                return SliverToBoxAdapter(child: SizedBox.shrink());
              }
              return SliverPadding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                sliver: SliverToBoxAdapter(
                  child: _buildContinueLearningSection(context, ref, courses),
                ),
              );
            },
            loading: () => SliverToBoxAdapter(child: SizedBox.shrink()),
            error: (err, stack) => SliverToBoxAdapter(child: SizedBox.shrink()),
          ),

          // ════════════════════════════════════════
          // RECOMMENDED PLAYLISTS
          // ════════════════════════════════════════
          recommendationsAsync.when(
            data: (courses) {
              if (courses.isEmpty) {
                return SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Center(
                      child: Text('No courses found. Search to get started!'),
                    ),
                  ),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Recommended Playlists',
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 250,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: courses.length,
                          itemBuilder: (context, index) {
                            final course = courses[index];
                            return Padding(
                              padding: const EdgeInsets.only(right: 16),
                              child: AICourseCard(
                                course: course,
                                onTap: () =>
                                    _navigateToPlayer(context, ref, course),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
            loading: () => SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: SizedBox(
                  height: 250,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: 3,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 16),
                        child: Container(
                          width: 160,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
            error: (error, stack) => SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Center(child: Text('Error loading courses: $error')),
              ),
            ),
          ),

          // Add bottom padding
          SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  Widget _buildAISearchBox(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFF0E7FF), Color(0xFFE8D5FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Color(0xFFD4B3FF), width: 1),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Color(0xFF7C3AED),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.psychology, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                'AI Course Finder',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF4C1D95),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            readOnly: true,
            decoration: InputDecoration(
              hintText: 'Find playlists on YouTube for...',
              filled: true,
              fillColor: Colors.white,
              suffixIcon: Icon(Icons.search, color: Color(0xFF7C3AED)),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    // Trigger search with default skills
                    ref
                        .read(courseRecommendationsProvider.notifier)
                        .fetchRecommendations([
                          'React',
                          'State Management',
                          'Clean Code',
                        ]);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF7C3AED),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.search, size: 18),
                      const SizedBox(width: 8),
                      Text('Search'),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Color(0xFF7C3AED).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.verified, size: 12, color: Color(0xFF7C3AED)),
                    const SizedBox(width: 4),
                    Text(
                      'Powered by Skill Analyzer',
                      style: TextStyle(
                        fontSize: 11,
                        color: Color(0xFF7C3AED),
                        fontWeight: FontWeight.w500,
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

  Widget _buildContinueLearningSection(
    BuildContext context,
    WidgetRef ref,
    List<AICourse> courses,
  ) {
    if (courses.isEmpty) return SizedBox.shrink();

    final course = courses.first;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Continue Learning',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              TextButton(onPressed: () {}, child: Text('View all')),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                  child: Image.network(
                    course.thumbnail,
                    height: 120,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        course.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: LinearProgressIndicator(
                              value: 0.45,
                              minHeight: 4,
                              backgroundColor: Colors.grey[300],
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Color(0xFF7C3AED),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '45%',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () =>
                              _navigateToPlayer(context, ref, course),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFF7C3AED),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text('Resume'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToPlayer(
    BuildContext context,
    WidgetRef ref,
    AICourse course,
  ) async {
    // Open YouTube URL instead of playing inline
    final youtubeUrl = 'https://www.youtube.com/watch?v=${course.videoId}';
    final uri = Uri.parse(youtubeUrl);

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      // Fallback: show error message
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not open YouTube')));
    }
  }
}
