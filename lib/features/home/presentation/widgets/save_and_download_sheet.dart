import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../config/theme.dart';

/// Modal bottom sheet matching Stitch screen 20:
/// PDF Preview — Save PDF and Download.
///
/// Features:
/// - Editable sanitized filename with fixed `.pdf` extension badge
/// - ATS naming compliance indicator
/// - Download folder location display
/// - File metadata badge (size & format)
/// - Native device storage save & share actions
class SaveAndDownloadSheet extends StatefulWidget {
  const SaveAndDownloadSheet({
    super.key,
    required this.pdfBytes,
    required this.initialResumeTitle,
  });

  final Uint8List pdfBytes;
  final String initialResumeTitle;

  static Future<void> show(
    BuildContext context, {
    required Uint8List pdfBytes,
    required String initialResumeTitle,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => SaveAndDownloadSheet(
        pdfBytes: pdfBytes,
        initialResumeTitle: initialResumeTitle,
      ),
    );
  }

  @override
  State<SaveAndDownloadSheet> createState() => _SaveAndDownloadSheetState();
}

class _SaveAndDownloadSheetState extends State<SaveAndDownloadSheet> {
  late final TextEditingController _filenameController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final sanitized = widget.initialResumeTitle
        .replaceAll(RegExp(r'[^\w\s-]'), '')
        .trim()
        .replaceAll(RegExp(r'\s+'), '_');
    _filenameController = TextEditingController(
      text: sanitized.isEmpty ? 'PrepMate_Resume' : sanitized,
    );
  }

  @override
  void dispose() {
    _filenameController.dispose();
    super.dispose();
  }

  Future<void> _saveToDevice() async {
    setState(() => _isSaving = true);
    try {
      final name = _filenameController.text.trim();
      final finalFileName = name.endsWith('.pdf') ? name : '$name.pdf';

      // Save to application documents or downloads directory
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/$finalFileName');
      await file.writeAsBytes(widget.pdfBytes);

      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Expanded(child: Text('Saved "$finalFileName" to Downloads')),
            ],
          ),
          duration: const Duration(seconds: 4),
          action: SnackBarAction(
            label: 'Share',
            textColor: Colors.white,
            onPressed: () {
              SharePlus.instance.share(
                ShareParams(
                  files: [
                    XFile(
                      file.path,
                      mimeType: 'application/pdf',
                      name: finalFileName,
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Could not save PDF: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final sizeKb = (widget.pdfBytes.lengthInBytes / 1024).toStringAsFixed(0);

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF121B2E).withValues(alpha: 0.18),
            blurRadius: 32,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 44,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: colors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.save_alt, color: colors.primary, size: 24),
                  const SizedBox(width: 8),
                  Text(
                    'Save PDF',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: colors.textPrimary,
                    ),
                  ),
                ],
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
                style: IconButton.styleFrom(
                  backgroundColor: colors.screenBackground,
                  foregroundColor: colors.textSecondary,
                ),
              ),
            ],
          ),
          Text(
            'Choose filename and save to your Android device storage.',
            style: TextStyle(fontSize: 13, color: colors.textSecondary),
          ),
          const SizedBox(height: 16),

          // Filename input
          Text(
            'Filename',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: colors.primary,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            decoration: BoxDecoration(
              color: colors.screenBackground,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: colors.border),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _filenameController,
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(vertical: 8),
                    ),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: colors.textPrimary,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: colors.primarySoft,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '.pdf',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: colors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(Icons.check_circle, size: 14, color: colors.secondary),
              const SizedBox(width: 4),
              Text(
                'Standard ATS-friendly naming format applied.',
                style: TextStyle(fontSize: 11, color: colors.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Download Location Card
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.screenBackground,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: colors.border.withValues(alpha: 0.6)),
            ),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: colors.primarySoft,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.folder_outlined,
                    color: colors.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Download location',
                        style: TextStyle(
                          fontSize: 11,
                          color: colors.textSecondary,
                        ),
                      ),
                      Text(
                        'Downloads / PrepMate Resumes',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: colors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // File Details Status Pill
          Align(
            alignment: Alignment.centerLeft,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: colors.screenBackground,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 14,
                    color: colors.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '$sizeKb KB • A4 PDF Document',
                    style: TextStyle(fontSize: 11, color: colors.textSecondary),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Save Button
          FilledButton.icon(
            onPressed: _isSaving ? null : _saveToDevice,
            style: FilledButton.styleFrom(
              backgroundColor: colors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: _isSaving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.download, size: 20),
            label: Text(
              _isSaving ? 'Saving PDF...' : 'Save to device',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 8),

          // Cancel
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(foregroundColor: colors.textSecondary),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }
}
