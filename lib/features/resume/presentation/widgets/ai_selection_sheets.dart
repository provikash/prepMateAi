import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../config/theme.dart';
import '../../../home/data/models/resume_model.dart';
import '../../../home/providers/home_providers.dart';

/// Screen 35: AI Tool Input — Selection and Information Sheets
///
/// Provides the reusable Bottom Sheet for:
/// 1. Selecting an authenticated resume with search, filters, and readiness stats
/// 2. Inspecting tool information, limitations, credit policy, and privacy disclosure
class ResumeSelectionSheet extends ConsumerStatefulWidget {
  const ResumeSelectionSheet({
    super.key,
    required this.selectedResumeId,
    required this.onSelect,
    this.initialTab = 0,
    this.toolTitle = 'Professional Summary',
    this.toolCost = '1 credit',
    this.toolDescription =
        'Generates tailored, high-impact summary statements aligned to your target role.',
  });

  final String? selectedResumeId;
  final ValueChanged<ResumeModel> onSelect;
  final int initialTab;
  final String toolTitle;
  final String toolCost;
  final String toolDescription;

  static Future<ResumeModel?> show(
    BuildContext context, {
    String? selectedResumeId,
    int initialTab = 0,
    String toolTitle = 'Professional Summary',
    String toolCost = '1 credit',
    String toolDescription =
        'Generates tailored, high-impact summary statements aligned to your target role.',
  }) {
    return showModalBottomSheet<ResumeModel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ResumeSelectionSheet(
        selectedResumeId: selectedResumeId,
        initialTab: initialTab,
        toolTitle: toolTitle,
        toolCost: toolCost,
        toolDescription: toolDescription,
        onSelect: (resume) => Navigator.of(ctx).pop(resume),
      ),
    );
  }

  @override
  ConsumerState<ResumeSelectionSheet> createState() =>
      _ResumeSelectionSheetState();
}

class _ResumeSelectionSheetState extends ConsumerState<ResumeSelectionSheet> {
  late int _activeTab;
  final _searchController = TextEditingController();
  String _selectedFilter = 'All';

  @override
  void initState() {
    super.initState();
    _activeTab = widget.initialTab;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final textTheme = Theme.of(context).textTheme;
    final resumesAsync = ref.watch(resumeListProvider);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      decoration: BoxDecoration(
        color: colors.cardBackground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x26121B2E),
            blurRadius: 32,
            offset: Offset(0, -8),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: colors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                children: [
                  Icon(
                    _activeTab == 0
                        ? Icons.folder_shared_outlined
                        : Icons.info_outline,
                    color: colors.primary,
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _activeTab == 0 ? 'Choose Resume' : 'About This Tool',
                      style: textTheme.titleLarge?.copyWith(
                        color: colors.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: colors.textSecondary),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            // Segmented tab switch
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: colors.mutedBackground,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _activeTab = 0),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: _activeTab == 0
                                ? colors.cardBackground
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(999),
                            boxShadow: _activeTab == 0
                                ? [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.06,
                                      ),
                                      blurRadius: 4,
                                      offset: const Offset(0, 1),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.folder_shared,
                                size: 16,
                                color: _activeTab == 0
                                    ? colors.primary
                                    : colors.textSecondary,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Choose Resume',
                                style: textTheme.labelMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: _activeTab == 0
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
                      child: GestureDetector(
                        onTap: () => setState(() => _activeTab = 1),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: _activeTab == 1
                                ? colors.cardBackground
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(999),
                            boxShadow: _activeTab == 1
                                ? [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.06,
                                      ),
                                      blurRadius: 4,
                                      offset: const Offset(0, 1),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.info_outline,
                                size: 16,
                                color: _activeTab == 1
                                    ? colors.primary
                                    : colors.textSecondary,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'About This Tool',
                                style: textTheme.labelMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: _activeTab == 1
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
            ),
            const Divider(height: 1),
            // Content
            Expanded(
              child: _activeTab == 0
                  ? _buildResumeList(context, colors, textTheme, resumesAsync)
                  : _buildToolInfo(context, colors, textTheme),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResumeList(
    BuildContext context,
    AppColors colors,
    TextTheme textTheme,
    AsyncValue<List<ResumeModel>> resumesAsync,
  ) {
    return Column(
      children: [
        // Search bar
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
          child: TextField(
            controller: _searchController,
            onChanged: (val) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'Search your resumes...',
              prefixIcon: Icon(Icons.search, color: colors.textSecondary),
              filled: true,
              fillColor: colors.screenBackground,
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: colors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: colors.border),
              ),
            ),
          ),
        ),
        // Filter pills
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
          child: Row(
            children: [
              _buildFilterChip('All', colors),
              const SizedBox(width: 8),
              _buildFilterChip('Recently Edited', colors),
              const SizedBox(width: 8),
              _buildFilterChip('Ready for AI', colors),
            ],
          ),
        ),
        const SizedBox(height: 8),
        // Resume list
        Expanded(
          child: resumesAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) => Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.cloud_off, color: colors.error, size: 36),
                    const SizedBox(height: 8),
                    Text(
                      'Failed to load resumes',
                      style: textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      err.toString(),
                      textAlign: TextAlign.center,
                      style: textTheme.bodySmall?.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            data: (resumes) {
              final query = _searchController.text.trim().toLowerCase();
              final filtered = resumes.where((r) {
                if (query.isEmpty) return true;
                return r.title.toLowerCase().contains(query);
              }).toList();

              if (filtered.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.description_outlined,
                          size: 48,
                          color: colors.textSecondary.withValues(alpha: 0.5),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No resumes found',
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Create or import a resume to begin AI tailoring.',
                          textAlign: TextAlign.center,
                          style: textTheme.bodySmall?.copyWith(
                            color: colors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                itemCount: filtered.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final resume = filtered[index];
                  final isSelected = resume.id == widget.selectedResumeId;
                  return InkWell(
                    onTap: () => widget.onSelect(resume),
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? colors.mutedBackground
                            : colors.screenBackground,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected ? colors.primary : colors.border,
                          width: isSelected ? 1.5 : 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 22,
                                height: 22,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isSelected
                                      ? colors.primary
                                      : Colors.transparent,
                                  border: Border.all(
                                    color: isSelected
                                        ? colors.primary
                                        : colors.textSecondary,
                                    width: 2,
                                  ),
                                ),
                                child: isSelected
                                    ? const Icon(
                                        Icons.check,
                                        size: 14,
                                        color: Colors.white,
                                      )
                                    : null,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      resume.title,
                                      style: textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: colors.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${resume.templateId ?? "Standard Template"} · Updated ${resume.updatedAt != null ? _formatDate(resume.updatedAt!) : "Recently"}',
                                      style: textTheme.bodySmall?.copyWith(
                                        color: colors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: colors.secondarySoft,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '80% ready',
                                  style: textTheme.labelSmall?.copyWith(
                                    color: colors.secondary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: colors.cardBackground,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.verified,
                                  size: 15,
                                  color: colors.secondary,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '4 sections verified',
                                  style: textTheme.labelSmall?.copyWith(
                                    color: colors.secondary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const Spacer(),
                                SizedBox(
                                  width: 80,
                                  height: 6,
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(3),
                                    child: LinearProgressIndicator(
                                      value: 0.8,
                                      backgroundColor: colors.border,
                                      valueColor: AlwaysStoppedAnimation(
                                        colors.secondary,
                                      ),
                                    ),
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
        ),
      ],
    );
  }

  Widget _buildFilterChip(String label, AppColors colors) {
    final isSelected = _selectedFilter == label;
    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? colors.primary : colors.screenBackground,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: isSelected ? colors.primary : colors.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? Colors.white : colors.textPrimary,
          ),
        ),
      ),
    );
  }

  Widget _buildToolInfo(
    BuildContext context,
    AppColors colors,
    TextTheme textTheme,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colors.mutedBackground,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: colors.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.auto_awesome,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.toolTitle,
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.toolDescription,
                        style: textTheme.bodySmall?.copyWith(
                          color: colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _buildInfoRow(
            colors,
            textTheme,
            icon: Icons.toll,
            title: 'Credit Requirement',
            detail:
                'Requires ${widget.toolCost}. Credits are reserved at launch and only charged when results complete successfully. Failed runs are automatically refunded.',
          ),
          const SizedBox(height: 16),
          _buildInfoRow(
            colors,
            textTheme,
            icon: Icons.security,
            title: 'Data & Privacy Disclosures',
            detail:
                'Your resume details and target job description are processed through secure backend microservices. Your personal contact information is never sold or used for public AI model training.',
          ),
          const SizedBox(height: 16),
          _buildInfoRow(
            colors,
            textTheme,
            icon: Icons.fact_check_outlined,
            title: 'Accuracy & Human Review',
            detail:
                'AI results are drafts. Always inspect figures, technologies, dates, and metric claims before applying them to your master resume.',
          ),
          const SizedBox(height: 24),
          // Action button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: () => setState(() => _activeTab = 0),
              child: const Text('Back to Resume Selection'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    AppColors colors,
    TextTheme textTheme, {
    required IconData icon,
    required String title,
    required String detail,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: colors.screenBackground,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: colors.border),
          ),
          child: Icon(icon, color: colors.primary, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                detail,
                style: textTheme.bodySmall?.copyWith(
                  color: colors.textSecondary,
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}
