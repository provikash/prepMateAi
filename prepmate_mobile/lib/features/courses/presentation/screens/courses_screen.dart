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
              // Header
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

              // Recommended Playlists
              SliverToBoxAdapter(
                child: _buildRecommendationsSection(
                  context,
                  recommendationsAsync,
                  colors,
                ),
              ),

              // Skill Gap Summary
              SliverToBoxAdapter(
                child: _buildSkillGapSummary(
                  context,
                  ref,
                  skillGapsAsync,
                  colors,
                ),
              ),

              // Continue Learning
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

  Widget _buildSkillChip(String label, AppColors colors) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: colors.cardBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.border),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: colors.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

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

  Widget _buildRecommendationCard(
    BuildContext context,
    AICourse rec,
    AppColors colors,
  ) {
    return Container(
      width: 220,
      margin: const EdgeInsets.only(right: 16, bottom: 10),
      decoration: BoxDecoration(
        color: colors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border),
        boxShadow: Theme.of(context).brightness == Brightness.dark
            ? AppTheme.darkShadow
            : AppTheme.lightShadow,
      ),
      child: InkWell(
        onTap: () async {
          final youtubeUrl = 'https://www.youtube.com/watch?v=${rec.videoId}';
          final uri = Uri.parse(youtubeUrl);

          if (await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          } else {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text('Could not open YouTube')));
          }
        },
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                  child: Image.network(
                    rec.thumbnail,
                    height: 120,
                    width: 220,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        Container(height: 120, color: colors.border),
                  ),
                ),
                Positioned(
                  bottom: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      rec.duration ?? 'Playlist',
                      style: const TextStyle(color: Colors.white, fontSize: 10),
                    ),
                  ),
                ),
                Positioned(
                  top: 8,
                  left: 8,
                  child: Icon(
                    Icons.play_circle_fill,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    rec.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        rec.channel,
                        style: TextStyle(
                          fontSize: 12,
                          color: colors.textSecondary,
                        ),
                      ),
                      const SizedBox(width: 4),
                      if (rec.channel.toLowerCase().contains('freecodecamp'))
                        const Icon(
                          Icons.verified,
                          size: 12,
                          color: Colors.blue,
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.star, size: 14, color: Colors.orange),
                      const SizedBox(width: 4),
                      Text(
                        '4.8 (2.1M views)',
                        style: TextStyle(
                          fontSize: 10,
                          color: colors.textSecondary,
                        ),
                      ),
                      const Spacer(),
                      _buildMatchBadge(rec.matchScore),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMatchBadge(double score) {
    Color color = Colors.green;
    String text = 'High Match';
    if (score < 40) {
      color = Colors.orange;
      text = 'Medium Match';
    } else if (score < 20) {
      color = Colors.grey;
      text = 'Low Match';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildContinueLearningSection(
    BuildContext context,
    WidgetRef ref,
    AppColors colors,
  ) {
    final progressAsync = ref.watch(continueLearningProvider);
    return progressAsync.when(
      data: (courses) {
        if (courses.isEmpty) return const SizedBox.shrink();
        final course = courses.first;
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Continue Learning',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: colors.textPrimary,
                    ),
                  ),
                  Text(
                    'View all',
                    style: TextStyle(
                      color: colors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              _buildContinueLearningItem(context, course, colors),
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildContinueLearningItem(
    BuildContext context,
    AICourse course,
    AppColors colors,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.cardBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.border),
        boxShadow: Theme.of(context).brightness == Brightness.dark
            ? AppTheme.darkShadow
            : AppTheme.lightShadow,
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              course.thumbnail,
              width: 100,
              height: 70,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  course.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: colors.textPrimary,
                  ),
                ),
                Text(
                  course.channel,
                  style: TextStyle(fontSize: 12, color: colors.textSecondary),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: LinearProgressIndicator(
                        value: 0.53, // Mock for now
                        backgroundColor: colors.border,
                        color: colors.primary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '53%',
                      style: TextStyle(
                        fontSize: 10,
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: () async {
              final youtubeUrl =
                  'https://www.youtube.com/watch?v=${course.videoId}';
              final uri = Uri.parse(youtubeUrl);

              if (await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Could not open YouTube')),
                );
              }
            },
            icon: Icon(
              Icons.play_arrow_rounded,
              color: colors.primary,
              size: 32,
            ),
          ),
        ],
      ),
    );
  }
}
