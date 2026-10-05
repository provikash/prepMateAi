import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../config/theme.dart';
import '../offline/offline_status.dart';

class OfflineStatusBanner extends StatelessWidget {
  const OfflineStatusBanner({super.key, required this.status});

  final OfflineStatus status;

  @override
  Widget build(BuildContext context) {
    if (!status.shouldShow) return const SizedBox.shrink();
    final colors = AppColors.of(context);
    final updated = status.updatedAt == null
        ? null
        : DateFormat('MMM d, h:mm a').format(status.updatedAt!.toLocal());
    final (icon, text) = status.isOffline
        ? (
            Icons.cloud_off_outlined,
            updated == null
                ? 'Offline — showing saved data'
                : 'Offline — saved data from $updated',
          )
        : status.isRefreshing
        ? (Icons.sync_rounded, 'Updating saved data…')
        : (
            Icons.history_rounded,
            updated == null
                ? 'Showing saved data'
                : 'Showing saved data from $updated',
          );

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(
        AppSpacing.screen,
        AppSpacing.xs,
        AppSpacing.screen,
        AppSpacing.sm,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: colors.primarySoft,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: colors.primary),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Text(text, style: Theme.of(context).textTheme.bodySmall),
          ),
        ],
      ),
    );
  }
}
