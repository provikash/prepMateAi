// ignore_for_file: file_names

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prepmate_mobile/config/theme.dart';
import '../../../features/home/providers/home_providers.dart';

class UserProfileWidget extends ConsumerWidget {
  const UserProfileWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = AppColors.of(context);

    // Watching homeDashboardProvider to get user information
    final dashboardAsync = ref.watch(dashboardProvider);

    return dashboardAsync.when(
      data: (data) => Column(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: colors.primarySoft,
            child: Icon(Icons.person, color: colors.primary, size: 40),
          ),
          const SizedBox(height: 12),
          Text(
            data.userName,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: colors.textPrimary,
            ),
          ),
        ],
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) =>
          Center(child: Text('Error loading profile: $error')),
    );
  }
}
