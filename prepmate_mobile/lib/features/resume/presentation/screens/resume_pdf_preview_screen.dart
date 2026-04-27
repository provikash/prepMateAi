import 'dart:typed_data';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdfx/pdfx.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../config/dio_client.dart';
import '../providers/resume_providers.dart';

class ResumePdfPreviewScreen extends ConsumerStatefulWidget {
  final String resumeId;

  const ResumePdfPreviewScreen({super.key, required this.resumeId});

  @override
  ConsumerState<ResumePdfPreviewScreen> createState() =>
      _ResumePdfPreviewScreenState();
}

class _ResumePdfPreviewScreenState extends ConsumerState<ResumePdfPreviewScreen> {
  PdfControllerPinch? _controller;
  bool _isBusy = false;
  double _downloadProgress = 0;

  Future<File> _savePdfToLocalFile(Uint8List bytes) async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}${Platform.pathSeparator}resume_${widget.resumeId}.pdf');
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }

  Future<void> _downloadPdf() async {
    setState(() => _isBusy = true);
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}${Platform.pathSeparator}resume_${widget.resumeId}.pdf');

      final dio = ref.read(dioProvider);
      final url = Uri.parse(dio.options.baseUrl)
          .resolve('resumes/${widget.resumeId}/export/')
          .toString();

      await dio.download(
        url,
        file.path,
        onReceiveProgress: (received, total) {
          if (!mounted || total <= 0) {
            return;
          }
          setState(() {
            _downloadProgress = received / total;
          });
        },
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('PDF downloaded successfully'),
          action: SnackBarAction(
            label: 'Open',
            onPressed: () => _openDownloadedFile(file.path),
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to download PDF: $error')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isBusy = false;
          _downloadProgress = 0;
        });
      }
    }
  }

  Future<void> _openDownloadedFile(String path) async {
    final uri = Uri.file(path);
    await launchUrl(uri);
  }

  Future<void> _sharePdf(Uint8List bytes) async {
    setState(() => _isBusy = true);
    try {
      final file = await _savePdfToLocalFile(bytes);
      await Share.shareXFiles([
        XFile(file.path, mimeType: 'application/pdf'),
      ], text: 'Resume PDF from PrepMateAI');
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to share PDF: $error')),
      );
    } finally {
      if (mounted) {
        setState(() => _isBusy = false);
      }
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pdfAsync = ref.watch(pdfViewerProvider(widget.resumeId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Resume Preview'),
        actions: [
          pdfAsync.maybeWhen(
            data: (bytes) => Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  tooltip: 'Download PDF',
                  onPressed: _isBusy ? null : _downloadPdf,
                  icon: const Icon(Icons.download_outlined),
                ),
                IconButton(
                  tooltip: 'Share PDF',
                  onPressed: _isBusy ? null : () => _sharePdf(bytes),
                  icon: const Icon(Icons.share_outlined),
                ),
              ],
            ),
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
      body: pdfAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Failed to load PDF: $error',
              textAlign: TextAlign.center,
            ),
          ),
        ),
        data: (bytes) {
          _controller ??= PdfControllerPinch(document: PdfDocument.openData(bytes));

          return Stack(
            children: [
              PdfViewPinch(
                controller: _controller!,
                onDocumentError: (error) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('PDF error: ${error.toString()}')),
                  );
                },
              ),
              if (_isBusy)
                Container(
                  color: Colors.black.withValues(alpha: 0.15),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(value: _downloadProgress == 0 ? null : _downloadProgress),
                        const SizedBox(height: 10),
                        Text(
                          _downloadProgress == 0
                              ? 'Preparing download...'
                              : 'Downloading ${(100 * _downloadProgress).toStringAsFixed(0)}%',
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
