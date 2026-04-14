import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:prepmate_mobile/features/home/providers/home_providers.dart';
import 'package:prepmate_mobile/features/resume/providers/template_provider.dart';

import '../../resume/presentation/widgets/template_card.dart';
import '../widgets/progressCard.dart';

class PrepMateHome extends ConsumerWidget {
  const PrepMateHome({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bottomNavIndex = ref.watch(bottomNavProvider);
    final dashboardAsync = ref.watch(homeDashboardProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      appBar: _buildAppBar(),
      body: IndexedStack(
        index: bottomNavIndex,
        children: [
          _HomeContent(dashboardAsync: dashboardAsync),
          const Center(child: Text('Interview Screen')),
          const Center(child: Text('ATS Score Screen')),
          const Center(child: Text('Courses Screen')),
          const Center(child: Text('Profile Screen Placeholder')), // We will handle navigation for profile separately if needed or replace this
        ],
      ),
      bottomNavigationBar: _buildBottomNav(context, ref, bottomNavIndex),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      title: const Text(
        'Prep Mate',
        style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.add_circle_outline, color: Colors.blue),
          onPressed: () {},
        ),
      ],
    );
  }

  Widget _buildBottomNav(BuildContext context, WidgetRef ref, int currentIndex) {
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
      selectedItemColor: Colors.blue,
      unselectedItemColor: Colors.grey,
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
  final AsyncValue dashboardAsync;
  const _HomeContent({required this.dashboardAsync});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildGreeting(dashboardAsync),
          const SizedBox(height: 24),
          const ProgressCard(),
          const SizedBox(height: 32),
          _buildTemplatesHeader(),
          const SizedBox(height: 16),
          _buildTemplatesList(ref),
        ],
      ),
    );
  }

  Widget _buildGreeting(AsyncValue dashboardAsync) {
    return dashboardAsync.when(
      data: (data) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CircleAvatar(
                backgroundColor: Color(0xFFE3F2FD),
                child: Icon(Icons.add, color: Colors.blue),
              ),
              const SizedBox(width: 12),
              ActionChip(
                label: const Text('Add Resume'),
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: const BorderSide(color: Colors.black12),
                ),
                onPressed: () {},
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            'Hello, ${data.userName}!',
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          const Text(
            'Your career journey continues.',
            style: TextStyle(color: Colors.grey, fontSize: 16),
          ),
        ],
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Text('Error: $err'),
    );
  }

  Widget _buildTemplatesHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Fresh Template',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        TextButton(
          onPressed: () {},
          child: const Text('See all', style: TextStyle(color: Colors.blue)),
        ),
      ],
    );
  }

  Widget _buildTemplatesList(WidgetRef ref) {
    final templatesAsync = ref.watch(templateListProvider);

    return SizedBox(
      height: 280,
      child: templatesAsync.when(
        data: (templates) => ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: templates.length,
          itemBuilder: (context, index) {
            return SizedBox(
              width: 200,
              child: TemplateCard(
                template: templates[index],
                onSelect: () {
                  // Handle template selection
                },
              ),
            );
          },
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }
}
