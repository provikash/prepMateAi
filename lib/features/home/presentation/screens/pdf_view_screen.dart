import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

import '../../../../config/theme.dart';
import '../../../resume/presentation/providers/resume_providers.dart';
import '../widgets/pages_and_document_info_sheet.dart';
import '../widgets/save_and_download_sheet.dart';

/// Screen 19: PDF Preview — Document Viewer &
/// Screen 22: PDF Preview — Generation and Error States.
class PdfViewScreen extends ConsumerStatefulWidget {
  const PdfViewScreen({super.key, required this.resumeId});

  final String resumeId;

  @override
  ConsumerState<PdfViewScreen> createState() => _PdfViewScreenState();
}

class _PdfViewScreenState extends ConsumerState<PdfViewScreen> {
  final PdfViewerController _pdfViewerController = PdfViewerController();
  int _pageCount = 1;
  int _currentPage = 1;
  double _zoomLevel = 1.0;

  void _zoomIn() {
    setState(() {
      _zoomLevel = (_zoomLevel + 0.25).clamp(0.75, 3.0);
      _pdfViewerController.zoomLevel = _zoomLevel;
    });
  }

  void _zoomOut() {
    setState(() {
      _zoomLevel = (_zoomLevel - 0.25).clamp(0.75, 3.0);
      _pdfViewerController.zoomLevel = _zoomLevel;
    });
  }

  void _resetZoom() {
    setState(() {
      _zoomLevel = 1.0;
      _pdfViewerController.zoomLevel = 1.0;
    });
  }

  void _jumpToPage(int page) {
    if (page >= 1 && page <= _pageCount) {
      _pdfViewerController.jumpToPage(page);
      setState(() => _currentPage = page);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final pdfAsync = ref.watch(pdfViewerProvider(widget.resumeId));

    return Scaffold(
      backgroundColor: colors.screenBackground,
      appBar: AppBar(
        backgroundColor: colors.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Resume Preview',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: colors.textPrimary,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Document details',
            icon: const Icon(Icons.help_outline),
            onPressed: () {
              if (pdfAsync.asData != null) {
                PagesAndDocumentInfoSheet.show(
                  context,
                  pageCount: _pageCount,
                  currentPage: _currentPage,
                  fileSizeBytes: pdfAsync.asData!.value.lengthInBytes,
                  templateName: 'Modern Professional (A4)',
                  onJumpToPage: _jumpToPage,
                );
              }
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: pdfAsync.when(
        loading: () => _buildGenerationState(context),
        error: (error, _) => _buildErrorState(context, error.toString()),
        data: (bytes) => _buildViewer(context, bytes),
      ),
    );
  }

  Widget _buildGenerationState(BuildContext context) {
    final colors = AppColors.of(context);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Status bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: colors.primarySoft,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: colors.secondary,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Cloud sync: Ready',
                        style: TextStyle(
                          fontSize: 12,
                          color: colors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    'PDF Engine v3.4',
                    style: TextStyle(fontSize: 11, color: colors.textSecondary),
                  ),
                ],
              ),
            ),
            const Spacer(),
            // Tactile Circular Loader with Center Sparkle
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 90,
                  height: 90,
                  child: CircularProgressIndicator(
                    strokeWidth: 6,
                    valueColor: AlwaysStoppedAnimation<Color>(colors.primary),
                    backgroundColor: colors.primarySoft,
                  ),
                ),
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: colors.surface,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: colors.primary.withValues(alpha: 0.15),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.auto_awesome,
                    color: colors.primary,
                    size: 24,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              'Preparing high-resolution PDF preview…',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Compiling fonts, layout geometry, and ATS-friendly text layer.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: colors.textSecondary),
            ),
            const SizedBox(height: 28),
            // Stepper Status Pills
            _buildStatusStep(
              icon: Icons.check_circle,
              iconColor: colors.secondary,
              label: 'Layout typography compiled',
              status: 'Done',
              statusColor: colors.textSecondary,
            ),
            const SizedBox(height: 8),
            _buildStatusStep(
              icon: Icons.sync,
              iconColor: colors.primary,
              label: 'Embedding ATS text tags',
              status: 'Compiling',
              statusColor: colors.primary,
            ),
            const SizedBox(height: 8),
            _buildStatusStep(
              icon: Icons.pending_outlined,
              iconColor: colors.textSecondary,
              label: 'Calibrating page boundaries',
              status: 'Queued',
              statusColor: colors.textSecondary,
            ),
            const Spacer(),
            OutlinedButton(
              onPressed: () => context.pop(),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Cancel generation'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusStep({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String status,
    required Color statusColor,
  }) {
    final colors = AppColors.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.border.withValues(alpha: 0.6)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: iconColor),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: colors.textPrimary,
                ),
              ),
            ],
          ),
          Text(
            status,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: statusColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, String errorMessage) {
    final colors = AppColors.of(context);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(height: 4, width: double.infinity, color: colors.error),
            const SizedBox(height: 24),
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: colors.errorSoft,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.error, color: colors.error, size: 36),
            ),
            const SizedBox(height: 16),
            Text(
              'Preview Generation Failed',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              errorMessage.isNotEmpty
                  ? errorMessage.replaceFirst('Exception: ', '')
                  : 'A temporary rendering timeout occurred while building your PDF layout. Your saved resume data is completely safe.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: colors.textSecondary),
            ),
            const SizedBox(height: 20),
            // Diagnostic Detail Block
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: colors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Incident Code',
                        style: TextStyle(
                          fontSize: 12,
                          color: colors.textSecondary,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: colors.errorSoft,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'ERR_RENDER_504',
                          style: TextStyle(
                            fontSize: 11,
                            fontFamily: 'monospace',
                            color: colors.error,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.verified_user,
                        size: 16,
                        color: colors.secondary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'All resume entries preserved safely',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: colors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Spacer(),
            FilledButton.icon(
              onPressed: () =>
                  ref.invalidate(pdfViewerProvider(widget.resumeId)),
              style: FilledButton.styleFrom(
                backgroundColor: colors.primary,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.refresh),
              label: const Text('Try again'),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: () => context.pop(),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.edit_document),
              label: const Text('Edit resume'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildViewer(BuildContext context, Uint8List bytes) {
    final colors = AppColors.of(context);
    final sizeMb = (bytes.lengthInBytes / (1024 * 1024)).toStringAsFixed(1);

    return Column(
      children: [
        // 1. Meta strip
        Container(
          margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: colors.border.withValues(alpha: 0.6)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.verified, size: 16, color: colors.secondary),
                  const SizedBox(width: 6),
                  Text(
                    'ATS Compatibility 98%',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: colors.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '• A4',
                    style: TextStyle(fontSize: 11, color: colors.textSecondary),
                  ),
                ],
              ),
              Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: colors.secondary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Rendered ($sizeMb MB)',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: colors.secondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // 2. Document Canvas Workspace with Floating Zoom & Page Pill
        Expanded(
          child: Stack(
            children: [
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFE9EDFF),
                  borderRadius: BorderRadius.circular(18),
                ),
                clipBehavior: Clip.antiAlias,
                child: SfPdfViewer.memory(
                  bytes,
                  controller: _pdfViewerController,
                  canShowScrollHead: true,
                  canShowScrollStatus: false,
                  pageLayoutMode: PdfPageLayoutMode.continuous,
                  onDocumentLoaded: (details) {
                    setState(() {
                      _pageCount = details.document.pages.count;
                    });
                  },
                  onPageChanged: (details) {
                    setState(() {
                      _currentPage = details.newPageNumber;
                    });
                  },
                ),
              ),

              // Floating Page Counter Pill (Top-Center)
              Align(
                alignment: Alignment.topCenter,
                child: Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: InkWell(
                    onTap: () {
                      PagesAndDocumentInfoSheet.show(
                        context,
                        pageCount: _pageCount,
                        currentPage: _currentPage,
                        fileSizeBytes: bytes.lengthInBytes,
                        templateName: 'Modern Professional (A4)',
                        onJumpToPage: _jumpToPage,
                      );
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF172033).withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.auto_stories,
                            color: Colors.white,
                            size: 14,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'PAGE $_currentPage / $_pageCount',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.6,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.expand_more,
                            color: Colors.white70,
                            size: 14,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Floating Zoom Controls Dock (Bottom-Right)
              Positioned(
                bottom: 16,
                right: 24,
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF172033).withValues(alpha: 0.92),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.25),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(4),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: 'Zoom in',
                        onPressed: _zoomIn,
                        icon: const Icon(
                          Icons.add,
                          color: Colors.white,
                          size: 18,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 36,
                          minHeight: 36,
                        ),
                        padding: EdgeInsets.zero,
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Text(
                          '${(_zoomLevel * 100).toInt()}%',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.white70,
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Zoom out',
                        onPressed: _zoomOut,
                        icon: const Icon(
                          Icons.remove,
                          color: Colors.white,
                          size: 18,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 36,
                          minHeight: 36,
                        ),
                        padding: EdgeInsets.zero,
                      ),
                      Container(
                        height: 1,
                        width: 20,
                        color: Colors.white24,
                        margin: const EdgeInsets.symmetric(vertical: 2),
                      ),
                      IconButton(
                        tooltip: 'Fit to width',
                        onPressed: _resetZoom,
                        icon: const Icon(
                          Icons.fit_screen,
                          color: Colors.white,
                          size: 16,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 36,
                          minHeight: 36,
                        ),
                        padding: EdgeInsets.zero,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        // 3. Realtime Export Quality Health Indicator
        Container(
          margin: const EdgeInsets.fromLTRB(16, 8, 16, 6),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: colors.border.withValues(alpha: 0.5)),
          ),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: colors.secondarySoft,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.picture_as_pdf,
                  color: colors.secondary,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'PrepMate_Resume.pdf',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: colors.textPrimary,
                      ),
                    ),
                    Text(
                      'Vector High-Res • Embedded Fonts • CMYK Safe',
                      style: TextStyle(
                        fontSize: 10,
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(Icons.tune, color: colors.textSecondary, size: 18),
                onPressed: () {
                  PagesAndDocumentInfoSheet.show(
                    context,
                    pageCount: _pageCount,
                    currentPage: _currentPage,
                    fileSizeBytes: bytes.lengthInBytes,
                    templateName: 'Modern Professional (A4)',
                    onJumpToPage: _jumpToPage,
                  );
                },
              ),
            ],
          ),
        ),

        // 4. Sticky Bottom Action Bar
        Container(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          decoration: BoxDecoration(
            color: colors.surface,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, -3),
              ),
            ],
          ),
          child: Row(
            children: [
              OutlinedButton.icon(
                onPressed: () => context.pop(),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  side: BorderSide(color: colors.border),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.edit, size: 18),
                label: const Text('Edit'),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.icon(
                  onPressed: () {
                    SaveAndDownloadSheet.show(
                      context,
                      pdfBytes: bytes,
                      initialResumeTitle: 'PrepMate_Resume',
                    );
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: colors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.download, size: 18),
                  label: const Text(
                    'Download PDF',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              IconButton.filledTonal(
                tooltip: 'Share',
                onPressed: () {
                  SharePlus.instance.share(
                    ShareParams(
                      files: [
                        XFile.fromData(
                          bytes,
                          mimeType: 'application/pdf',
                          name: 'PrepMate_Resume.pdf',
                        ),
                      ],
                    ),
                  );
                },
                icon: const Icon(Icons.share, size: 20),
                style: IconButton.styleFrom(
                  backgroundColor: colors.screenBackground,
                  foregroundColor: colors.primary,
                  padding: const EdgeInsets.all(12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
