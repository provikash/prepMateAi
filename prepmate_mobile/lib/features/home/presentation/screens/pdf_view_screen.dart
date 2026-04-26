import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import '../../providers/home_providers.dart';

class PdfViewScreen extends ConsumerWidget {
  final String resumeId;

  const PdfViewScreen({super.key, required this.resumeId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resumeFuture = ref
        .read(homeRemoteDataSourceProvider)
        .getResumeById(resumeId);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Resume Viewer'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: FutureBuilder(
        future: resumeFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Failed to load resume: ${snapshot.error}'),
            );
          }

          final resume = snapshot.data;
          if (resume == null ||
              resume.pdfUrl == null ||
              resume.pdfUrl!.isEmpty) {
            return const Center(
              child: Text('PDF is not available for this resume yet.'),
            );
          }

          return SfPdfViewer.network(
            resume.pdfUrl!,
            onDocumentLoadFailed: (details) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Failed to load PDF: ${details.description}'),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
