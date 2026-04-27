// ignore_for_file: file_names

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:prepmate_mobile/config/theme.dart';
import 'package:prepmate_mobile/features/home/providers/home_providers.dart';
import 'package:prepmate_mobile/features/profile/presentation/providers/profile_provider.dart';
import 'package:prepmate_mobile/features/interview/presentation/screens/interview_screen.dart';
import 'package:prepmate_mobile/features/resume_analyzer/presentation/screens/analyze_screen.dart';
import '../widgets/progressCard.dart';
import '../presentation/widgets/resume_horizontal_list.dart';
import '../presentation/widgets/template_horizontal_list.dart';

class PrepMateHome extends ConsumerStatefulWidget {
  const PrepMateHome({super.key});

  @override
  ConsumerState<PrepMateHome> createState() => _PrepMateHomeState();
}

class _PrepMateHomeState extends ConsumerState<PrepMateHome> {
  bool _profileDialogShown = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(profileProvider.notifier).loadProfile());
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(isProfileIncompleteProvider, (previous, isIncomplete) {
      if (!isIncomplete || _profileDialogShown || !mounted) {
        return;
      }

      _profileDialogShown = true;
      showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Complete your profile'),
          content: const Text('Please add your full name and phone number.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Later'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(context).pop();
                context.push('/profile');
              },
              child: const Text('Complete now'),
            ),
          ],
        ),
      );
    });

    final colors = AppColors.of(context);
    final bottomNavIndex = ref.watch(bottomNavProvider);

    return Scaffold(
      backgroundColor: colors.screenBackground,
      appBar: _buildAppBar(context),
      body: IndexedStack(
        index: bottomNavIndex,
        children: [
          const _HomeContent(),
          const InterviewScreen(),
          const AnalyzeScreen(),
          const Center(child: Text('Courses Screen')),
          const Center(
            child: Text('Profile Screen Placeholder'),
          ), // We will handle navigation for profile separately if needed or replace this
        ],
      ),
      bottomNavigationBar: _buildBottomNav(context, ref, bottomNavIndex),
    );
  }

  AppBar _buildAppBar(BuildContext context) {
    final colors = AppColors.of(context);

    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      title: Text(
        'Prep Mate',
        style: TextStyle(
          color: colors.textPrimary,
          fontWeight: FontWeight.bold,
        ),
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.add_circle_outline, color: colors.primary),
          onPressed: () {},
        ),
      ],
    );
  }

  Widget _buildBottomNav(
    BuildContext context,
    WidgetRef ref,
    int currentIndex,
  ) {
    final colors = AppColors.of(context);

    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: (index) {
        if (index == 4) {
          context.push('/profile');
        } else {
          ref.read(bottomNavProvider.notifier).state = index;
        }
      },
      type: BottomNavigationBarType.fixed,
      selectedItemColor: colors.primary,
      unselectedItemColor: colors.textSecondary,
      showUnselectedLabels: true,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.mic), label: 'Interview'),
        BottomNavigationBarItem(icon: Icon(Icons.score), label: 'ATS Score'),
        BottomNavigationBarItem(icon: Icon(Icons.book), label: 'Courses'),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
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

    return RefreshIndicator(
      onRefresh: () async {
        await Future.wait([
          ref.read(dashboardProvider.notifier).refresh(),
          ref.read(resumeListProvider.notifier).refresh(),
          ref.read(templateListProvider.notifier).refresh(),
          ref.read(profileProvider.notifier).refresh(),
        ]);
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const ResumeHorizontalList(),
            const SizedBox(height: 20),
            _buildGreeting(dashboardAsync, colors),
            const SizedBox(height: 24),
            const ProgressCard(),
            const SizedBox(height: 32),
            const TemplateHorizontalList(),
          ],
        ),
      ),
    );
  }

  Widget _buildGreeting(AsyncValue dashboardAsync, AppColors colors) {
    return dashboardAsync.when(
      data: (data) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Hello, ${data.userName}!',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Your career journey continues.',
            style: TextStyle(color: colors.textSecondary, fontSize: 16),
          ),
        ],
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Text('Error: $err'),
    );
  }
}
