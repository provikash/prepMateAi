import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import '../../../../config/theme.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/app_state.dart';
import '../../../resume/presentation/providers/resume_providers.dart';
import '../providers/optimization_provider.dart';
import '../widgets/optimization_widgets.dart';
import '../../../ai_credits/presentation/providers/ai_credits_provider.dart';

class OptimizedResumePreviewScreen extends ConsumerWidget {
  const OptimizedResumePreviewScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(optimizationProvider);
    final credits = ref.watch(aiCreditsProvider).account?.availableCredits ?? 0;
    final resume = state.resume;
    if (resume == null) {
      return AppScaffold(
        title: 'Optimized Resume',
        body: const AppErrorState(
          message: 'The selected resume is unavailable.',
        ),
      );
    }
    final pdf = ref.watch(pdfViewerProvider(resume.id));
    return AppScaffold(
      title: 'Optimized Resume',
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        0,
        AppSpacing.md,
        AppSpacing.md,
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: Center(child: CreditBadge(credits: credits)),
        ),
      ],
      body: ResponsiveContent(
        maxWidth: 1100,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          state.versionName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        Text(
                          'Master safe · ${state.analysis?.afterScore ?? 86}% ATS',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: AppColors.of(context).success),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    tooltip: 'Resume actions',
                    onSelected: (value) {
                      if (value == 'ats') context.push('/resume/optimize/ats');
                      if (value == 'template') context.push('/template');
                      if (value == 'edit') context.push('/resume/form');
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 'edit', child: Text('Edit Resume')),
                      PopupMenuItem(
                        value: 'template',
                        child: Text('Change Template'),
                      ),
                      PopupMenuItem(value: 'ats', child: Text('View ATS')),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.md),
                child: ColoredBox(
                  color: AppColors.of(context).mutedBackground,
                  child: pdf.when(
                    loading: () => const _PdfLoading(),
                    error: (_, __) => AppErrorState(
                      title: 'PDF unavailable',
                      message:
                          'We could not render this resume. Select a saved resume and retry.',
                      actionLabel: 'Retry',
                      onAction: () =>
                          ref.invalidate(pdfViewerProvider(resume.id)),
                    ),
                    data: (bytes) => SfPdfViewer.memory(
                      bytes,
                      canShowPaginationDialog: true,
                      canShowScrollHead: true,
                      onDocumentLoadFailed: (_) =>
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('PDF rendering failed. Try again.'),
                            ),
                          ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: AppSecondaryButton(
                    label: 'View ATS',
                    icon: Icons.analytics_outlined,
                    onPressed: () => context.push('/resume/optimize/ats'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: AppPrimaryButton(
                    label: 'Download PDF',
                    icon: Icons.download,
                    onPressed: pdf.asData == null
                        ? null
                        : () => _sharePdf(
                            context,
                            pdf.asData!.value,
                            state.versionName,
                          ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _sharePdf(
    BuildContext context,
    List<int> bytes,
    String name,
  ) async {
    try {
      await Share.shareXFiles(
        [
          XFile.fromData(
            Uint8List.fromList(bytes),
            mimeType: 'application/pdf',
            name: '$name.pdf',
          ),
        ],
        fileNameOverrides: ['$name.pdf'],
      );
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('PDF export failed. Try again.')),
        );
      }
    }
  }
}

class _PdfLoading extends StatelessWidget {
  const _PdfLoading();
  @override
  Widget build(BuildContext context) => const Center(
    child: SizedBox(
      width: 280,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          LinearProgressIndicator(),
          SizedBox(height: 12),
          Text('Rendering resume...'),
          SizedBox(height: 4),
          Text('Generating PDF...'),
        ],
      ),
    ),
  );
}
