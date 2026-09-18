import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/theme.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_state.dart';
import '../providers/ai_provider.dart';

class AIResultScreen extends ConsumerWidget {
  const AIResultScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(aiProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI result'),
        actions: [
          IconButton(
            tooltip: 'Close',
            icon: const Icon(Icons.close_rounded),
            onPressed: () {
              ref.read(aiProvider.notifier).reset();
              context.pop();
            },
          ),
        ],
      ),
      body: switch (state.status) {
        AIStatus.loading => const AppLoadingState(
          label: 'Improving your resume content',
        ),
        AIStatus.success => _SuccessState(state: state),
        AIStatus.error => AppErrorState(
          title: 'AI enhancement unavailable',
          message: state.errorMessage ?? 'Please try again in a moment.',
        ),
        _ => const AppEmptyState(
          icon: Icons.auto_awesome_outlined,
          title: 'No result yet',
          message: 'Choose an AI action from the resume form to get started.',
        ),
      },
    );
  }
}

class _SuccessState extends ConsumerWidget {
  const _SuccessState({required this.state});

  final AIState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = AppColors.of(context);
    final result = state.result ?? '';
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.screen,
          AppSpacing.md,
          AppSpacing.screen,
          AppSpacing.xl,
        ),
        child: Column(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: colors.successSoft,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.check_rounded, color: colors.success, size: 34),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              _titleForAction(state.action),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppSpacing.xxs),
            Text(
              _subtitleForAction(state.action),
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: colors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.lg),
            Expanded(
              child: AppCard(
                child: SingleChildScrollView(
                  child: SelectableText(
                    result,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: AppSecondaryButton(
                    label: 'Copy',
                    icon: Icons.copy_rounded,
                    onPressed: () async {
                      await Clipboard.setData(ClipboardData(text: result));
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Copied to clipboard.')),
                        );
                      }
                    },
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: AppPrimaryButton(
                    label: 'Back to form',
                    icon: Icons.check_rounded,
                    onPressed: () {
                      ref.read(aiProvider.notifier).reset();
                      context.pop();
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _titleForAction(String? action) => switch (action) {
    'generate_summary' => 'Summary generated',
    'improve_section' => 'Section improved',
    'suggest_skills' => 'Skills suggested',
    'generate_bullets' => 'Bullet points generated',
    _ => 'Enhancement ready',
  };

  String _subtitleForAction(String? action) => switch (action) {
    'generate_summary' => 'Applied to your summary section.',
    'improve_section' => 'Applied to your summary section.',
    'suggest_skills' => 'Added to your skills section.',
    'generate_bullets' => 'Added to your first experience.',
    _ => 'Applied to your resume form.',
  };
}
