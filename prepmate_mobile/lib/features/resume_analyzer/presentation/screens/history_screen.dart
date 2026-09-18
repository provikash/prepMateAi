import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/theme.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/app_state.dart';
import '../providers/resume_analyzer_providers.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(historyProvider);
    return AppScaffold(
      title: 'Analysis history',
      description:
          'Review previous ATS checks and track how your resume improves.',
      padding: EdgeInsets.zero,
      body: historyAsync.when(
        loading: () => const AppLoadingState(label: 'Loading your analyses'),
        error: (error, _) => AppErrorState(
          message: 'We couldn’t load your analysis history.',
          onAction: () => ref.read(historyProvider.notifier).refresh(),
        ),
        data: (history) {
          if (history.isEmpty) {
            return const AppEmptyState(
              icon: Icons.history_rounded,
              title: 'No analyses yet',
              message: 'Completed resume analyses will appear here.',
            );
          }
          return RefreshIndicator(
            onRefresh: () => ref.read(historyProvider.notifier).refresh(),
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screen,
                AppSpacing.xs,
                AppSpacing.screen,
                AppSpacing.xl,
              ),
              itemCount: history.length,
              separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
              itemBuilder: (context, index) {
                final item = history[index];
                return AppCard(
                  padding: EdgeInsets.zero,
                  child: ListTile(
                    onTap: () => context.push('/ats-result', extra: item),
                    leading: _Score(score: item.atsScore),
                    title: Text(item.jobRole),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.xxs),
                      child: Text(
                        '${item.createdAt.day}/${item.createdAt.month}/${item.createdAt.year}  •  ${item.resumeTitle}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    trailing: const Icon(Icons.chevron_right_rounded),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _Score extends StatelessWidget {
  const _Score({required this.score});

  final int score;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final (foreground, background) = score >= 80
        ? (colors.success, colors.successSoft)
        : score >= 60
        ? (colors.warning, colors.warningSoft)
        : (colors.error, colors.errorSoft);
    return Semantics(
      label: 'ATS score $score out of 100',
      child: Container(
        width: AppSizes.tapTarget,
        height: AppSizes.tapTarget,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: background,
          shape: BoxShape.circle,
          border: Border.all(color: foreground),
        ),
        child: Text(
          '$score',
          style: Theme.of(
            context,
          ).textTheme.labelLarge?.copyWith(color: foreground),
        ),
      ),
    );
  }
}
