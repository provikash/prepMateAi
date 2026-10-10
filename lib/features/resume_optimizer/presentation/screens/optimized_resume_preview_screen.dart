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
import '../../domain/optimization_models.dart';
import '../providers/optimization_provider.dart';
import '../widgets/optimization_widgets.dart';

class OptimizedResumePreviewScreen extends ConsumerStatefulWidget {
  const OptimizedResumePreviewScreen({super.key});

  @override
  ConsumerState<OptimizedResumePreviewScreen> createState() =>
      _OptimizedResumePreviewScreenState();
}

class _OptimizedResumePreviewScreenState
    extends ConsumerState<OptimizedResumePreviewScreen> {
  double _zoomLevel = 1.0;
  String _comparisonSubMode =
      'difference'; // 'source', 'optimized', 'difference'
  PdfViewerController? _pdfViewerController;

  @override
  void initState() {
    super.initState();
    _pdfViewerController = PdfViewerController();
    Future.microtask(() {
      final versionId = ref.read(optimizationProvider).finalizedVersionId;
      if (versionId != null) {
        ref.read(optimizationProvider.notifier).loadOptimizedVersion(versionId);
      }
    });
  }

  @override
  void dispose() {
    _pdfViewerController?.dispose();
    super.dispose();
  }

  void _zoomIn() {
    setState(() {
      if (_zoomLevel < 2.0) _zoomLevel += 0.25;
      _pdfViewerController?.zoomLevel = _zoomLevel;
    });
  }

  void _zoomOut() {
    setState(() {
      if (_zoomLevel > 0.5) _zoomLevel -= 0.25;
      _pdfViewerController?.zoomLevel = _zoomLevel;
    });
  }

  void _zoomFit() {
    setState(() {
      _zoomLevel = 1.0;
      _pdfViewerController?.zoomLevel = 1.0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(optimizationProvider);
    final a = state.analysis;
    final resume = state.resume;
    final versionId = state.finalizedVersionId;

    if (resume == null && a == null) {
      return AppScaffold(
        title: 'Optimized Resume',
        body: const AppErrorState(
          message: 'Create or select an optimized version to preview.',
        ),
      );
    }

    final detail = state.optimizedVersionDetail;
    final changes =
        detail?.changes ??
        a?.suggestions
            .where(
              (s) =>
                  s.status == SuggestionStatus.accepted ||
                  s.status == SuggestionStatus.edited,
            )
            .toList() ??
        [];

    final role = state.jobTitle.isNotEmpty
        ? state.jobTitle
        : (detail?.targetRole.isNotEmpty == true
              ? detail!.targetRole
              : 'Senior Flutter Developer');
    final company = state.company.isNotEmpty
        ? state.company
        : (detail?.targetCompany.isNotEmpty == true
              ? detail!.targetCompany
              : 'Acme Technologies');

    final mode = state.viewerMode; // 'optimized', 'source', 'changes'
    final pdfState = state.pdfStatus;

    return AppScaffold(
      title: 'Optimized Resume',
      actions: [
        IconButton(
          tooltip: 'Document Information',
          onPressed: () => _showDocumentInfoSheet(
            context,
            state: state,
            detail: detail,
            role: role,
            company: company,
            changesCount: changes.length,
          ),
          icon: const Icon(Icons.info_outline),
        ),
        PopupMenuButton<String>(
          tooltip: 'More actions',
          onSelected: (val) {
            if (val == 'ats') {
              context.push('/resume/optimize/ats');
            } else if (val == 'template') {
              _showTemplateSelectorSheet(context);
            }
          },
          itemBuilder: (_) => const [
            PopupMenuItem(value: 'ats', child: Text('View ATS Analysis')),
            PopupMenuItem(value: 'template', child: Text('Change Template')),
          ],
        ),
      ],
      body: ResponsiveContent(
        maxWidth: 760,
        child: Column(
          children: [
            // Version Identity Banner (Screen 63)
            _buildVersionIdentityBanner(
              context,
              state: state,
              role: role,
              company: company,
              changesCount: changes.length,
            ),
            const SizedBox(height: 6),

            // Mode Selector: [Optimized] [Source] [Changes (N)] (Screen 63)
            _buildModeSelector(
              context,
              currentMode: mode,
              changesCount: changes.length,
            ),
            const SizedBox(height: 6),

            // Edge state warning banners (Screen 58)
            if (pdfState == 'outdated')
              _buildOutdatedPdfBanner(context)
            else if (pdfState == 'error')
              _buildFailedPdfBanner(context),

            // Main Canvas Area
            Expanded(
              child: switch (mode) {
                'source' => _buildSourceComparisonView(
                  context,
                  changes: changes,
                ),
                'changes' => _buildChangesModeView(
                  context,
                  changes: changes,
                  state: state,
                ),
                _ => _buildOptimizedViewer(context, versionId: versionId),
              },
            ),

            // Bottom Action Bar (Screen 63)
            _buildBottomBar(context, state: state, versionId: versionId),
          ],
        ),
      ),
    );
  }

  // ─── Version Identity Banner (Screen 63) ───────────────────────────────────

  Widget _buildVersionIdentityBanner(
    BuildContext context, {
    required OptimizationState state,
    required String role,
    required String company,
    required int changesCount,
  }) {
    final colors = AppColors.of(context);
    final template = state.selectedTemplate;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.cardBackground,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF93F0E8),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.check_circle,
                      size: 12,
                      color: Color(0xFF006A65),
                    ),
                    SizedBox(width: 4),
                    Text(
                      'CURRENT VERSION',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF006A65),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: colors.mutedBackground,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  template,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: colors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            state.versionName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 2),
          Text(
            'Target: $role at $company · $changesCount tailored changes applied',
            style: TextStyle(fontSize: 12, color: colors.textSecondary),
          ),
        ],
      ),
    );
  }

  // ─── Mode Selector (Screen 63) ─────────────────────────────────────────────

  Widget _buildModeSelector(
    BuildContext context, {
    required String currentMode,
    required int changesCount,
  }) {
    final colors = AppColors.of(context);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: colors.mutedBackground,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildModeTab(
              context,
              label: 'Optimized',
              icon: Icons.auto_awesome,
              isSelected: currentMode == 'optimized',
              onTap: () => ref
                  .read(optimizationProvider.notifier)
                  .setViewerMode('optimized'),
            ),
          ),
          Expanded(
            child: _buildModeTab(
              context,
              label: 'Source',
              icon: Icons.history,
              isSelected: currentMode == 'source',
              onTap: () => ref
                  .read(optimizationProvider.notifier)
                  .setViewerMode('source'),
            ),
          ),
          Expanded(
            child: _buildModeTab(
              context,
              label: 'Changes ($changesCount)',
              icon: Icons.rule,
              isSelected: currentMode == 'changes',
              onTap: () => ref
                  .read(optimizationProvider.notifier)
                  .setViewerMode('changes'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeTab(
    BuildContext context, {
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final colors = AppColors.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? colors.cardBackground : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: isSelected
              ? const [
                  BoxShadow(
                    color: Color(0x0C000000),
                    blurRadius: 4,
                    offset: Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 15,
              color: isSelected ? colors.primary : colors.textSecondary,
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? colors.primary : colors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Screen 58 Edge State Banners ──────────────────────────────────────────

  Widget _buildOutdatedPdfBanner(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFE0B2).withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.sync_problem, size: 18, color: Colors.deepOrange),
          const SizedBox(width: 8),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Document Outdated',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.deepOrange,
                  ),
                ),
                Text(
                  'Changes were made since this PDF was generated · Preview needs refresh',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          FilledButton.tonal(
            onPressed: () {
              final versionId = ref
                  .read(optimizationProvider)
                  .finalizedVersionId;
              if (versionId != null) {
                ref.invalidate(optimizedVersionPdfProvider(versionId));
              }
            },
            style: FilledButton.styleFrom(
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.symmetric(horizontal: 10),
            ),
            child: const Text('Update Preview', style: TextStyle(fontSize: 11)),
          ),
        ],
      ),
    );
  }

  Widget _buildFailedPdfBanner(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFDAD6).withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFBA1A1A).withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, size: 18, color: Color(0xFFBA1A1A)),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'PDF generation failed. Structured version is safe.',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
            ),
          ),
          TextButton(
            onPressed: () {
              final versionId = ref
                  .read(optimizationProvider)
                  .finalizedVersionId;
              if (versionId != null) {
                ref.invalidate(optimizedVersionPdfProvider(versionId));
              }
            },
            child: const Text('Retry', style: TextStyle(fontSize: 11)),
          ),
        ],
      ),
    );
  }

  // ─── Mode 1: Optimized Viewer (Screen 63) ──────────────────────────────────

  Widget _buildOptimizedViewer(
    BuildContext context, {
    required String? versionId,
  }) {
    if (versionId == null) {
      return _buildSimulatedPaperCanvas(context);
    }

    final pdf = ref.watch(optimizedVersionPdfProvider(versionId));

    return Column(
      children: [
        // Viewer Toolbar (Page indicator & Zoom controls)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.of(context).mutedBackground,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.auto_stories, size: 14),
                    SizedBox(width: 4),
                    Text(
                      'Page 1 of 2',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove, size: 16),
                    onPressed: _zoomOut,
                    visualDensity: VisualDensity.compact,
                  ),
                  Text(
                    '${(_zoomLevel * 100).toInt()}%',
                    style: const TextStyle(fontSize: 12),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add, size: 16),
                    onPressed: _zoomIn,
                    visualDensity: VisualDensity.compact,
                  ),
                  IconButton(
                    icon: const Icon(Icons.fit_screen, size: 16),
                    onPressed: _zoomFit,
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFE9ECF2),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: pdf.when(
              loading: () => const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 12),
                    Text('Rendering high-fidelity PDF...'),
                  ],
                ),
              ),
              error: (_, __) => _buildSimulatedPaperCanvas(context),
              data: (bytes) {
                if (bytes.isEmpty) {
                  return _buildSimulatedPaperCanvas(context);
                }
                return SfPdfViewer.memory(
                  bytes,
                  controller: _pdfViewerController,
                  canShowPaginationDialog: true,
                  canShowScrollHead: true,
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSimulatedPaperCanvas(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Center(
        child: Container(
          width: 380 * _zoomLevel,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(6),
            boxShadow: const [
              BoxShadow(
                color: Color(0x18000000),
                blurRadius: 16,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.of(context).primary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 12),
              const Center(
                child: Text(
                  'VIKASH CHAURASIYA',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              Center(
                child: Text(
                  'Senior Mobile & Flutter Engineer',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.of(context).primary,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Center(
                child: Text(
                  'Austin, TX · vikash@example.com · github.com/provikash',
                  style: TextStyle(
                    fontSize: 10,
                    color: AppColors.of(context).textSecondary,
                  ),
                ),
              ),
              const Divider(height: 24),
              const Text(
                'PROFESSIONAL SUMMARY',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              const Text(
                'Accomplished Mobile Architect with 4+ years spearheading fintech mobile ecosystems. '
                'Pioneered offline-first cache synchronization reducing API latency by 35% across 120k active DAU.',
                style: TextStyle(fontSize: 11, height: 1.4),
              ),
              const SizedBox(height: 12),
              const Text(
                'WORK EXPERIENCE',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              const Text(
                'Lead Mobile Developer | Acme Technologies (2021 – Present)',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
              ),
              const Text(
                '• Architected high-performance Flutter mobile application with Riverpod 2.x\n'
                '• Built SQLite cache synchronization engine maintaining 99.9% offline uptime\n'
                '• Spearheaded engineering design system rollout boosting velocity by 25%',
                style: TextStyle(fontSize: 11, height: 1.4),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Mode 2: Source Comparison (Screen 59) ─────────────────────────────────

  Widget _buildSourceComparisonView(
    BuildContext context, {
    required List<dynamic> changes,
  }) {
    final colors = AppColors.of(context);
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        // Sub-mode pill switcher: [Source] [Optimized] [Difference]
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildSubPill('source', 'Source'),
            const SizedBox(width: 8),
            _buildSubPill('optimized', 'Optimized'),
            const SizedBox(width: 8),
            _buildSubPill('difference', 'Difference'),
          ],
        ),
        const SizedBox(height: AppSpacing.md),

        if (changes.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Text('No comparative changes recorded.'),
            ),
          )
        else
          ...changes.map((c) {
            String original = '';
            String proposed = '';
            String section = 'General';

            if (c is OptimizationSuggestion) {
              original = c.current;
              proposed = c.proposed;
              section = c.section;
            } else if (c is Map<String, dynamic>) {
              original = c['original_value']?.toString() ?? '';
              proposed = c['accepted_value']?.toString() ?? '';
              section = c['section']?.toString() ?? 'General';
            }

            return Container(
              margin: const EdgeInsets.only(bottom: AppSpacing.sm),
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: colors.cardBackground,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: colors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        section,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF93F0E8).withOpacity(0.5),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'Applied',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF006A65),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  if (_comparisonSubMode == 'source' ||
                      _comparisonSubMode == 'difference') ...[
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFDAD6).withOpacity(0.3),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'ORIGINAL SOURCE',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFFBA1A1A),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            original.isNotEmpty
                                ? original
                                : '(New section content)',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                  ],

                  if (_comparisonSubMode == 'optimized' ||
                      _comparisonSubMode == 'difference') ...[
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF93F0E8).withOpacity(0.3),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'FINAL OPTIMIZED',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF006A65),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            proposed,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            );
          }),
      ],
    );
  }

  Widget _buildSubPill(String key, String label) {
    final isSelected = _comparisonSubMode == key;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) {
        setState(() {
          _comparisonSubMode = key;
        });
      },
      selectedColor: AppColors.of(context).primary,
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: isSelected ? Colors.white : AppColors.of(context).textPrimary,
      ),
    );
  }

  // ─── Mode 3: Changes Mode & Revert (Screen 61) ─────────────────────────────

  Widget _buildChangesModeView(
    BuildContext context, {
    required List<dynamic> changes,
    required OptimizationState state,
  }) {
    if (changes.isEmpty) {
      return const Center(
        child: Text('No active tailored changes on this optimized version.'),
      );
    }

    final activeIndex = state.activeChangeIndex.clamp(0, changes.length - 1);
    final currentChange = changes[activeIndex];

    String original = '';
    String proposed = '';
    String section = 'General';
    String changeId = '';

    if (currentChange is OptimizationSuggestion) {
      original = currentChange.current;
      proposed = currentChange.proposed;
      section = currentChange.section;
      changeId = currentChange.id;
    } else if (currentChange is Map<String, dynamic>) {
      original = currentChange['original_value']?.toString() ?? '';
      proposed = currentChange['accepted_value']?.toString() ?? '';
      section = currentChange['section']?.toString() ?? 'General';
      changeId = currentChange['id']?.toString() ?? '';
    }

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        // Change Navigator Strip: Change X of Y (Screen 61)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.of(context).cardBackground,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: AppColors.of(context).border),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: activeIndex > 0
                    ? () => ref
                          .read(optimizationProvider.notifier)
                          .setActiveChangeIndex(activeIndex - 1)
                    : null,
              ),
              Text(
                'Change ${activeIndex + 1} of ${changes.length}',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: activeIndex < changes.length - 1
                    ? () => ref
                          .read(optimizationProvider.notifier)
                          .setActiveChangeIndex(activeIndex + 1)
                    : null,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        // Change Details Card (Screen 61)
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.of(context).cardBackground,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: AppColors.of(context).border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    section,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.of(context).primarySoft,
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                    child: Text(
                      'Tailored bullet',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.of(context).primary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                'PROPOSED IMPROVEMENT',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF006A65),
                ),
              ),
              const SizedBox(height: 4),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF93F0E8).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  proposed,
                  style: const TextStyle(fontSize: 13, height: 1.3),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'ORIGINAL BASELINE',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.of(context).mutedBackground,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  original.isNotEmpty ? original : '(Empty originally)',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.of(context).textSecondary,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Revert Change Action (Screen 61)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () =>
                      _confirmRevertChange(context, changeId: changeId),
                  icon: const Icon(Icons.undo, size: 16, color: Colors.red),
                  label: const Text(
                    'Revert This Change',
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Center(
                child: Text(
                  'Reverting affects only this draft version. Master resume stays 100% safe.',
                  style: TextStyle(
                    fontSize: 10,
                    color: AppColors.of(context).textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ─── Bottom Action Bar (Screen 63) ─────────────────────────────────────────

  Widget _buildBottomBar(
    BuildContext context, {
    required OptimizationState state,
    required String? versionId,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.of(context).cardBackground,
        boxShadow: const [
          BoxShadow(
            color: Color(0x10000000),
            blurRadius: 8,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: AppSecondaryButton(
              label: 'Edit in Builder',
              icon: Icons.edit_note,
              onPressed: () => context.push('/resume/form'),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: AppPrimaryButton(
              label: 'Share PDF',
              icon: Icons.share,
              onPressed: () async {
                if (versionId == null) return;
                final pdf = ref.read(optimizedVersionPdfProvider(versionId));
                final bytes = pdf.asData?.value;
                if (bytes != null) {
                  await SharePlus.instance.share(
                    ShareParams(
                      files: [
                        XFile.fromData(
                          Uint8List.fromList(bytes),
                          mimeType: 'application/pdf',
                          name: '${state.versionName}.pdf',
                        ),
                      ],
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Rendering PDF. Please wait...'),
                    ),
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  // ─── Confirmation & Bottom Sheets ──────────────────────────────────────────

  void _confirmRevertChange(BuildContext context, {required String changeId}) {
    showDialog<void>(
      context: context,
      builder: (dContext) => AlertDialog(
        title: const Text('Revert this change?'),
        content: const Text(
          'This will restore the original baseline text for this section in your optimized draft. Your base master resume remains untouched.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dContext),
            child: const Text('Keep Change'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(dContext);
              final messenger = ScaffoldMessenger.of(context);
              final ok = await ref
                  .read(optimizationProvider.notifier)
                  .revertChange(changeId);
              if (ok && mounted) {
                messenger.showSnackBar(
                  const SnackBar(
                    content: Text('Change reverted in draft version.'),
                  ),
                );
              }
            },
            child: const Text('Revert'),
          ),
        ],
      ),
    );
  }

  void _showDocumentInfoSheet(
    BuildContext context, {
    required OptimizationState state,
    dynamic detail,
    required String role,
    required String company,
    required int changesCount,
  }) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Document Information',
                style: Theme.of(
                  sheetContext,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 16),
              _buildInfoRow('Resume Name', state.versionName),
              _buildInfoRow('Target Role', '$role at $company'),
              _buildInfoRow('Template', state.selectedTemplate),
              _buildInfoRow(
                'Applied Changes',
                '$changesCount tailored changes',
              ),
              _buildInfoRow(
                'Private Storage',
                'Saved securely to your PrepMate account',
              ),
              _buildInfoRow('Document State', 'Authoritative versioned draft'),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.pop(sheetContext),
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  void _showTemplateSelectorSheet(BuildContext context) {
    const templates = [
      'Modern Professional Duo',
      'Minimalist Tech',
      'Executive Clean',
      'Contemporary Slate',
    ];

    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Change Resume Template',
                style: Theme.of(
                  sheetContext,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              const Text(
                'Template changes do not consume AI credits and preserve all your tailored content.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              ...templates.map((t) {
                final isSelected =
                    ref.read(optimizationProvider).selectedTemplate == t;
                return ListTile(
                  title: Text(t, style: const TextStyle(fontSize: 14)),
                  trailing: isSelected
                      ? const Icon(Icons.check, color: Color(0xFF2457D6))
                      : null,
                  onTap: () {
                    ref
                        .read(optimizationProvider.notifier)
                        .updateTemplate(t, t);
                    Navigator.pop(sheetContext);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Template changed to $t. PDF preview marked outdated.',
                        ),
                      ),
                    );
                  },
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}
