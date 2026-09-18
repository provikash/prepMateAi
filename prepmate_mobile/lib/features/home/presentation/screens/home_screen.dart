import 'package:prepmate_mobile/core/widgets/app_loading.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/theme.dart';
import '../../../../config/page_transitions.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/career_hero.dart';
import '../../../../core/widgets/section_header.dart';
import 'package:prepmate_mobile/features/home/data/models/dashboard_model.dart';
import 'package:prepmate_mobile/features/home/data/models/resume_model.dart';
import 'package:prepmate_mobile/features/home/data/models/template_model.dart';
import 'package:prepmate_mobile/features/courses/presentation/screens/courses_screen.dart';
import 'package:prepmate_mobile/features/profile/presentation/providers/profile_provider.dart';
import 'package:prepmate_mobile/features/auth/presentation/viewmodel/auth_viewmodel.dart';
import 'package:prepmate_mobile/features/resume_analyzer/presentation/screens/analyze_screen.dart';

import '../../providers/home_providers.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _profileDialogShown = false;
  final Set<int> _visitedTabs = {0};

  @override
  Widget build(BuildContext context) {
    ref.listen(isProfileIncompleteProvider, (previous, next) {
      if (!next || _profileDialogShown || !mounted) {
        return;
      }
      _profileDialogShown = true;
      showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Complete your profile'),
          content: const Text('Please add your full name and phone number.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Later'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                context.push('/profile');
              },
              child: const Text('Complete now'),
            ),
          ],
        ),
      );
    });

    final bottomNavIndex = ref.watch(bottomNavProvider);
    _visitedTabs.add(bottomNavIndex);

    return Scaffold(
      body: IndexedStack(
        index: bottomNavIndex,
        children: List.generate(
          3,
          (index) => TabEntrance(
            active: index == bottomNavIndex,
            child: !_visitedTabs.contains(index)
                ? const SizedBox.shrink()
                : switch (index) {
                    0 => const SafeArea(child: _HomeContent()),
                    1 => const AnalyzeScreen(),
                    _ => const CoursesScreen(),
                  },
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNav(context, ref, bottomNavIndex),
    );
  }

  Widget _buildBottomNav(
    BuildContext context,
    WidgetRef ref,
    int currentIndex,
  ) {
    return NavigationBar(
      selectedIndex: currentIndex,
      animationDuration: AppMotion.standard,
      onDestinationSelected: (index) {
        if (index == 3) {
          context.push('/profile');
        } else {
          ref.read(bottomNavProvider.notifier).state = index;
        }
      },
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home_rounded),
          label: 'Home',
        ),
        NavigationDestination(
          icon: Icon(Icons.analytics_outlined),
          selectedIcon: Icon(Icons.analytics_rounded),
          label: 'Analyze',
        ),
        NavigationDestination(
          icon: Icon(Icons.auto_stories_outlined),
          selectedIcon: Icon(Icons.auto_stories),
          label: 'Learn',
        ),
        NavigationDestination(
          icon: Icon(Icons.person_outline_rounded),
          selectedIcon: Icon(Icons.person_rounded),
          label: 'Profile',
        ),
      ],
    );
  }
}

class _HomeContent extends ConsumerWidget {
  const _HomeContent();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = AppColors.of(context);
    final dashboardAsync = ref.watch(dashboardProvider);
    final resumesAsync = ref.watch(resumeListProvider);
    final templatesAsync = ref.watch(templateListProvider);

    return RefreshIndicator(
      onRefresh: () async {
        var dashboardRefreshed = false;
        await Future.wait([
          ref
              .read(dashboardProvider.notifier)
              .refresh()
              .then((value) => dashboardRefreshed = value),
          ref.read(resumeListProvider.notifier).refresh(),
          ref.read(templateListProvider.notifier).refresh(),
          ref.read(profileProvider.notifier).refresh(),
        ]);
        if (!dashboardRefreshed && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Dashboard could not be refreshed. Showing saved data.',
              ),
            ),
          );
        }
      },
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
              child: _HeaderRow(onAddTap: () => context.push('/template')),
            ),
          ),
          SliverToBoxAdapter(child: SizedBox(height: 8)),
          SliverToBoxAdapter(
            child: CareerHero(
              onBuild: () => context.push('/template'),
              onAnalyze: () => ref.read(bottomNavProvider.notifier).state = 1,
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 18),
              child: AppCard(
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: colors.primarySoft,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: Icon(Icons.auto_awesome, color: colors.primary),
                  ),
                  title: const Text('Optimize for a job'),
                  subtitle: const Text(
                    'Tailor an existing resume with evidence-backed AI suggestions.',
                  ),
                  trailing: const Icon(Icons.arrow_forward),
                  onTap: () => context.push('/resume/optimize'),
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: SizedBox(
              height: 114,
              child: _ResumeStrip(resumesAsync: resumesAsync),
            ),
          ),

          SliverToBoxAdapter(child: SizedBox(height: 18)),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: _GreetingRow(dashboardAsync: dashboardAsync),
            ),
          ),

          SliverToBoxAdapter(child: SizedBox(height: 18)),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: _ProgressCard(dashboardAsync: dashboardAsync),
            ),
          ),

          SliverToBoxAdapter(child: SizedBox(height: 18)),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
              child: SectionHeader(
                title: 'Fresh Templates',
                subtitle: 'See all',
                trailing: TextButton(
                  onPressed: () => context.push('/template'),
                  child: Text(
                    'See all',
                    style: TextStyle(color: colors.primary),
                  ),
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: SizedBox(
              height: 220,
              child: _TemplateStrip(templatesAsync: templatesAsync),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 16)),
        ],
      ),
    );
  }
}

class _HeaderRow extends StatelessWidget {
  final VoidCallback onAddTap;

  const _HeaderRow({required this.onAddTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 18),
                Text(
                  'PrepMate ✨',
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Your AI Career Companion',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          SizedBox(height: 20.0),

          Row(
            children: [
              _IconCircleButton(icon: Icons.notifications_none, onTap: () {}),
              const SizedBox(width: 18),
            ],
          ),
        ],
      ),
    );
  }
}

class _IconCircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _IconCircleButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: colors.cardBackground,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(icon, color: colors.textPrimary),
      ),
    );
  }
}

class _ResumeStrip extends StatelessWidget {
  final AsyncValue<List<ResumeModel>> resumesAsync;

  const _ResumeStrip({required this.resumesAsync});

  @override
  Widget build(BuildContext context) {
    return resumesAsync.when(
      loading: () => const Center(child: AppLoading()),
      error: (error, _) => Center(child: Text('Error: $error')),
      data: (resumes) {
        return ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          scrollDirection: Axis.horizontal,
          itemCount: resumes.length + 1,
          separatorBuilder: (_, __) => const SizedBox(width: 12),
          itemBuilder: (context, index) {
            if (index == 0) {
              return _AddResumeItem(onTap: () => context.push('/template'));
            }

            final resume = resumes[index - 1];
            return HomeResumeCard(
              title: resume.title,
              thumbnailUrl: resume.thumbnailUrl,
              onTap: () => context.push('/resume/pdf/${resume.id}'),
            );
          },
        );
      },
    );
  }
}

class _AddResumeItem extends StatelessWidget {
  final VoidCallback onTap;

  const _AddResumeItem({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(
              color: colors.primarySoft,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: colors.primary.withValues(alpha: 0.12)),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(
                  Icons.description_outlined,
                  color: colors.primary,
                  size: 30,
                ),
                Positioned(
                  right: 8,
                  bottom: 8,
                  child: Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: colors.primary,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(Icons.add, color: Colors.white, size: 14),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text('Add Resume', style: TextStyle(color: colors.textSecondary)),
        ],
      ),
    );
  }
}

class HomeResumeCard extends StatelessWidget {
  final String title;
  final String thumbnailUrl;
  final VoidCallback onTap;

  const HomeResumeCard({
    required this.title,
    required this.thumbnailUrl,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return Semantics(
      button: true,
      label: 'Open resume $title',
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          children: [
            Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colors.mutedBackground,
                border: Border.all(color: colors.primary, width: 2),
              ),
              child: ClipOval(
                child: thumbnailUrl.isEmpty
                    ? Icon(Icons.description, color: colors.primary)
                    : Image.network(
                        thumbnailUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            Icon(Icons.description, color: colors.primary),
                      ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: 78,
              child: Text(
                title,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: colors.textSecondary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GreetingRow extends ConsumerWidget {
  final AsyncValue<DashboardModel> dashboardAsync;

  const _GreetingRow({required this.dashboardAsync});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = AppColors.of(context);

    return dashboardAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (data) {
        final profileName = ref.watch(profileProvider).user?.fullName;
        final accountName = ref.watch(authViewModelProvider).user?.fullName;
        final userName = [profileName, accountName, data.userName]
            .whereType<String>()
            .map((value) => value.trim())
            .firstWhere((value) => value.isNotEmpty, orElse: () => 'User');
        return Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hello, $userName! 👋',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Your career journey continues.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            AppCard(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              borderRadius: 16,
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: colors.primarySoft,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.bolt, color: colors.primary, size: 20),
                  ),
                  const SizedBox(width: 10),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ProgressCard extends ConsumerWidget {
  final AsyncValue<DashboardModel> dashboardAsync;

  const _ProgressCard({required this.dashboardAsync});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = AppColors.of(context);

    return dashboardAsync.when(
      loading: () => const AppCard(child: Center(child: AppLoading())),
      error: (_, __) => AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Dashboard data could not be loaded.',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () => ref.read(dashboardProvider.notifier).refresh(),
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
      data: (data) {
        final score = data.atsScore;
        final progress = data.progress;
        final focusAreas = data.suggestedSkills.isNotEmpty
            ? data.suggestedSkills.split(', ').take(4).join(', ')
            : 'communication, problem solving, version control, api';

        return AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Current Progress',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: colors.primarySoft,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      'Analyzed',
                      style: TextStyle(
                        color: colors.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                data.latestResume,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontSize: 18),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: LinearProgressIndicator(
                      value: progress,
                      color: colors.primary,
                      backgroundColor: colors.primarySoft,
                      minHeight: 8,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '$score%',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: colors.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: colors.mutedBackground,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Icon(Icons.auto_awesome, color: colors.primary, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Focus areas: $focusAreas',
                        style: TextStyle(color: colors.textSecondary),
                      ),
                    ),
                    const Icon(Icons.chevron_right),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _TemplateStrip extends StatelessWidget {
  final AsyncValue<List<TemplateModel>> templatesAsync;

  const _TemplateStrip({required this.templatesAsync});

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return templatesAsync.when(
      loading: () => const Center(child: AppLoading()),
      error: (error, _) => Center(child: Text('Error: $error')),
      data: (templates) {
        return ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          scrollDirection: Axis.horizontal,
          itemCount: templates.length,
          separatorBuilder: (_, __) => const SizedBox(width: 12),
          itemBuilder: (context, index) {
            final template = templates[index];
            return GestureDetector(
              onTap: () => context.push('/resume/form', extra: template.id),
              child: SizedBox(
                width: 154,
                child: AppCard(
                  padding: const EdgeInsets.all(8),
                  borderRadius: 18,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: Container(
                            color: colors.mutedBackground,
                            width: double.infinity,
                            child: template.thumbnailUrl.isNotEmpty
                                ? Image.network(
                                    template.thumbnailUrl,
                                    fit: BoxFit.cover,
                                  )
                                : Icon(
                                    Icons.description,
                                    color: colors.primary,
                                    size: 44,
                                  ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              template.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          _TagBadge(
                            label: index.isEven ? 'NEW' : 'POPULAR',
                            color: index.isEven
                                ? colors.primary
                                : const Color(0xFF2DB36D),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        template.category,
                        style: TextStyle(
                          color: colors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _TagBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _TagBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
