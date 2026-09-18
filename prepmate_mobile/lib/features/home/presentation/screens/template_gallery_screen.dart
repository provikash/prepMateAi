import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/theme.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/app_state.dart';
import '../../providers/home_providers.dart';

class TemplateGalleryScreen extends ConsumerWidget {
  const TemplateGalleryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final templatesAsync = ref.watch(templateListProvider);
    return AppScaffold(
      title: 'Choose a template',
      description:
          'Start with a professional layout. You can refine the content next.',
      padding: EdgeInsets.zero,
      body: templatesAsync.when(
        loading: () => const AppLoadingState(label: 'Loading templates'),
        error: (error, _) => AppErrorState(
          message: 'We couldn’t load resume templates.',
          onAction: () => ref.read(templateListProvider.notifier).refresh(),
        ),
        data: (templates) {
          if (templates.isEmpty) {
            return const AppEmptyState(
              icon: Icons.description_outlined,
              title: 'No templates available',
              message: 'Please check again shortly.',
            );
          }
          return GridView.builder(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.screen,
              AppSpacing.xxs,
              AppSpacing.screen,
              AppSpacing.xl,
            ),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 240,
              childAspectRatio: 0.72,
              crossAxisSpacing: AppSpacing.sm,
              mainAxisSpacing: AppSpacing.sm,
            ),
            itemCount: templates.length,
            itemBuilder: (context, index) {
              final template = templates[index];
              return AppCard(
                padding: EdgeInsets.zero,
                child: InkWell(
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  onTap: () => context.push('/resume/form', extra: template.id),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(AppRadius.lg),
                          ),
                          child: _TemplateImage(url: template.thumbnailUrl),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(AppSpacing.sm),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              template.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                            const SizedBox(height: AppSpacing.xxs),
                            Text(
                              template.category,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: AppColors.of(context).textSecondary,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _TemplateImage extends StatelessWidget {
  const _TemplateImage({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final fallback = ColoredBox(
      color: colors.mutedBackground,
      child: Center(
        child: Icon(Icons.description_outlined, color: colors.textSecondary),
      ),
    );
    if (url.isEmpty) return fallback;
    return Image.network(
      url,
      width: double.infinity,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => fallback,
    );
  }
}
