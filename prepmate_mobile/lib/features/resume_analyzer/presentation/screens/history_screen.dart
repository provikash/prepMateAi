import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../config/theme.dart';
import '../providers/resume_analyzer_providers.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(historyProvider);
    final colors = AppColors.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: colors.screenBackground,
      appBar: AppBar(
        title: Text(
          'Analysis History',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: colors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: historyAsync.when(
        data: (history) => history.isEmpty
            ? _buildEmptyState(colors)
            : RefreshIndicator(
                onRefresh: () => ref.read(historyProvider.notifier).refresh(),
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  itemCount: history.length,
                  itemBuilder: (context, index) {
                    final item = history[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: isDark ? colors.cardBackground : colors.screenBackground,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: isDark ? AppTheme.darkShadow : AppTheme.lightShadow,
                      ),
                      child: ListTile(
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        onTap: () => context.push('/ats-result', extra: item),
                        leading: _buildScoreCircle(item.atsScore, colors),
                        title: Text(
                          item.jobRole,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: colors.textPrimary,
                            fontSize: 16,
                          ),
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 6.0),
                          child: Row(
                            children: [
                              Icon(Icons.calendar_today, size: 12, color: colors.textSecondary),
                              const SizedBox(width: 6),
                              Text(
                                '${item.createdAt.day}/${item.createdAt.month}/${item.createdAt.year}',
                                style: TextStyle(color: colors.textSecondary, fontSize: 13),
                              ),
                              const SizedBox(width: 12),
                              Icon(Icons.description_outlined, size: 12, color: colors.textSecondary),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  item.resumeTitle,
                                  style: TextStyle(color: colors.textSecondary, fontSize: 13),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        trailing: Icon(Icons.arrow_forward_ios,
                            size: 16, color: colors.primary),
                      ),
                    );
                  },
                ),
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
              const SizedBox(height: 16),
              Text('Error: $err', textAlign: TextAlign.center),
              TextButton(
                onPressed: () => ref.read(historyProvider.notifier).refresh(),
                child: const Text('Retry'),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScoreCircle(int score, AppColors colors) {
    Color scoreColor = Colors.redAccent;
    if (score >= 80) {
      scoreColor = Colors.green;
    } else if (score >= 60) {
      scoreColor = Colors.orange;
    }

    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: scoreColor.withOpacity(0.1),
        shape: BoxShape.circle,
        border: Border.all(color: scoreColor.withOpacity(0.3), width: 2),
      ),
      alignment: Alignment.center,
      child: Text(
        '$score',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: scoreColor,
        ),
      ),
    );
  }

  Widget _buildEmptyState(AppColors colors) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history_outlined, size: 80, color: colors.textSecondary.withOpacity(0.2)),
          const SizedBox(height: 24),
          Text(
            'No Analysis History',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Your previous resume analyses will appear here.',
            style: TextStyle(color: colors.textSecondary),
          ),
        ],
      ),
    );
  }
}
