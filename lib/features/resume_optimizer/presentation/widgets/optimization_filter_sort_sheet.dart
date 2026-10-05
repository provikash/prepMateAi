import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../config/theme.dart';
import '../../../home/providers/home_providers.dart';
import '../providers/optimization_sessions_provider.dart';

/// Screen 37: Optimization History — Filter and Sort Sheet
///
/// Material 3 Bottom Sheet allowing users to:
/// - Quick Sort: Recently updated, Newest created, Oldest created, Company A-Z, Target role A-Z
/// - Status Filter: All, In Progress, Completed, Needs Attention, Drafts, Archived
/// - Source Resume: Pick a specific linked resume
class OptimizationFilterSortSheet extends ConsumerStatefulWidget {
  const OptimizationFilterSortSheet({
    super.key,
    required this.initialFilter,
    required this.onApply,
  });

  final OptimizationHistoryFilter initialFilter;
  final ValueChanged<OptimizationHistoryFilter> onApply;

  static Future<OptimizationHistoryFilter?> show(
    BuildContext context, {
    required OptimizationHistoryFilter initialFilter,
  }) {
    return showModalBottomSheet<OptimizationHistoryFilter>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => OptimizationFilterSortSheet(
        initialFilter: initialFilter,
        onApply: (filter) => Navigator.of(ctx).pop(filter),
      ),
    );
  }

  @override
  ConsumerState<OptimizationFilterSortSheet> createState() =>
      _OptimizationFilterSortSheetState();
}

class _OptimizationFilterSortSheetState
    extends ConsumerState<OptimizationFilterSortSheet> {
  late String _ordering;
  late String _statusFilter;
  String? _selectedResumeId;

  @override
  void initState() {
    super.initState();
    _ordering = widget.initialFilter.ordering;
    _statusFilter = widget.initialFilter.statusFilter;
    _selectedResumeId = widget.initialFilter.selectedResumeId;
  }

  int get _activeCount {
    var count = 0;
    if (_statusFilter != 'all') count++;
    if (_selectedResumeId != null && _selectedResumeId!.isNotEmpty) count++;
    if (_ordering != 'recently_updated') count++;
    return count;
  }

  void _reset() {
    setState(() {
      _ordering = 'recently_updated';
      _statusFilter = 'all';
      _selectedResumeId = null;
    });
  }

  void _apply() {
    widget.onApply(
      widget.initialFilter.copyWith(
        ordering: _ordering,
        statusFilter: _statusFilter,
        selectedResumeId: _selectedResumeId,
        clearResume: _selectedResumeId == null || _selectedResumeId!.isEmpty,
      ),
    );
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
                  Icon(Icons.tune, color: colors.primary, size: 24),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Filter & Sort Optimizations',
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colors.textPrimary,
                          ),
                        ),
                        Text(
                          'Narrow down by role, status, and resume',
                          style: textTheme.bodySmall?.copyWith(
                            color: colors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: colors.textSecondary),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // Scrollable Options Body
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Section 1: Quick Sort
                    _buildSectionHeader(
                      'QUICK SORT',
                      'Single selection',
                      colors,
                      textTheme,
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: colors.mutedBackground,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: colors.border),
                      ),
                      child: Column(
                        children: [
                          _buildSortTile(
                            'recently_updated',
                            'Recently updated',
                            Icons.schedule,
                            colors,
                            textTheme,
                          ),
                          const Divider(height: 1),
                          _buildSortTile(
                            'newest',
                            'Newest created',
                            Icons.arrow_downward,
                            colors,
                            textTheme,
                          ),
                          const Divider(height: 1),
                          _buildSortTile(
                            'oldest',
                            'Oldest created',
                            Icons.arrow_upward,
                            colors,
                            textTheme,
                          ),
                          const Divider(height: 1),
                          _buildSortTile(
                            'company',
                            'Company A–Z',
                            Icons.business,
                            colors,
                            textTheme,
                          ),
                          const Divider(height: 1),
                          _buildSortTile(
                            'role',
                            'Target role A–Z',
                            Icons.badge,
                            colors,
                            textTheme,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Section 2: Session Status
                    _buildSectionHeader(
                      'SESSION STATUS',
                      'Filter by progress',
                      colors,
                      textTheme,
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildStatusChip('all', 'All Statuses', colors),
                        _buildStatusChip('in_progress', 'In Progress', colors),
                        _buildStatusChip('completed', 'Completed', colors),
                        _buildStatusChip(
                          'needs_attention',
                          'Needs Attention',
                          colors,
                        ),
                        _buildStatusChip('draft', 'Drafts', colors),
                        _buildStatusChip('archived', 'Archived', colors),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Section 3: Filter by Source Resume
                    _buildSectionHeader(
                      'SOURCE RESUME',
                      'Filter by origin',
                      colors,
                      textTheme,
                    ),
                    const SizedBox(height: 10),
                    resumesAsync.when(
                      data: (resumes) {
                        return SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              _buildResumeCard(
                                null,
                                'All Resumes',
                                'Show all sessions',
                                colors,
                                textTheme,
                              ),
                              ...resumes.map(
                                (r) => Padding(
                                  padding: const EdgeInsets.only(left: 8),
                                  child: _buildResumeCard(
                                    r.id,
                                    r.title,
                                    r.templateId ?? 'Template',
                                    colors,
                                    textTheme,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                      loading: () => const Center(
                        child: Padding(
                          padding: EdgeInsets.all(12),
                          child: CircularProgressIndicator(),
                        ),
                      ),
                      error: (_, __) => Text(
                        'Unable to load resumes list',
                        style: textTheme.bodySmall?.copyWith(
                          color: colors.error,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const Divider(height: 1),
            // Bottom Action Bar
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    flex: 1,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: colors.textPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: _reset,
                      child: const Text('Reset All'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: _apply,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('Show Results'),
                          if (_activeCount > 0) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.25),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '$_activeCount',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ],
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
  }

  Widget _buildSectionHeader(
    String title,
    String subtitle,
    AppColors colors,
    TextTheme textTheme,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: textTheme.labelSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: colors.textSecondary,
            letterSpacing: 0.5,
          ),
        ),
        Text(
          subtitle,
          style: textTheme.bodySmall?.copyWith(
            color: colors.primary,
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  Widget _buildSortTile(
    String value,
    String title,
    IconData icon,
    AppColors colors,
    TextTheme textTheme,
  ) {
    final isSelected = _ordering == value;
    return InkWell(
      onTap: () => setState(() => _ordering = value),
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? colors.primary : colors.border,
                  width: isSelected ? 5 : 1.5,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: textTheme.bodyMedium?.copyWith(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? colors.primary : colors.textPrimary,
                ),
              ),
            ),
            Icon(
              icon,
              size: 18,
              color: isSelected ? colors.primary : colors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(String value, String label, AppColors colors) {
    final isSelected = _statusFilter == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: colors.primary,
      backgroundColor: colors.mutedBackground,
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
        color: isSelected ? Colors.white : colors.textPrimary,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: isSelected ? colors.primary : colors.border),
      ),
      onSelected: (_) => setState(() => _statusFilter = value),
    );
  }

  Widget _buildResumeCard(
    String? id,
    String title,
    String subtitle,
    AppColors colors,
    TextTheme textTheme,
  ) {
    final isSelected = _selectedResumeId == id;
    return GestureDetector(
      onTap: () => setState(() => _selectedResumeId = id),
      child: Container(
        width: 140,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? colors.primary : colors.mutedBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? colors.primary : colors.border,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              id == null ? Icons.folder_open : Icons.description_outlined,
              size: 20,
              color: isSelected ? Colors.white : colors.primary,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : colors.textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: textTheme.bodySmall?.copyWith(
                fontSize: 10,
                color: isSelected
                    ? Colors.white.withValues(alpha: 0.8)
                    : colors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
