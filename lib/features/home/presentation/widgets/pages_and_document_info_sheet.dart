import 'package:flutter/material.dart';
import '../../../../config/theme.dart';

/// Modal bottom sheet matching Stitch screen 23:
/// PDF Preview — Thumbnail Navigator and Information.
///
/// Features:
/// - M3 segmented tabs: Pages (X) and Document Details
/// - Responsive page thumbnail grid with 'Viewing' badge and page selector
/// - Document details (ATS score, template, file size, timestamp)
/// - 'Jump to Page X' action
class PagesAndDocumentInfoSheet extends StatefulWidget {
  const PagesAndDocumentInfoSheet({
    super.key,
    required this.pageCount,
    required this.currentPage,
    required this.fileSizeBytes,
    required this.templateName,
    required this.onJumpToPage,
  });

  final int pageCount;
  final int currentPage;
  final int fileSizeBytes;
  final String templateName;
  final ValueChanged<int> onJumpToPage;

  static Future<void> show(
    BuildContext context, {
    required int pageCount,
    required int currentPage,
    required int fileSizeBytes,
    required String templateName,
    required ValueChanged<int> onJumpToPage,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => PagesAndDocumentInfoSheet(
        pageCount: pageCount,
        currentPage: currentPage,
        fileSizeBytes: fileSizeBytes,
        templateName: templateName,
        onJumpToPage: onJumpToPage,
      ),
    );
  }

  @override
  State<PagesAndDocumentInfoSheet> createState() =>
      _PagesAndDocumentInfoSheetState();
}

class _PagesAndDocumentInfoSheetState extends State<PagesAndDocumentInfoSheet> {
  int _selectedTabIndex = 0; // 0: Pages, 1: Details
  late int _targetedPage;

  @override
  void initState() {
    super.initState();
    _targetedPage = widget.currentPage;
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final sizeKb = (widget.fileSizeBytes / 1024).toStringAsFixed(0);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 44,
              height: 4,
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              decoration: BoxDecoration(
                color: colors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 16, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: colors.primarySoft,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.auto_stories,
                        color: colors.primary,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Pages & Document Info',
                      style: TextStyle(
                        fontSize: 16,
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
          ),

          // M3 Segmented Tabs
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _selectedTabIndex = 0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: _selectedTabIndex == 0
                                ? colors.primary
                                : Colors.transparent,
                            width: 2.5,
                          ),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.grid_view,
                            size: 16,
                            color: _selectedTabIndex == 0
                                ? colors.primary
                                : colors.textSecondary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Pages (${widget.pageCount})',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: _selectedTabIndex == 0
                                  ? colors.primary
                                  : colors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _selectedTabIndex = 1),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: _selectedTabIndex == 1
                                ? colors.primary
                                : Colors.transparent,
                            width: 2.5,
                          ),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 16,
                            color: _selectedTabIndex == 1
                                ? colors.primary
                                : colors.textSecondary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Document Details',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: _selectedTabIndex == 1
                                  ? colors.primary
                                  : colors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Tab Content
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: _selectedTabIndex == 0
                  ? _buildPagesTab(context)
                  : _buildDetailsTab(context, sizeKb),
            ),
          ),

          // Footer Dock
          Container(
            padding: EdgeInsets.fromLTRB(
              20,
              12,
              20,
              MediaQuery.of(context).viewInsets.bottom + 16,
            ),
            decoration: BoxDecoration(
              color: colors.surface,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF121B2E).withValues(alpha: 0.05),
                  blurRadius: 16,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: BorderSide(color: colors.border),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Dismiss'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () {
                      widget.onJumpToPage(_targetedPage);
                      Navigator.pop(context);
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: colors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.launch, size: 16),
                    label: Text('Jump to Page $_targetedPage'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPagesTab(BuildContext context) {
    final colors = AppColors.of(context);

    return Column(
      children: [
        // Status pill
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: colors.screenBackground,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.check_circle, size: 16, color: colors.secondary),
                  const SizedBox(width: 6),
                  Text(
                    '${widget.pageCount} ${widget.pageCount == 1 ? 'Page' : 'Pages'} generated',
                    style: TextStyle(fontSize: 12, color: colors.textSecondary),
                  ),
                ],
              ),
              Text(
                'A4 Standard',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: colors.primary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Grid of pages
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            childAspectRatio: 0.72,
          ),
          itemCount: widget.pageCount,
          itemBuilder: (context, index) {
            final pageNum = index + 1;
            final isTargeted = _targetedPage == pageNum;
            final isCurrent = widget.currentPage == pageNum;

            return InkWell(
              onTap: () => setState(() => _targetedPage = pageNum),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                decoration: BoxDecoration(
                  color: colors.screenBackground,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isTargeted ? colors.primary : colors.border,
                    width: isTargeted ? 2 : 1,
                  ),
                ),
                padding: const EdgeInsets.all(8),
                child: Column(
                  children: [
                    // Top tag (Viewing badge)
                    Align(
                      alignment: Alignment.topRight,
                      child: isCurrent
                          ? Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: colors.primary,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.visibility,
                                    color: Colors.white,
                                    size: 10,
                                  ),
                                  SizedBox(width: 3),
                                  Text(
                                    'Viewing',
                                    style: TextStyle(
                                      fontSize: 9,
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : const SizedBox(height: 16),
                    ),
                    const SizedBox(height: 4),
                    // Miniature representation
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 40,
                              height: 6,
                              color: colors.primarySoft,
                            ),
                            const SizedBox(height: 4),
                            Container(
                              width: 25,
                              height: 4,
                              color: colors.border,
                            ),
                            const Divider(height: 8),
                            Container(
                              width: 50,
                              height: 4,
                              color: colors.border,
                            ),
                            const SizedBox(height: 3),
                            Container(
                              width: 45,
                              height: 4,
                              color: colors.border,
                            ),
                            const SizedBox(height: 3),
                            Container(
                              width: 35,
                              height: 4,
                              color: colors.border,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Page $pageNum',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isTargeted
                                ? colors.primary
                                : colors.textPrimary,
                          ),
                        ),
                        Icon(
                          isTargeted
                              ? Icons.radio_button_checked
                              : Icons.radio_button_off,
                          size: 16,
                          color: isTargeted
                              ? colors.primary
                              : colors.textSecondary,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildDetailsTab(BuildContext context, String sizeKb) {
    final colors = AppColors.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ATS Card
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: colors.primarySoft.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colors.primary.withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: colors.primary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.verified,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ATS Compatibility 98%',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: colors.textPrimary,
                      ),
                    ),
                    Text(
                      'High keyword parsing affinity for target roles',
                      style: TextStyle(
                        fontSize: 11,
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Properties List
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: colors.screenBackground,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colors.border.withValues(alpha: 0.6)),
          ),
          child: Column(
            children: [
              _buildPropRow('Selected Template', widget.templateName),
              const Divider(height: 16),
              _buildPropRow('Generated File Size', '$sizeKb KB'),
              const Divider(height: 16),
              _buildPropRow('Last Generated', 'Just now'),
              const Divider(height: 16),
              _buildPropRow('Typography Engine', 'Vector Scalable Fonts'),
            ],
          ),
        ),
        const SizedBox(height: 14),

        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.tips_and_updates, size: 16, color: colors.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Exporting to PDF retains vector text shapes, ensuring your resume content is fully readable by automated applicant tracking software.',
                style: TextStyle(
                  fontSize: 12,
                  color: colors.textSecondary,
                  height: 1.3,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPropRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, color: Colors.grey)),
        Text(
          value,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
