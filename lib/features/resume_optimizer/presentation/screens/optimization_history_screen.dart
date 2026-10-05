import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../config/theme.dart';
import '../../domain/optimization_models.dart';
import '../providers/optimization_sessions_provider.dart';
import '../widgets/optimization_empty_states.dart';
import '../widgets/optimization_filter_sort_sheet.dart';
import '../widgets/optimization_session_card.dart';

/// Screen 39: Optimization History — Populated
/// Incorporates Screen 36 (Status Variants), Screen 37 (Filter & Sort Sheet),
/// and Screen 38 (Search and Empty States).
class OptimizationHistoryScreen extends ConsumerStatefulWidget {
  const OptimizationHistoryScreen({super.key});

  @override
  ConsumerState<OptimizationHistoryScreen> createState() =>
      _OptimizationHistoryScreenState();
}

class _OptimizationHistoryScreenState
    extends ConsumerState<OptimizationHistoryScreen> {
  final _searchController = TextEditingController();
  bool _isSearchExpanded = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openFilterModal(OptimizationHistoryState state) async {
    final newFilter = await OptimizationFilterSortSheet.show(
      context,
      initialFilter: state.filter,
    );
    if (newFilter != null) {
      ref
          .read(optimizationHistoryProvider.notifier)
          .setFilters(
            status: newFilter.statusFilter,
            resumeId: newFilter.selectedResumeId,
            ordering: newFilter.ordering,
          );
    }
  }

  void _navigateToSession(OptimizationSessionModel session) {
    context.push('/resume/optimize/detail/${session.id}');
  }

  void _confirmDelete(OptimizationSessionModel session) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Optimization?'),
        content: Text(
          'Are you sure you want to remove the optimization run for "${session.jobDescription?.title ?? "this role"}"? The source resume will NOT be deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(ctx).colorScheme.error,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref
          .read(optimizationHistoryProvider.notifier)
          .deleteSession(session.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Optimization session deleted.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final textTheme = Theme.of(context).textTheme;
    final state = ref.watch(optimizationHistoryProvider);

    return Scaffold(
      backgroundColor: colors.screenBackground,
      appBar: AppBar(
        backgroundColor: colors.cardBackground,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: _isSearchExpanded
            ? TextField(
                controller: _searchController,
                autofocus: true,
                style: TextStyle(color: colors.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Search roles, companies...',
                  hintStyle: TextStyle(color: colors.textSecondary),
                  border: InputBorder.none,
                ),
                onChanged: (val) {
                  ref
                      .read(optimizationHistoryProvider.notifier)
                      .setSearchQuery(val);
                },
              )
            : Text(
                'Optimization History',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colors.textPrimary,
                ),
              ),
        actions: [
          IconButton(
            icon: Icon(
              _isSearchExpanded ? Icons.close : Icons.search,
              color: colors.textPrimary,
            ),
            onPressed: () {
              setState(() {
                if (_isSearchExpanded) {
                  _searchController.clear();
                  ref
                      .read(optimizationHistoryProvider.notifier)
                      .setSearchQuery('');
                  _isSearchExpanded = false;
                } else {
                  _isSearchExpanded = true;
                }
              });
            },
          ),
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: Icon(Icons.tune, color: colors.textPrimary),
                onPressed: () => _openFilterModal(state),
              ),
              if (state.filter.activeFilterCount > 0)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: colors.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: colors.primary,
        foregroundColor: Colors.white,
        onPressed: () {
          context.push('/resume/optimize');
        },
        icon: const Icon(Icons.auto_awesome, size: 20),
        label: const Text(
          'New Optimization',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () => ref
            .read(optimizationHistoryProvider.notifier)
            .loadSessions(refresh: true),
        child: Column(
          children: [
            // Status Pills Strip
            Container(
              color: colors.cardBackground,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterPill('all', 'All', state, colors),
                    const SizedBox(width: 8),
                    _buildFilterPill(
                      'in_progress',
                      'In Progress',
                      state,
                      colors,
                    ),
                    const SizedBox(width: 8),
                    _buildFilterPill('completed', 'Completed', state, colors),
                    const SizedBox(width: 8),
                    _buildFilterPill(
                      'needs_attention',
                      'Needs Attention',
                      state,
                      colors,
                    ),
                    const SizedBox(width: 8),
                    _buildFilterPill('draft', 'Drafts', state, colors),
                    const SizedBox(width: 8),
                    _buildFilterPill('archived', 'Archived', state, colors),
                  ],
                ),
              ),
            ),
            const Divider(height: 1),

            // Offline banner
            if (state.isOffline) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                color: const Color(0xFFFEF3C7),
                child: Row(
                  children: [
                    const Icon(
                      Icons.wifi_off,
                      size: 16,
                      color: Color(0xFFB45309),
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Offline Mode · Showing cached session history.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFFB45309),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Content Body
            Expanded(child: _buildBody(state, colors, textTheme)),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(
    OptimizationHistoryState state,
    AppColors colors,
    TextTheme textTheme,
  ) {
    if (state.isLoading && state.sessions.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null && state.sessions.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 48, color: colors.error),
              const SizedBox(height: 12),
              Text(
                'Unable to load optimizations',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                state.error!,
                textAlign: TextAlign.center,
                style: textTheme.bodySmall?.copyWith(
                  color: colors.textSecondary,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () => ref
                    .read(optimizationHistoryProvider.notifier)
                    .loadSessions(),
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (state.sessions.isEmpty) {
      if (state.filter.searchQuery.isNotEmpty) {
        return OptimizationNoSearchResultsState(
          query: state.filter.searchQuery,
          onClearSearch: () {
            _searchController.clear();
            ref.read(optimizationHistoryProvider.notifier).setSearchQuery('');
          },
          onViewAll: () {
            _searchController.clear();
            ref.read(optimizationHistoryProvider.notifier).resetFilters();
          },
        );
      }
      return OptimizationZeroState(
        onStartOptimization: () => context.push('/resume/optimize'),
        onHowItWorks: () => _openHowItWorksSheet(colors, textTheme),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      itemCount: state.sessions.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final session = state.sessions[index];
        return OptimizationSessionCard(
          session: session,
          onTap: () => _navigateToSession(session),
          onPrimaryAction: () => _navigateToSession(session),
          onArchive: () => ref
              .read(optimizationHistoryProvider.notifier)
              .archiveSession(session.id),
          onDelete: () => _confirmDelete(session),
          onDuplicate: () {
            context.push('/resume/optimize');
          },
        );
      },
    );
  }

  Widget _buildFilterPill(
    String key,
    String label,
    OptimizationHistoryState state,
    AppColors colors,
  ) {
    final isSelected = state.filter.statusFilter == key;
    return GestureDetector(
      onTap: () =>
          ref.read(optimizationHistoryProvider.notifier).setStatusFilter(key),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? colors.primary : colors.mutedBackground,
          borderRadius: BorderRadius.circular(999),
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

  void _openHowItWorksSheet(AppColors colors, TextTheme textTheme) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: colors.cardBackground,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: colors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'How PrepMate Resume Optimization Works',
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            _buildExplanationStep(
              '1',
              'Match Extraction',
              'We parse the job description for key technical proficiencies, soft skills, and ATS filters.',
              colors,
            ),
            _buildExplanationStep(
              '2',
              'Evidence Mapping',
              'We evaluate your resume achievements against the requirements without fabricating claims.',
              colors,
            ),
            _buildExplanationStep(
              '3',
              'Targeted Suggestions',
              'Review actionable bullet polish recommendations with metric anchoring.',
              colors,
            ),
            _buildExplanationStep(
              '4',
              'Final Export',
              'Export an ATS-tailored resume version calibrated specifically for the target employer.',
              colors,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Got it'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExplanationStep(
    String step,
    String title,
    String desc,
    AppColors colors,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 12,
            backgroundColor: colors.primary,
            child: Text(
              step,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 2),
                Text(
                  desc,
                  style: TextStyle(
                    fontSize: 12,
                    color: colors.textSecondary,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
