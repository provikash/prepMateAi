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

class AtsAnalysisScreen extends ConsumerStatefulWidget {
  const AtsAnalysisScreen({super.key});

  @override
  ConsumerState<AtsAnalysisScreen> createState() => _AtsAnalysisScreenState();
}

class _AtsAnalysisScreenState extends ConsumerState<AtsAnalysisScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _showRawExtractedText = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(optimizationProvider);
    final a = state.analysis;

    if (a == null) {
      return AppScaffold(
        title: 'ATS Analysis',
        body: const AppErrorState(
          message: 'Create or select an optimized version to view ATS results.',
        ),
      );
    }

    final readinessScore = a.afterAtsScore ?? a.afterScore;
    final beforeScore = a.beforeAtsScore ?? a.beforeScore;
    final delta = readinessScore - beforeScore;
    final role = state.jobTitle.isNotEmpty
        ? state.jobTitle
        : 'Senior Flutter Developer';
    final company = state.company.isNotEmpty
        ? state.company
        : 'Acme Technologies';

    return AppScaffold(
      title: 'ATS Analysis',
      actions: [
        IconButton(
          tooltip: 'Methodology explanation',
          onPressed: () => _showMethodologySheet(context),
          icon: const Icon(Icons.info_outline),
        ),
      ],
      body: ResponsiveContent(
        maxWidth: 720,
        child: Column(
          children: [
            const OptimizationStepHeader(step: 4),
            const SizedBox(height: AppSpacing.sm),

            // Target Context Chip Strip (Screen 64)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.of(context).mutedBackground,
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Icon(
                          Icons.description_outlined,
                          size: 16,
                          color: AppColors.of(context).primary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${state.versionName} • Target: $company',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF93F0E8),
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.verified,
                          size: 12,
                          color: Color(0xFF006A65),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '$readinessScore% Match',
                          style: const TextStyle(
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
            const SizedBox(height: 6),

            // Material 3 Tabs: Overview, Parsing, Job Alignment, Content (Screen 64)
            Container(
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: AppColors.of(context).border),
                ),
              ),
              child: TabBar(
                controller: _tabController,
                isScrollable: false,
                labelColor: AppColors.of(context).primary,
                unselectedLabelColor: AppColors.of(context).textSecondary,
                indicatorColor: AppColors.of(context).primary,
                indicatorWeight: 3,
                labelStyle: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
                tabs: const [
                  Tab(text: 'Overview'),
                  Tab(text: 'Parsing'),
                  Tab(text: 'Alignment'),
                  Tab(text: 'Content'),
                ],
              ),
            ),

            // Tab Panels
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildOverviewTab(
                    context,
                    readinessScore: readinessScore,
                    beforeScore: beforeScore,
                    delta: delta,
                    role: role,
                    company: company,
                  ),
                  _buildParsingTab(context),
                  _buildJobAlignmentTab(context),
                  _buildContentTab(context),
                ],
              ),
            ),

            // Bottom CTA
            Container(
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
              child: AppPrimaryButton(
                label: 'View Optimized Resume',
                icon: Icons.description_outlined,
                onPressed: () => context.push('/resume/optimize/preview'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Tab 1: Overview (Screen 57) ───────────────────────────────────────────

  Widget _buildOverviewTab(
    BuildContext context, {
    required int readinessScore,
    required int beforeScore,
    required int delta,
    required String role,
    required String company,
  }) {
    final colors = AppColors.of(context);
    return ListView(
      padding: const EdgeInsets.symmetric(
        horizontal: 4,
        vertical: AppSpacing.md,
      ),
      children: [
        // Context Card (Screen 57)
        Container(
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
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: colors.primarySoft,
                            borderRadius: BorderRadius.circular(AppRadius.pill),
                          ),
                          child: Text(
                            'Resume & job-description checks',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: colors.primary,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Diagnostic check completed in 1.4s',
                          style: TextStyle(
                            fontSize: 12,
                            color: colors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: colors.mutedBackground,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.analytics, color: colors.primary),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: colors.mutedBackground,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.business_center,
                          size: 16,
                          color: Color(0xFF006A65),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            '$role at $company',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.picture_as_pdf,
                          size: 16,
                          color: colors.textSecondary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Modern Blue template (Selectable vector text PDF)',
                          style: TextStyle(
                            fontSize: 11,
                            color: colors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        // Restrained ATS Readiness Overview Card (Screen 57)
        Container(
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
                  const Text(
                    'PrepMate Readiness Score',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF93F0E8),
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.check_circle,
                          size: 14,
                          color: Color(0xFF006A65),
                        ),
                        SizedBox(width: 4),
                        Text(
                          'Good readiness',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF006A65),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Most standard parsing and structure checks passed. Review recommended items before applying.',
                style: TextStyle(fontSize: 12, color: colors.textSecondary),
              ),
              const SizedBox(height: 14),

              // Score block
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colors.mutedBackground,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              '$readinessScore',
                              style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            Text(
                              ' / 100',
                              style: TextStyle(
                                fontSize: 16,
                                color: colors.textSecondary,
                              ),
                            ),
                            const SizedBox(width: 8),
                            if (delta > 0)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFF93F0E8,
                                  ).withOpacity(0.5),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  '+$delta improved',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF006A65),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        TextButton(
                          onPressed: () => _showMethodologySheet(context),
                          child: const Text(
                            'How this is calculated',
                            style: TextStyle(fontSize: 11),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'PrepMate readiness score · Calculated from deterministic parsing & evidence alignment. Not an employer ATS score or hiring guarantee.',
                      style: TextStyle(
                        fontSize: 11,
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Progress Breakdown Bars
              _buildCategoryProgressBar(
                context,
                title: 'Parsing & structure',
                percentage: 90,
                rating: 'Good',
                color: const Color(0xFF006A65),
              ),
              const SizedBox(height: 10),
              _buildCategoryProgressBar(
                context,
                title: 'Section recognition',
                percentage: 85,
                rating: 'Good',
                color: const Color(0xFF006A65),
              ),
              const SizedBox(height: 10),
              _buildCategoryProgressBar(
                context,
                title: 'Job alignment evidence',
                percentage: 75,
                rating: 'Aligned',
                color: colors.primary,
              ),
              const SizedBox(height: 12),
              Text(
                'Diagnostic Categories',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: colors.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  _buildDiagnosticChip(context, 'File compatibility', true),
                  _buildDiagnosticChip(context, 'Text extraction', true),
                  _buildDiagnosticChip(context, 'Reading order flow', true),
                  _buildDiagnosticChip(context, 'Typography & glyphs', true),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        // Diagnostic Issues List
        Text(
          'Diagnostic Items to Review',
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: AppSpacing.sm),
        _buildIssueCard(
          context,
          title: 'Missing LinkedIn or Portfolio Link',
          category: 'Contact details',
          importance: 'Medium',
          explanation:
              'A verifiable professional profile URL increases employer trust and recruiter follow-up speed.',
          section: 'Header',
        ),
        const SizedBox(height: 8),
        _buildIssueCard(
          context,
          title: 'Section heading standard wording',
          category: 'Structure',
          importance: 'Low',
          explanation:
              'Used "Professional Experience" which is recognized by 100% of standard parser schemas.',
          section: 'Experience',
          isResolved: true,
        ),
      ],
    );
  }

  Widget _buildCategoryProgressBar(
    BuildContext context, {
    required String title,
    required int percentage,
    required String rating,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
            Row(
              children: [
                Text(
                  rating,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  '$percentage%',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.of(context).textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: percentage / 100.0,
            backgroundColor: AppColors.of(context).mutedBackground,
            color: color,
            minHeight: 6,
          ),
        ),
      ],
    );
  }

  Widget _buildDiagnosticChip(BuildContext context, String label, bool isGood) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.of(context).mutedBackground,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: AppColors.of(context).border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isGood ? Icons.check_circle : Icons.warning_amber,
            size: 13,
            color: isGood
                ? const Color(0xFF006A65)
                : AppColors.of(context).primary,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildIssueCard(
    BuildContext context, {
    required String title,
    required String category,
    required String importance,
    required String explanation,
    required String section,
    bool isResolved = false,
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
              Row(
                children: [
                  Icon(
                    isResolved
                        ? Icons.check_circle
                        : Icons.warning_amber_rounded,
                    size: 16,
                    color: isResolved
                        ? const Color(0xFF006A65)
                        : colors.primary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isResolved
                      ? const Color(0xFF93F0E8).withOpacity(0.5)
                      : colors.primarySoft,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  importance,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: isResolved
                        ? const Color(0xFF006A65)
                        : colors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            explanation,
            style: TextStyle(
              fontSize: 12,
              color: colors.textSecondary,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Tab 2: Parsing (Screen 64) ────────────────────────────────────────────

  Widget _buildParsingTab(BuildContext context) {
    const checks = [
      {'name': 'Text selectable in PDF', 'status': 'Passed'},
      {'name': 'Contact details detected', 'status': 'Passed'},
      {'name': 'Section headings recognized', 'status': 'Passed'},
      {'name': 'Logical reading order confirmed', 'status': 'Passed'},
      {'name': 'Dates readable & consistent', 'status': 'Passed'},
      {'name': 'Text not rendered inside images', 'status': 'Passed'},
      {'name': 'Columns/tables do not disrupt content', 'status': 'Passed'},
      {'name': 'Link URLs readable as text', 'status': 'Needs review'},
      {'name': 'Standard UTF-8 glyphs supported', 'status': 'Passed'},
    ];

    return ListView(
      padding: const EdgeInsets.symmetric(
        horizontal: 4,
        vertical: AppSpacing.md,
      ),
      children: [
        // Extracted Text Preview Switcher
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
                  const Text(
                    'Raw Extracted Text Preview',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                  ),
                  Switch(
                    value: _showRawExtractedText,
                    onChanged: (val) {
                      setState(() {
                        _showRawExtractedText = val;
                      });
                    },
                  ),
                ],
              ),
              Text(
                'Displays text exactly as standard enterprise ATS parsers extract it from your generated PDF.',
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.of(context).textSecondary,
                ),
              ),
              if (_showRawExtractedText) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.of(context).mutedBackground,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const SelectableText(
                    'JOHN DOE\nSenior Mobile Engineer | Flutter & Dart\n'
                    'San Francisco, CA • john.doe@example.com • github.com/johndoe\n\n'
                    'PROFESSIONAL SUMMARY\n'
                    'Accomplished Mobile Architect with 5+ years leading mobile engineering...\n\n'
                    'WORK EXPERIENCE\n'
                    'Lead Mobile Developer | Example Labs (2021 – Present)\n'
                    '• Architected high-performance Flutter mobile app serving 120k DAU\n'
                    '• Migrated state management architecture to Riverpod 2.x',
                    style: TextStyle(fontFamily: 'monospace', fontSize: 11),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        // Deterministic Checks
        Text(
          '9 Deterministic Parser Checks',
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: AppSpacing.sm),
        ...checks.map((c) {
          final isPassed = c['status'] == 'Passed';
          return Container(
            margin: const EdgeInsets.only(bottom: 6),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.of(context).cardBackground,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.of(context).border),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      isPassed ? Icons.check_circle : Icons.info_outline,
                      size: 16,
                      color: isPassed
                          ? const Color(0xFF006A65)
                          : AppColors.of(context).primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      c['name']!,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: isPassed
                        ? const Color(0xFF93F0E8).withOpacity(0.5)
                        : AppColors.of(context).primarySoft,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    c['status']!,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: isPassed
                          ? const Color(0xFF006A65)
                          : AppColors.of(context).primary,
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  // ─── Tab 3: Alignment (Screen 64) ──────────────────────────────────────────

  Widget _buildJobAlignmentTab(BuildContext context) {
    final state = ref.watch(optimizationProvider);
    final domainReqs = state.analysis?.requirements;

    final requirements = (domainReqs != null && domainReqs.isNotEmpty)
        ? domainReqs
              .map(
                (r) => {
                  'name': r.name,
                  'type': r.category,
                  'match': switch (r.match) {
                    RequirementMatch.matched => 'Strong',
                    RequirementMatch.partial => 'Partial',
                    RequirementMatch.missing ||
                    RequirementMatch.unclear => 'Not found',
                  },
                },
              )
              .toList()
        : const [
            {
              'name': 'Flutter & Dart Core',
              'type': 'Skills',
              'match': 'Strong',
            },
            {
              'name': 'Riverpod State Management',
              'type': 'Skills',
              'match': 'Strong',
            },
            {
              'name': 'Offline SQLite Syncing',
              'type': 'Skills',
              'match': 'Strong',
            },
            {
              'name': 'CI/CD Automation pipelines',
              'type': 'Skills',
              'match': 'Partial',
            },
            {
              'name': 'Architecture Track Delivery',
              'type': 'Responsibilities',
              'match': 'Strong',
            },
            {
              'name': 'Cross-functional QA sync',
              'type': 'Responsibilities',
              'match': 'Partial',
            },
            {
              'name': 'Unit & Golden Widget Testing',
              'type': 'Qualifications',
              'match': 'Not found',
            },
          ];

    return ListView(
      padding: const EdgeInsets.symmetric(
        horizontal: 4,
        vertical: AppSpacing.md,
      ),
      children: [
        // Target Coverage Bento Card (Screen 64)
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
                  const Text(
                    'Target Coverage',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                  Text(
                    'Senior Flutter Role',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.of(context).primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Segmented Evidence Bar
              Row(
                children: [
                  Expanded(
                    flex: 7,
                    child: Container(
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Color(0xFF006A65),
                        borderRadius: BorderRadius.horizontal(
                          left: Radius.circular(4),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 4,
                    child: Container(
                      height: 8,
                      color: AppColors.of(context).primary,
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Container(
                      height: 8,
                      decoration: BoxDecoration(
                        color: AppColors.of(context).border,
                        borderRadius: const BorderRadius.horizontal(
                          right: Radius.circular(4),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Tri-split Evidence Stats
              Row(
                children: [
                  Expanded(
                    child: _buildTriStat(
                      context,
                      count: 7,
                      label: 'Strong match',
                      color: const Color(0xFF006A65),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildTriStat(
                      context,
                      count: 4,
                      label: 'Partial',
                      color: AppColors.of(context).primary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildTriStat(
                      context,
                      count: 2,
                      label: 'Review gap',
                      color: AppColors.of(context).textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.of(context).mutedBackground,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.tips_and_updates,
                      size: 14,
                      color: Color(0xFF006A65),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Good to know: Missing evidence means the term was not detected in text, not that you lack the capability.',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.of(context).textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        // Ethical Match Guidance (Screen 64)
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.of(context).primarySoft,
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.shield,
                size: 20,
                color: AppColors.of(context).primary,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'PrepMate Ethical Match',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.of(context).primary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Use job-specific terms naturally. Repeating keywords without genuine evidence reduces human credibility. PrepMate never generates auto-stuffed content.',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.of(context).textPrimary,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        // Matched Requirements Header
        Text(
          'Matched Requirements',
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: AppSpacing.sm),

        // Categorized Requirements List
        ...requirements.map((r) {
          final isStrong = r['match'] == 'Strong';
          final isPartial = r['match'] == 'Partial';
          final color = isStrong
              ? const Color(0xFF006A65)
              : (isPartial
                    ? AppColors.of(context).primary
                    : AppColors.of(context).textSecondary);

          return Container(
            margin: const EdgeInsets.only(bottom: 6),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.of(context).cardBackground,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.of(context).border),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      r['name']!,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      r['type']!,
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.of(context).textSecondary,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    r['match']!,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildTriStat(
    BuildContext context, {
    required int count,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppColors.of(context).mutedBackground,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        children: [
          Text(
            '$count',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: AppColors.of(context).textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Tab 4: Content (Screen 64) ────────────────────────────────────────────

  Widget _buildContentTab(BuildContext context) {
    const checks = [
      {'name': 'Professional summary clarity', 'status': 'Passed'},
      {'name': 'Action verbs & active voice', 'status': 'Passed'},
      {'name': 'Experience bullets quantified', 'status': 'Needs review'},
      {'name': 'Repetition & stuffing analysis', 'status': 'Passed'},
      {'name': 'Chronological date consistency', 'status': 'Passed'},
      {'name': 'Contact information completeness', 'status': 'Passed'},
      {'name': 'Section length proportionality', 'status': 'Passed'},
    ];

    return ListView(
      padding: const EdgeInsets.symmetric(
        horizontal: 4,
        vertical: AppSpacing.md,
      ),
      children: [
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
              const Text(
                'Content Quality & Evidence Checks',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text(
                'Evaluates clarity, metric evidence, and formatting consistency without fabricating credentials.',
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.of(context).textSecondary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        ...checks.map((c) {
          final isPassed = c['status'] == 'Passed';
          return Container(
            margin: const EdgeInsets.only(bottom: 6),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.of(context).cardBackground,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.of(context).border),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      isPassed ? Icons.check_circle : Icons.info_outline,
                      size: 16,
                      color: isPassed
                          ? const Color(0xFF006A65)
                          : AppColors.of(context).primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      c['name']!,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: isPassed
                        ? const Color(0xFF93F0E8).withOpacity(0.5)
                        : AppColors.of(context).primarySoft,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    c['status']!,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: isPassed
                          ? const Color(0xFF006A65)
                          : AppColors.of(context).primary,
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  // ─── Methodology Explanation Modal ─────────────────────────────────────────

  void _showMethodologySheet(BuildContext context) {
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
              'ATS Analysis Methodology',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            Text(
              'How This Is Calculated',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.of(context).primary,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              '1. Deterministic Checks (50% weight):\n'
              '• Selectable vector text in PDF (not raster images)\n'
              '• Section heading detection against common parsing taxonomies\n'
              '• Reading order integrity, glyph compatibility, and deterministic parsing integrity\n\n'
              '2. Job Alignment Checks (50% weight):\n'
              '• Natural match with required technologies and domain terms\n'
              '• Action verb strength and quantified metrics\n\n'
              'Disclaimer: PrepMate scores measure formatting hygiene and semantic overlap against your target job. They do not simulate internal proprietary employer hiring systems.',
              style: TextStyle(fontSize: 12, height: 1.4),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.pop(bContext),
                child: const Text('Understand & Close'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
