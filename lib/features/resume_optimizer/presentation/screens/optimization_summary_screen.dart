import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../config/theme.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/app_state.dart';
import '../../domain/optimization_models.dart';
import '../providers/optimization_provider.dart';
import '../widgets/optimization_widgets.dart';

class OptimizationSummaryScreen extends ConsumerStatefulWidget {
  const OptimizationSummaryScreen({super.key});

  @override
  ConsumerState<OptimizationSummaryScreen> createState() =>
      _OptimizationSummaryScreenState();
}

class _OptimizationSummaryScreenState
    extends ConsumerState<OptimizationSummaryScreen>
    with SingleTickerProviderStateMixin {
  final Set<String> _expandedSections = <String>{};
  bool _skippedExpanded = false;
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _shakeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).chain(CurveTween(curve: Curves.elasticIn)).animate(_shakeController);

    Future.microtask(() {
      ref.read(optimizationProvider.notifier).loadSummary();
    });
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  void _triggerShake() {
    _shakeController.forward(from: 0.0);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(optimizationProvider);
    final a = state.analysis;

    if (a == null) {
      return AppScaffold(
        title: 'Optimization Summary',
        body: const AppErrorState(
          message: 'No active optimization session was found.',
        ),
      );
    }

    final acceptedList = a.suggestions
        .where((s) => s.status == SuggestionStatus.accepted)
        .toList();
    final editedList = a.suggestions
        .where((s) => s.status == SuggestionStatus.edited)
        .toList();
    final skippedList = a.suggestions
        .where((s) => s.status == SuggestionStatus.rejected)
        .toList();
    final pendingList = a.suggestions
        .where((s) => s.status == SuggestionStatus.pending)
        .toList();

    final groups = <String, List<OptimizationSuggestion>>{};
    for (final s in a.suggestions) {
      (groups[s.section] ??= []).add(s);
    }

    // Default expand first section on first build
    if (_expandedSections.isEmpty && groups.isNotEmpty) {
      _expandedSections.add(groups.keys.first);
    }

    final role = state.jobTitle.isNotEmpty ? state.jobTitle : 'Target Role';
    final company = state.company.isNotEmpty ? state.company : 'Target Company';
    final sourceResumeName = state.resume?.title.isNotEmpty == true
        ? state.resume!.title
        : 'Software Engineer Resume (v2.4)';

    final edgeState = state.summaryEdgeState;

    return AppScaffold(
      title: 'Optimization Summary',
      body: ResponsiveContent(
        maxWidth: 720,
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
                children: [
                  const OptimizationStepHeader(step: 3),
                  const SizedBox(height: AppSpacing.md),

                  // Edge state simulator switcher (Screen 60)
                  _buildEdgeStateSelector(context, edgeState),
                  const SizedBox(height: AppSpacing.md),

                  // RENDER SELECTED STATE PANEL
                  if (edgeState == 'in-flight' ||
                      (edgeState == 'ready' && state.creationStage > 0))
                    _buildInFlightStepper(context, role)
                  else if (edgeState == 'conflict')
                    _buildConflictBanner(context)
                  else if (edgeState == 'offline')
                    _buildOfflineBanner(context)
                  else if (edgeState == 'unresolved' || pendingList.isNotEmpty)
                    _buildUnresolvedBanner(context, pendingList.length),

                  if (edgeState != 'in-flight' && state.creationStage == 0) ...[
                    // Target Context Pill (Screen 56)
                    _buildTargetContextPill(
                      context,
                      role: role,
                      company: company,
                      sourceResume: sourceResumeName,
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // Readiness Card (Screen 56)
                    _buildReadinessCard(
                      context,
                      totalSuggestions: a.suggestions.length,
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // Review Breakdown Bento Grid (Screen 56)
                    _buildBentoGrid(
                      context,
                      total: a.suggestions.length,
                      accepted: acceptedList.length,
                      edited: editedList.length,
                      skipped: skippedList.length,
                      unresolved: pendingList.length,
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // Output Resume Configuration Card (Screen 56)
                    _buildOutputConfigCard(
                      context,
                      state: state,
                      sourceResume: sourceResumeName,
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // Factual Integrity Banner (Screen 56 & 62)
                    _buildFactualIntegrityCard(context, a.suggestions),
                    const SizedBox(height: AppSpacing.md),

                    // Accuracy Confirmation Checkbox (Screen 56 & 62)
                    AnimatedBuilder(
                      animation: _shakeAnimation,
                      builder: (context, child) {
                        final offset =
                            (_shakeAnimation.value > 0 &&
                                _shakeAnimation.value < 1)
                            ? (8.0 * (1 - _shakeAnimation.value))
                            : 0.0;
                        return Transform.translate(
                          offset: Offset(offset, 0),
                          child: child,
                        );
                      },
                      child: _buildAccuracyConfirmationCard(
                        context,
                        state,
                        a.suggestions
                            .where(
                              (s) =>
                                  s.requiresConfirmation &&
                                  (s.status == SuggestionStatus.accepted ||
                                      s.status == SuggestionStatus.edited),
                            )
                            .length,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // Changes by Section (Screen 56 & 62)
                    _buildSectionChangesHeader(context, groups.length),
                    const SizedBox(height: AppSpacing.sm),
                    ...groups.entries.map((entry) {
                      final isExpanded = _expandedSections.contains(entry.key);
                      return _buildSectionCard(
                        context,
                        sectionTitle: entry.key,
                        suggestions: entry.value,
                        isExpanded: isExpanded,
                        onToggle: () {
                          setState(() {
                            if (isExpanded) {
                              _expandedSections.remove(entry.key);
                            } else {
                              _expandedSections.add(entry.key);
                            }
                          });
                        },
                      );
                    }),

                    // Skipped Suggestions Collapsed Section (Screen 62)
                    if (skippedList.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.md),
                      _buildSkippedSection(context, skippedList),
                    ],

                    const SizedBox(height: AppSpacing.md),

                    // Credit Summary Notice (Screen 56)
                    _buildCreditSummaryNotice(context),
                  ],
                ],
              ),
            ),

            // Elevated Sticky Bottom Action Bar (Screen 56)
            _buildBottomActionBar(
              context,
              state: state,
              hasPending: pendingList.isNotEmpty,
              isOffline: edgeState == 'offline',
            ),
          ],
        ),
      ),
    );
  }

  // ─── Edge State Selector (Screen 60) ───────────────────────────────────────

  Widget _buildEdgeStateSelector(BuildContext context, String current) {
    const states = [
      {'key': 'ready', 'label': 'Ready'},
      {'key': 'in-flight', 'label': 'Creating'},
      {'key': 'unresolved', 'label': 'Unresolved'},
      {'key': 'conflict', 'label': 'Source Changed'},
      {'key': 'offline', 'label': 'Offline'},
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.of(context).cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.of(context).border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.tune, size: 16, color: AppColors.of(context).primary),
              const SizedBox(width: 6),
              Text(
                'LIFECYCLE & RECOVERY INSPECTOR',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  letterSpacing: 0.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.of(context).textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: states.map((s) {
                final isSelected = current == s['key'];
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ChoiceChip(
                    label: Text(s['label']!),
                    selected: isSelected,
                    onSelected: (_) {
                      ref
                          .read(optimizationProvider.notifier)
                          .setSummaryEdgeState(s['key']!);
                    },
                    selectedColor: AppColors.of(context).primary,
                    labelStyle: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? Colors.white
                          : AppColors.of(context).textPrimary,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Target Context Pill (Screen 56) ────────────────────────────────────────

  Widget _buildTargetContextPill(
    BuildContext context, {
    required String role,
    required String company,
    required String sourceResume,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.of(context).mutedBackground,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(
          color: AppColors.of(context).border.withOpacity(0.5),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.work_outline,
            size: 18,
            color: AppColors.of(context).primary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text.rich(
              TextSpan(
                style: Theme.of(context).textTheme.bodySmall,
                children: [
                  TextSpan(
                    text: '$role at $company',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const TextSpan(text: ' · '),
                  TextSpan(
                    text: sourceResume,
                    style: TextStyle(
                      color: AppColors.of(context).textSecondary,
                    ),
                  ),
                ],
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Readiness Card (Screen 56) ─────────────────────────────────────────────

  Widget _buildReadinessCard(
    BuildContext context, {
    required int totalSuggestions,
  }) {
    final colors = AppColors.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: const Color(0xFF93F0E8).withOpacity(0.18),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: const Color(0xFF006A65).withOpacity(0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: Color(0xFF93F0E8),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle,
              color: Color(0xFF006A65),
              size: 24,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ready to create your optimized resume',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'All $totalSuggestions suggestions have been reviewed. Your accepted changes will be added to a separate resume version.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colors.textSecondary,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x0A000000),
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.verified_user,
                        size: 14,
                        color: Color(0xFF006A65),
                      ),
                      SizedBox(width: 5),
                      Text(
                        'Original resume stays unchanged',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF006A65),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Bento Grid (Screen 56) ────────────────────────────────────────────────

  Widget _buildBentoGrid(
    BuildContext context, {
    required int total,
    required int accepted,
    required int edited,
    required int skipped,
    required int unresolved,
  }) {
    final colors = AppColors.of(context);
    return Container(
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
                'Review Breakdown',
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
              Text(
                '$total total items',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: colors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: _buildBentoTile(
                  context,
                  count: accepted,
                  label: 'Accepted',
                  sublabel: 'Direct inclusions',
                  icon: Icons.done_all,
                  bgColor: const Color(0xFF93F0E8).withOpacity(0.25),
                  fgColor: const Color(0xFF006A65),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _buildBentoTile(
                  context,
                  count: edited,
                  label: 'Edited',
                  sublabel: 'Customized tone',
                  icon: Icons.edit_note,
                  bgColor: colors.primarySoft,
                  fgColor: colors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: _buildBentoTile(
                  context,
                  count: skipped,
                  label: 'Skipped',
                  sublabel: 'Omitted points',
                  icon: Icons.close,
                  bgColor: colors.mutedBackground,
                  fgColor: colors.textSecondary,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _buildBentoTile(
                  context,
                  count: unresolved,
                  label: 'Unresolved',
                  sublabel: unresolved == 0 ? 'Clean slate' : 'Needs review',
                  icon: unresolved == 0
                      ? Icons.check
                      : Icons.warning_amber_rounded,
                  bgColor: colors.mutedBackground,
                  fgColor: unresolved == 0
                      ? colors.textSecondary
                      : colors.error,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(Icons.touch_app, size: 14, color: colors.textSecondary),
              const SizedBox(width: 4),
              Text(
                'Tap any metric to inspect specific decisions',
                style: TextStyle(fontSize: 11, color: colors.textSecondary),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBentoTile(
    BuildContext context, {
    required int count,
    required String label,
    required String sublabel,
    required IconData icon,
    required Color bgColor,
    required Color fgColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$count',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: fgColor,
                ),
              ),
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: fgColor.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 14, color: fgColor),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: fgColor,
            ),
          ),
          Text(
            sublabel,
            style: TextStyle(
              fontSize: 11,
              color: AppColors.of(context).textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Output Resume Configuration Card (Screen 56) ──────────────────────────

  Widget _buildOutputConfigCard(
    BuildContext context, {
    required OptimizationState state,
    required String sourceResume,
  }) {
    final colors = AppColors.of(context);
    return Container(
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
                'Optimized Resume Version',
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF93F0E8),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: const Text(
                  'New draft',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF006F69),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),

          // Title row with edit button
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.mutedBackground,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'VERSION NAME',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                          color: colors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        state.versionName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Rename version',
                  onPressed: () =>
                      _showRenameDialog(context, state.versionName),
                  icon: Icon(Icons.edit, size: 18, color: colors.primary),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Metadata row: Source resume
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.history, size: 18, color: colors.textSecondary),
                  const SizedBox(width: 6),
                  Text(
                    'Source resume',
                    style: TextStyle(fontSize: 13, color: colors.textSecondary),
                  ),
                ],
              ),
              Text(
                sourceResume,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Metadata row: Design Template
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.palette_outlined,
                    size: 18,
                    color: colors.textSecondary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Design Template',
                    style: TextStyle(fontSize: 13, color: colors.textSecondary),
                  ),
                ],
              ),
              Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: colors.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    state.selectedTemplate,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 6),
                  TextButton(
                    onPressed: () => _showTemplateSelectorSheet(context),
                    child: const Text('Change', style: TextStyle(fontSize: 12)),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Guarantee banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: colors.primarySoft,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.verified, size: 16, color: colors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Does not overwrite your base resume · 0 additional AI credits',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: colors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Factual Integrity Banner (Screen 56 & 62) ─────────────────────────────

  Widget _buildFactualIntegrityCard(
    BuildContext context, [
    List<OptimizationSuggestion>? suggestions,
  ]) {
    final confirmed = suggestions
        ?.where(
          (s) =>
              s.requiresConfirmation &&
              (s.status == SuggestionStatus.accepted ||
                  s.status == SuggestionStatus.edited),
        )
        .toList();

    final List<String> claims;
    if (confirmed != null && confirmed.isNotEmpty) {
      claims = confirmed
          .map(
            (s) =>
                '${s.section}: ${s.proposed} (${s.evidence.isNotEmpty ? s.evidence : s.reason})',
          )
          .toList();
    } else {
      claims = const [
        '4+ Years experience claim: Matches validated timeline (2019–present).',
        'Flutter production lead: Documented role delivery in architecture track.',
        'Riverpod state management: Evaluated in technical skills survey.',
        '35% API latency benchmark: Sourced from sprint retrospective logs.',
        'Cross-team collaboration: Confirmed product & QA co-ownership.',
      ];
    }

    final totalCount = confirmed != null ? confirmed.length : 5;

    return Container(
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
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: const Color(0xFF96F3EB),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.verified_user,
                  size: 18,
                  color: Color(0xFF00201E),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Factual Claims Verified',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      totalCount == 0
                          ? 'No new factual claims required confirmation'
                          : '$totalCount statement${totalCount == 1 ? '' : 's'} verified against your profile',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.of(context).textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF96F3EB).withOpacity(0.5),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Text(
                  totalCount == 0 ? 'Verified' : '100% Validated',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF006A65),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...claims.map(
            (c) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.check_circle,
                    size: 16,
                    color: Color(0xFF006A65),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      c,
                      style: const TextStyle(fontSize: 12, height: 1.3),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Accuracy Confirmation Card (Screen 56 & 62) ───────────────────────────

  Widget _buildAccuracyConfirmationCard(
    BuildContext context,
    OptimizationState state, [
    int? confirmedClaimsCount,
  ]) {
    final colors = AppColors.of(context);
    final count = confirmedClaimsCount ?? 5;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.cardBackground,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: state.isAccuracyConfirmed ? colors.primary : colors.border,
          width: state.isAccuracyConfirmed ? 1.5 : 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.fact_check, size: 18, color: colors.primary),
              const SizedBox(width: 6),
              Text(
                count > 0
                    ? 'You confirmed $count factual claim${count == 1 ? '' : 's'}'
                    : 'Accuracy review confirmation',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: colors.primary,
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),
          InkWell(
            onTap: () {
              ref
                  .read(optimizationProvider.notifier)
                  .toggleAccuracyConfirmation(!state.isAccuracyConfirmed);
            },
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Checkbox(
                    value: state.isAccuracyConfirmed,
                    activeColor: colors.primary,
                    onChanged: (val) {
                      ref
                          .read(optimizationProvider.notifier)
                          .toggleAccuracyConfirmation(val ?? false);
                    },
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        'I have reviewed the accepted changes and confirm that they accurately reflect my genuine skills and experience.',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: colors.textPrimary,
                          height: 1.3,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(left: 48),
            child: Text(
              '“PrepMate coaches and formats; you remain the author of your truth.”',
              style: TextStyle(
                fontSize: 11,
                fontStyle: FontStyle.italic,
                color: colors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Changes by Section (Screen 56 & 62) ────────────────────────────────────

  Widget _buildSectionChangesHeader(BuildContext context, int sectionCount) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Text(
              'Changes by Section',
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(width: 6),
            Text(
              '($sectionCount Active Sections)',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.of(context).textSecondary,
              ),
            ),
          ],
        ),
        TextButton(
          onPressed: () {
            setState(() {
              if (_expandedSections.isNotEmpty) {
                _expandedSections.clear();
              } else {
                _expandedSections.addAll([
                  'Professional Summary',
                  'Work Experience',
                  'Core Skills',
                  'Projects',
                ]);
              }
            });
          },
          child: Text(
            _expandedSections.isNotEmpty ? 'Collapse All' : 'Expand All',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionCard(
    BuildContext context, {
    required String sectionTitle,
    required List<OptimizationSuggestion> suggestions,
    required bool isExpanded,
    required VoidCallback onToggle,
  }) {
    final colors = AppColors.of(context);
    final accepted = suggestions
        .where((s) => s.status == SuggestionStatus.accepted)
        .length;
    final edited = suggestions
        .where((s) => s.status == SuggestionStatus.edited)
        .length;

    IconData icon;
    switch (sectionTitle.toLowerCase()) {
      case 'summary':
      case 'professional summary':
        icon = Icons.badge;
        break;
      case 'experience':
      case 'work experience':
        icon = Icons.domain;
        break;
      case 'skills':
      case 'core skills':
        icon = Icons.terminal;
        break;
      case 'projects':
        icon = Icons.rocket_launch;
        break;
      default:
        icon = Icons.article_outlined;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      decoration: BoxDecoration(
        color: colors.cardBackground,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: onToggle,
            borderRadius: BorderRadius.circular(AppRadius.md),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: colors.mutedBackground,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, size: 18, color: colors.primary),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          sectionTitle,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            if (accepted > 0)
                              Container(
                                margin: const EdgeInsets.only(right: 6),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFF93F0E8,
                                  ).withOpacity(0.4),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  '$accepted accepted',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF006A65),
                                  ),
                                ),
                              ),
                            if (edited > 0)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: colors.primarySoft,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  '$edited edited',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: colors.primary,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: colors.textSecondary,
                  ),
                ],
              ),
            ),
          ),
          if (isExpanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: suggestions.map((s) {
                  return Container(
                    margin: const EdgeInsets.only(top: 8),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: colors.mutedBackground,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'PROPOSED DIFF',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: colors.primary,
                              ),
                            ),
                            TextButton.icon(
                              onPressed: () {
                                context.push(
                                  '/resume/optimize/suggestions/${s.id}/edit',
                                );
                              },
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              icon: const Text(
                                'Open suggestion',
                                style: TextStyle(fontSize: 11),
                              ),
                              label: const Icon(Icons.arrow_forward, size: 12),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          s.proposed,
                          style: const TextStyle(fontSize: 12, height: 1.3),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }

  // ─── Skipped Suggestions Section (Screen 62) ───────────────────────────────

  Widget _buildSkippedSection(
    BuildContext context,
    List<OptimizationSuggestion> skipped,
  ) {
    final colors = AppColors.of(context);
    return Container(
      decoration: BoxDecoration(
        color: colors.cardBackground,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        children: [
          Material(
            color: Colors.transparent,
            child: ListTile(
              onTap: () {
                setState(() {
                  _skippedExpanded = !_skippedExpanded;
                });
              },
              title: Text(
                '${skipped.length} Skipped suggestions',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: Text(
                'Skipped content will not appear in the optimized resume.',
                style: TextStyle(fontSize: 11, color: colors.textSecondary),
              ),
              trailing: IconButton(
                icon: Icon(
                  _skippedExpanded ? Icons.expand_less : Icons.expand_more,
                ),
                onPressed: () {
                  setState(() {
                    _skippedExpanded = !_skippedExpanded;
                  });
                },
              ),
            ),
          ),
          if (_skippedExpanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                children: skipped.map((s) {
                  return Container(
                    margin: const EdgeInsets.only(top: 8),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: colors.mutedBackground,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            s.proposed,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            context.push(
                              '/resume/optimize/suggestions/${s.id}/edit',
                            );
                          },
                          child: const Text(
                            'Review Again',
                            style: TextStyle(fontSize: 11),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }

  // ─── Credit Summary Notice (Screen 56) ─────────────────────────────────────

  Widget _buildCreditSummaryNotice(BuildContext context) {
    final colors = AppColors.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.mutedBackground,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(Icons.toll, size: 20, color: colors.primary),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Analysis: 3 credits used',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                  ),
                  Text(
                    'New version creation: Free',
                    style: TextStyle(fontSize: 11, color: colors.textSecondary),
                  ),
                ],
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF93F0E8),
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
            child: const Text(
              '0 Additional',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: Color(0xFF006F69),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Screen 60 Edge State Banners & Steppers ────────────────────────────────

  Widget _buildInFlightStepper(BuildContext context, String role) {
    final colors = AppColors.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.cardBackground,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: colors.primary.withOpacity(0.3)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0C000000),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: colors.primarySoft,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Center(
                  child: SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Creating Optimized Resume',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'Target: $role',
                      style: TextStyle(
                        fontSize: 12,
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: colors.primarySoft,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Text(
                  'In Progress',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: colors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildStepItem(
            context,
            stepNumber: 1,
            title: '1. Validating decisions',
            subtitle: 'Checking confirmed suggestions against active session.',
            status: 'Done',
            isDone: true,
          ),
          const SizedBox(height: 10),
          _buildStepItem(
            context,
            stepNumber: 2,
            title: '2. Creating résumé version',
            subtitle: 'Registering isolated derived version in database.',
            status: 'Done',
            isDone: true,
          ),
          const SizedBox(height: 10),
          _buildStepItem(
            context,
            stepNumber: 3,
            title: '3. Applying confirmed changes',
            subtitle:
                'Synthesizing accepted and user-edited content into target sections.',
            status: 'In Progress',
            isInProgress: true,
          ),
          const SizedBox(height: 10),
          _buildStepItem(
            context,
            stepNumber: 4,
            title: '4. Preparing document preview',
            subtitle:
                'Formatting structured draft layout for high-fidelity canvas preview.',
            status: 'Queued',
            isQueued: true,
          ),
        ],
      ),
    );
  }

  Widget _buildStepItem(
    BuildContext context, {
    required int stepNumber,
    required String title,
    required String subtitle,
    required String status,
    bool isDone = false,
    bool isInProgress = false,
    bool isQueued = false,
    String? extraSnippet,
  }) {
    final colors = AppColors.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            color: isDone
                ? const Color(0xFF006A65)
                : (isInProgress ? colors.primary : colors.mutedBackground),
            shape: BoxShape.circle,
          ),
          child: Icon(
            isDone
                ? Icons.check
                : (isInProgress ? Icons.sync : Icons.circle_outlined),
            size: 14,
            color: (isDone || isInProgress)
                ? Colors.white
                : colors.textSecondary,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isInProgress
                          ? FontWeight.w700
                          : FontWeight.w600,
                      color: isInProgress ? colors.primary : colors.textPrimary,
                    ),
                  ),
                  Text(
                    status,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: isDone
                          ? const Color(0xFF006A65)
                          : (isInProgress
                                ? colors.primary
                                : colors.textSecondary),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(fontSize: 11, color: colors.textSecondary),
              ),
              if (extraSnippet != null) ...[
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colors.mutedBackground,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.auto_awesome, size: 14, color: colors.primary),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          extraSnippet,
                          style: TextStyle(
                            fontSize: 11,
                            fontStyle: FontStyle.italic,
                            color: colors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildUnresolvedBanner(BuildContext context, int count) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: const Color(0xFFFFDAD6).withOpacity(0.5),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: const Color(0xFFBA1A1A).withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.warning_amber_rounded, color: Color(0xFFBA1A1A)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Suggestions Still Require Review',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFBA1A1A),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$count suggestion${count == 1 ? '' : 's'} remain pending. Review them to include or skip them before creating your final version.',
                  style: const TextStyle(fontSize: 12, height: 1.3),
                ),
                const SizedBox(height: 8),
                FilledButton.tonal(
                  onPressed: () => context.push('/resume/optimize/suggestions'),
                  style: FilledButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                  ),
                  child: const Text('Review Remaining Items'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConflictBanner(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: const Color(0xFFFFE0B2).withOpacity(0.6),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: Colors.orange.withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.fork_right, color: Colors.deepOrange),
              SizedBox(width: 8),
              Text(
                'Source Resume Modified in Parallel',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.deepOrange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Your original resume was edited since this analysis began. Your master resume will never be overwritten.',
            style: TextStyle(fontSize: 12, height: 1.3),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              OutlinedButton(
                onPressed: () {},
                child: const Text('Review conflicts'),
              ),
              FilledButton(
                onPressed: () {},
                child: const Text('Create copy from snapshot'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOfflineBanner(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.of(context).mutedBackground,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.of(context).border),
      ),
      child: const Row(
        children: [
          Icon(Icons.wifi_off, color: Colors.grey),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Offline mode · Viewing cached summary. Final resume generation requires an internet connection.',
              style: TextStyle(fontSize: 12, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Sticky Bottom Action Bar (Screen 56) ──────────────────────────────────

  Widget _buildBottomActionBar(
    BuildContext context, {
    required OptimizationState state,
    required bool hasPending,
    required bool isOffline,
  }) {
    final colors = AppColors.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.cardBackground.withOpacity(0.95),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 12,
            offset: Offset(0, -3),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            flex: 1,
            child: AppSecondaryButton(
              label: 'Preview',
              icon: Icons.visibility_outlined,
              onPressed: () => context.push('/resume/optimize/preview'),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            flex: 2,
            child: AppPrimaryButton(
              label: 'Create resume',
              icon: Icons.arrow_forward,
              loading: state.busy,
              onPressed: isOffline
                  ? null
                  : () async {
                      if (!state.isAccuracyConfirmed) {
                        _triggerShake();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Please check the accuracy confirmation to proceed.',
                            ),
                          ),
                        );
                        return;
                      }

                      if (hasPending) {
                        final proceed = await showDialog<bool>(
                          context: context,
                          builder: (dContext) => AlertDialog(
                            title: const Text('Suggestions still need review'),
                            content: const Text(
                              'Unreviewed suggestions will not be applied to the new resume. Would you like to review them now or continue?',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(dContext, false),
                                child: const Text('Review'),
                              ),
                              FilledButton(
                                onPressed: () => Navigator.pop(dContext, true),
                                child: const Text('Continue'),
                              ),
                            ],
                          ),
                        );
                        if (proceed != true) return;
                      }

                      final ok = await ref
                          .read(optimizationProvider.notifier)
                          .createVersion();
                      if (ok && context.mounted) {
                        context.push('/resume/optimize/preview');
                      }
                    },
            ),
          ),
        ],
      ),
    );
  }

  // ─── Modal Dialogs & Sheets ────────────────────────────────────────────────

  void _showRenameDialog(BuildContext context, String currentTitle) {
    final controller = TextEditingController(text: currentTitle);
    showDialog<void>(
      context: context,
      builder: (dContext) => AlertDialog(
        title: const Text('Rename Resume Version'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Version Name',
            hintText: 'e.g. Software Engineer — Acme',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final val = controller.text.trim();
              if (val.isNotEmpty) {
                ref.read(optimizationProvider.notifier).setVersionName(val);
              }
              Navigator.pop(dContext);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showTemplateSelectorSheet(BuildContext context) {
    const templates = ['Modern Blue', 'Executive Slate', 'Minimal Clean'];
    final current = ref.read(optimizationProvider).selectedTemplate;

    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (bContext) => Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select Resume Design Template',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: AppSpacing.sm),
            ...templates.map((t) {
              final isSel = t == current;
              return ListTile(
                title: Text(
                  t,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                trailing: isSel
                    ? const Icon(Icons.check_circle, color: Color(0xFF2457D6))
                    : null,
                onTap: () {
                  ref.read(optimizationProvider.notifier).setTemplate(t);
                  Navigator.pop(bContext);
                },
              );
            }),
          ],
        ),
      ),
    );
  }
}
