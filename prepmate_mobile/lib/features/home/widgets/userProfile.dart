import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../features/home/providers/home_providers.dart';
import 'package:cached_network_image/cached_network_image.dart';

class UserProfileWidget extends ConsumerWidget {
  const UserProfileWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watching homeDashboardProvider to get user information
    final dashboardAsync = ref.watch(dashboardProvider);

    return dashboardAsync.when(
      data: (data) => Column(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: Colors.blue.shade100,
            child: const Icon(Icons.person, color: Colors.blue, size: 40),
          ),
          const SizedBox(height: 12),
          Text(
            data.userName,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ],
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) =>
          Center(child: Text('Error loading profile: $error')),
    );
  }
}
