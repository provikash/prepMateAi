import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/app_state.dart';
import '../../../resume/presentation/providers/resume_providers.dart';
import '../../providers/home_providers.dart';

class PdfViewScreen extends ConsumerWidget {
  const PdfViewScreen({super.key, required this.resumeId});

  final String resumeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pdf = ref.watch(pdfViewerProvider(resumeId));
    return AppScaffold(
      title: 'Resume preview',
      padding: EdgeInsets.zero,
      actions: [
        IconButton(
          tooltip: 'Delete resume',
          icon: const Icon(Icons.delete_outline),
          onPressed: () => _deleteResume(context, ref),
        ),
        IconButton(
          tooltip: 'Share PDF',
          icon: const Icon(Icons.ios_share_rounded),
          onPressed: pdf.asData == null
              ? null
              : () async {
                  try {
                    await Share.shareXFiles(
                      [
                        XFile.fromData(
                          pdf.asData!.value,
                          mimeType: 'application/pdf',
                          name: 'PrepMate-resume.pdf',
                        ),
                      ],
                      fileNameOverrides: ['PrepMate-resume.pdf'],
                    );
                  } catch (_) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Could not share the PDF. Please try again.',
                          ),
                        ),
                      );
                    }
                  }
                },
        ),
      ],
      body: pdf.when(
        loading: () => const AppLoadingState(label: 'Generating your PDF'),
        data: (bytes) => SfPdfViewer.memory(
          bytes,
          onDocumentLoadFailed: (details) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'The PDF could not be displayed. Please try again.',
                ),
              ),
            );
          },
        ),
        error: (error, _) => AppErrorState(
          title: 'PDF unavailable',
          message: error.toString().replaceFirst('Exception: ', ''),
          onAction: () => ref.invalidate(pdfViewerProvider(resumeId)),
        ),
      ),
    );
  }

  Future<void> _deleteResume(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete resume?'),
        content: const Text('This permanently removes the resume.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref.read(resumeRepositoryProvider).deleteResume(resumeId);
      ref.invalidate(resumeListProvider);
      ref.invalidate(dashboardProvider);
      if (context.mounted) context.go('/home');
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('The resume could not be deleted. Please retry.'),
          ),
        );
      }
    }
  }
}
