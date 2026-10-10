import 'package:flutter/material.dart';
import '../../../../config/theme.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../domain/optimization_models.dart';

/// Screen 45: Job Analysis Lifecycle & Edge States
/// Screen 44: Job Analysis Overview
/// Screen 46: Job Analysis Requirements & Keywords
/// Screen 49: Job Analysis Source Evidence Inspection Sheets

/// Screen 45: Job Analysis Lifecycle & Edge States View
class JobAnalysisLifecycleView extends StatelessWidget {
  const JobAnalysisLifecycleView({
    super.key,
    required this.jobTitle,
    required this.company,
    required this.stage,
    this.progressPercent = 65,
    this.isDelayed = false,
    this.isLowConfidence = false,
    this.isResumeEdited = false,
    this.isOffline = false,
    this.onRefresh,
    this.onContinueInBackground,
  });

  final String jobTitle;
  final String company;
  final int stage; // 1 to 5
  final int progressPercent;
  final bool isDelayed;
  final bool isLowConfidence;
  final bool isResumeEdited;
  final bool isOffline;
  final VoidCallback? onRefresh;
  final VoidCallback? onContinueInBackground;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        // Escrow Security Banner
        Container(
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: const Color(0xFFE1F4F1),
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(
                  color: Color(0xFF087E78),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.verified_user,
                  color: Colors.white,
                  size: 18,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: const [
                        Text(
                          'Active Background Worker',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF087E78),
                          ),
                        ),
                        SizedBox(width: 6),
                        Icon(Icons.circle, size: 6, color: Color(0xFF087E78)),
                      ],
                    ),
                    const Text(
                      '3 credits securely held in escrow until generation completes',
                      style: TextStyle(fontSize: 11, color: Color(0xFF172033)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        // Delayed State Notice
        if (isDelayed)
          Container(
            margin: const EdgeInsets.only(bottom: AppSpacing.md),
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF4E5),
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(
                color: const Color(0xFFA15C00).withOpacity(0.4),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.timer_outlined,
                  color: Color(0xFFA15C00),
                  size: 20,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'Taking longer than expected... Server load is high. You can continue in the background.',
                    style: TextStyle(fontSize: 12, color: colors.textPrimary),
                  ),
                ),
                if (onRefresh != null)
                  TextButton(
                    onPressed: onRefresh,
                    child: const Text('Check Status'),
                  ),
              ],
            ),
          ),

        // Low Confidence JD Warning
        if (isLowConfidence)
          Container(
            margin: const EdgeInsets.only(bottom: AppSpacing.md),
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF4E5),
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(
                color: const Color(0xFFA15C00).withOpacity(0.4),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.warning_amber_rounded,
                  color: Color(0xFFA15C00),
                  size: 20,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'Limited Job Description: Fewer than 150 words provided. Semantic matching confidence may be reduced.',
                    style: TextStyle(fontSize: 12, color: colors.textPrimary),
                  ),
                ),
              ],
            ),
          ),

        // Resume Edited Warning
        if (isResumeEdited)
          Container(
            margin: const EdgeInsets.only(bottom: AppSpacing.md),
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: colors.primarySoft,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: colors.primary.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.history, color: colors.primary, size: 20),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'Analysis is based on saved snapshot v2.4. Your master resume has recent unsaved edits.',
                    style: TextStyle(fontSize: 12, color: colors.textPrimary),
                  ),
                ),
              ],
            ),
          ),

        // Offline Cached State
        if (isOffline)
          Container(
            margin: const EdgeInsets.only(bottom: AppSpacing.md),
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: colors.screenBackground,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: colors.border),
            ),
            child: Row(
              children: [
                Icon(Icons.cloud_off, color: colors.textSecondary, size: 20),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'Offline mode active · Viewing cached analysis result.',
                    style: TextStyle(fontSize: 12, color: colors.textSecondary),
                  ),
                ),
              ],
            ),
          ),

        // Main In-Flight Progress Card
        AppCard(
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
                        Text(
                          'SEMANTIC PIPELINE V3.2',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: colors.primary,
                            letterSpacing: 0.8,
                          ),
                        ),
                        Text(
                          jobTitle.isNotEmpty
                              ? jobTitle
                              : 'Senior Flutter Developer',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          company.isNotEmpty ? company : 'Acme Technologies',
                          style: TextStyle(
                            fontSize: 12,
                            color: colors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: colors.primarySoft,
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: colors.primary,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '$progressPercent%',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: colors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              // Linear Progress Bar
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.pill),
                child: LinearProgressIndicator(
                  value: progressPercent / 100.0,
                  minHeight: 8,
                  backgroundColor: colors.border,
                  valueColor: AlwaysStoppedAnimation<Color>(colors.primary),
                ),
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Pipeline Progress',
                    style: TextStyle(fontSize: 11, color: colors.textSecondary),
                  ),
                  Text(
                    'Stage $stage of 5 · Running',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: colors.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              // 5-Stage Step Pipeline Details
              _buildStageItem(
                context,
                stageNumber: 1,
                title: 'Parse job description & semantic taxonomy',
                isCompleted: stage > 1,
                isActive: stage == 1,
              ),
              _buildStageItem(
                context,
                stageNumber: 2,
                title: 'Extract required core qualifications',
                isCompleted: stage > 2,
                isActive: stage == 2,
              ),
              _buildStageItem(
                context,
                stageNumber: 3,
                title: 'Scan resume version & align experience vectors',
                isCompleted: stage > 3,
                isActive: stage == 3,
              ),
              _buildStageItem(
                context,
                stageNumber: 4,
                title: 'Synthesize tailored bullet improvements',
                isCompleted: stage > 4,
                isActive: stage == 4,
              ),
              _buildStageItem(
                context,
                stageNumber: 5,
                title: 'Final quality assurance & alignment scorecard',
                isCompleted: stage > 5,
                isActive: stage == 5,
                isLast: true,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        if (onContinueInBackground != null)
          OutlinedButton.icon(
            onPressed: onContinueInBackground,
            icon: const Icon(Icons.arrow_back),
            label: const Text('Return to Sessions / Continue in Background'),
          ),
      ],
    );
  }

  Widget _buildStageItem(
    BuildContext context, {
    required int stageNumber,
    required String title,
    required bool isCompleted,
    required bool isActive,
    bool isLast = false,
  }) {
    final colors = AppColors.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isCompleted
                    ? const Color(0xFF087E78)
                    : isActive
                    ? colors.primary
                    : colors.border,
              ),
              child: Center(
                child: isCompleted
                    ? const Icon(Icons.check, size: 14, color: Colors.white)
                    : isActive
                    ? const SizedBox(
                        width: 10,
                        height: 10,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        '$stageNumber',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: colors.textSecondary,
                        ),
                      ),
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 28,
                color: isCompleted ? const Color(0xFF087E78) : colors.border,
                margin: const EdgeInsets.symmetric(vertical: 2),
              ),
          ],
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                color: isActive
                    ? colors.primary
                    : isCompleted
                    ? colors.textPrimary
                    : colors.textSecondary,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Screen 44: Job Analysis Overview View
class JobAnalysisOverviewView extends StatelessWidget {
  const JobAnalysisOverviewView({
    super.key,
    required this.analysis,
    required this.targetRole,
    required this.company,
    required this.onReviewSuggestions,
    required this.onViewRequirements,
    required this.onInspectRequirement,
  });

  final OptimizationAnalysis analysis;
  final String targetRole;
  final String company;
  final VoidCallback onReviewSuggestions;
  final VoidCallback onViewRequirements;
  final ValueChanged<JobRequirement> onInspectRequirement;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final score = analysis.beforeScore;
    final totalReqs = analysis.requirements.length;
    final strongCount = analysis.requirements
        .where((r) => r.match == RequirementMatch.matched)
        .length;
    final partialCount = analysis.requirements
        .where((r) => r.match == RequirementMatch.partial)
        .length;
    final gapCount = analysis.requirements
        .where((r) => r.match == RequirementMatch.missing)
        .length;
    final suggestionCount = analysis.suggestions.length;

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        // Role Context Card
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: colors.primarySoft,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: Icon(
                      Icons.work_outline,
                      color: colors.primary,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          targetRole.isNotEmpty
                              ? targetRole
                              : 'Senior Flutter Developer',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '$company · Baseline Snapshot v2.4',
                          style: TextStyle(
                            fontSize: 12,
                            color: colors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        // Compatibility Scorecard
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Overall Compatibility',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Semantic alignment against extracted rubric',
                        style: TextStyle(
                          fontSize: 12,
                          color: colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '$score%',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: colors.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.pill),
                child: LinearProgressIndicator(
                  value: score / 100.0,
                  minHeight: 10,
                  backgroundColor: colors.border,
                  valueColor: AlwaysStoppedAnimation<Color>(colors.primary),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Note: Compatibility reflects keyword and responsibility alignment. It does not predict employer hiring decisions or interview probability.',
                style: TextStyle(
                  fontSize: 11,
                  color: colors.textSecondary,
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              // Requirement breakdown stats
              Row(
                children: [
                  _buildStatBadge(
                    context,
                    label: 'Strong',
                    count: strongCount,
                    color: const Color(0xFF087E78),
                    bgColor: const Color(0xFFE1F4F1),
                  ),
                  const SizedBox(width: 8),
                  _buildStatBadge(
                    context,
                    label: 'Partial',
                    count: partialCount,
                    color: const Color(0xFFA15C00),
                    bgColor: const Color(0xFFFFF4E5),
                  ),
                  const SizedBox(width: 8),
                  _buildStatBadge(
                    context,
                    label: 'Gaps',
                    count: gapCount,
                    color: const Color(0xFFBA1A1A),
                    bgColor: const Color(0xFFFFDAD6),
                  ),
                  const Spacer(),
                  Text(
                    '$totalReqs total requirements',
                    style: TextStyle(fontSize: 11, color: colors.textSecondary),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        // Top Qualifications Preview
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Extracted Core Requirements',
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            TextButton(
              onPressed: onViewRequirements,
              child: const Text('View All', style: TextStyle(fontSize: 12)),
            ),
          ],
        ),
        ...analysis.requirements.take(3).map((req) {
          final isMatched = req.match == RequirementMatch.matched;
          final isPartial = req.match == RequirementMatch.partial;
          return Container(
            margin: const EdgeInsets.only(bottom: AppSpacing.sm),
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: colors.border),
            ),
            child: Row(
              children: [
                Icon(
                  isMatched
                      ? Icons.check_circle
                      : isPartial
                      ? Icons.adjust
                      : Icons.radio_button_unchecked,
                  size: 20,
                  color: isMatched
                      ? const Color(0xFF087E78)
                      : isPartial
                      ? const Color(0xFFA15C00)
                      : const Color(0xFFBA1A1A),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        req.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        req.explanation,
                        style: TextStyle(
                          fontSize: 11,
                          color: colors.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right, size: 20),
                  onPressed: () => onInspectRequirement(req),
                ),
              ],
            ),
          );
        }),
        const SizedBox(height: AppSpacing.lg),

        // Primary Action: Continue to Suggestions Workspace
        AppButton(
          label: 'Review Suggestions ($suggestionCount prepared)',
          onPressed: onReviewSuggestions,
        ),
      ],
    );
  }

  Widget _buildStatBadge(
    BuildContext context, {
    required String label,
    required int count,
    required Color color,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        '$label: $count',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }
}

/// Screen 46: Job Analysis Requirements & Keywords View
class JobAnalysisRequirementsKeywordsView extends StatefulWidget {
  const JobAnalysisRequirementsKeywordsView({
    super.key,
    required this.requirements,
    required this.keywords,
    required this.onInspectRequirement,
    required this.onAddMissingSkill,
  });

  final List<JobRequirement> requirements;
  final List<String> keywords;
  final ValueChanged<JobRequirement> onInspectRequirement;
  final ValueChanged<String> onAddMissingSkill;

  @override
  State<JobAnalysisRequirementsKeywordsView> createState() =>
      _JobAnalysisRequirementsKeywordsViewState();
}

class _JobAnalysisRequirementsKeywordsViewState
    extends State<JobAnalysisRequirementsKeywordsView> {
  int _tabIndex = 0; // 0: Requirements, 1: Keywords
  RequirementMatch? _matchFilter;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final reqs = _matchFilter == null
        ? widget.requirements
        : widget.requirements.where((r) => r.match == _matchFilter).toList();

    return Column(
      children: [
        // Tab Selector (Requirements vs Keywords)
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: colors.screenBackground,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: colors.border),
            ),
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _tabIndex = 0),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: _tabIndex == 0
                            ? colors.surface
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                        boxShadow: _tabIndex == 0
                            ? [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.04),
                                  blurRadius: 4,
                                ),
                              ]
                            : null,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.fact_check,
                            size: 16,
                            color: _tabIndex == 0
                                ? colors.primary
                                : colors.textSecondary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Requirements (${widget.requirements.length})',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: _tabIndex == 0
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: _tabIndex == 0
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
                    onTap: () => setState(() => _tabIndex = 1),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: _tabIndex == 1
                            ? colors.surface
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                        boxShadow: _tabIndex == 1
                            ? [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.04),
                                  blurRadius: 4,
                                ),
                              ]
                            : null,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.key,
                            size: 16,
                            color: _tabIndex == 1
                                ? colors.primary
                                : colors.textSecondary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Keywords (${widget.keywords.length})',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: _tabIndex == 1
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: _tabIndex == 1
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

        // Tab Content
        Expanded(
          child: _tabIndex == 0
              ? _buildRequirementsTab(context, reqs)
              : _buildKeywordsTab(context),
        ),
      ],
    );
  }

  Widget _buildRequirementsTab(
    BuildContext context,
    List<JobRequirement> reqs,
  ) {
    final colors = AppColors.of(context);
    return Column(
      children: [
        // Horizontal Filter Chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Row(
            children: [
              FilterChip(
                label: Text('All (${widget.requirements.length})'),
                selected: _matchFilter == null,
                onSelected: (_) => setState(() => _matchFilter = null),
              ),
              const SizedBox(width: 6),
              FilterChip(
                label: const Text('Strong evidence'),
                selected: _matchFilter == RequirementMatch.matched,
                onSelected: (_) =>
                    setState(() => _matchFilter = RequirementMatch.matched),
              ),
              const SizedBox(width: 6),
              FilterChip(
                label: const Text('Partial'),
                selected: _matchFilter == RequirementMatch.partial,
                onSelected: (_) =>
                    setState(() => _matchFilter = RequirementMatch.partial),
              ),
              const SizedBox(width: 6),
              FilterChip(
                label: const Text('Potential gap'),
                selected: _matchFilter == RequirementMatch.missing,
                onSelected: (_) =>
                    setState(() => _matchFilter = RequirementMatch.missing),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(AppSpacing.md),
            itemCount: reqs.length,
            itemBuilder: (context, index) {
              final req = reqs[index];
              final isMatched = req.match == RequirementMatch.matched;
              final isPartial = req.match == RequirementMatch.partial;
              final matchColor = isMatched
                  ? const Color(0xFF087E78)
                  : isPartial
                  ? const Color(0xFFA15C00)
                  : const Color(0xFFBA1A1A);

              return Container(
                margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(color: colors.border),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(AppSpacing.sm),
                  title: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: matchColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                        ),
                        child: Text(
                          isMatched
                              ? 'Strong evidence'
                              : isPartial
                              ? 'Partial match'
                              : 'Potential gap',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: matchColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        req.importance,
                        style: TextStyle(
                          fontSize: 11,
                          color: colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          req.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          req.explanation,
                          style: TextStyle(
                            fontSize: 12,
                            color: colors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  trailing: OutlinedButton(
                    onPressed: () => widget.onInspectRequirement(req),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      minimumSize: Size.zero,
                    ),
                    child: const Text(
                      'Inspect',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildKeywordsTab(BuildContext context) {
    final colors = AppColors.of(context);
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        Text(
          'Target Keywords & ATS Relevance',
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          'Keywords identified from the job description with estimated relevance weighting.',
          style: TextStyle(fontSize: 12, color: colors.textSecondary),
        ),
        const SizedBox(height: AppSpacing.md),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: widget.keywords.map((kw) {
            return ActionChip(
              avatar: const Icon(
                Icons.check,
                size: 14,
                color: Color(0xFF087E78),
              ),
              label: Text(kw, style: const TextStyle(fontSize: 12)),
              onPressed: () => widget.onAddMissingSkill(kw),
            );
          }).toList(),
        ),
      ],
    );
  }
}

/// Screen 49: Job Analysis Source Evidence Inspection Sheet
class JobAnalysisSourceEvidenceSheet extends StatelessWidget {
  const JobAnalysisSourceEvidenceSheet({
    super.key,
    required this.requirement,
    required this.onIncludeInSuggestions,
    required this.onDismiss,
  });

  final JobRequirement requirement;
  final VoidCallback onIncludeInSuggestions;
  final VoidCallback onDismiss;

  static Future<void> show(
    BuildContext context, {
    required JobRequirement requirement,
    required VoidCallback onIncludeInSuggestions,
    required VoidCallback onDismiss,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => JobAnalysisSourceEvidenceSheet(
        requirement: requirement,
        onIncludeInSuggestions: onIncludeInSuggestions,
        onDismiss: onDismiss,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final isMatched = requirement.match == RequirementMatch.matched;
    final isPartial = requirement.match == RequirementMatch.partial;
    final matchColor = isMatched
        ? const Color(0xFF087E78)
        : isPartial
        ? const Color(0xFFA15C00)
        : const Color(0xFFBA1A1A);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colors.border,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.manage_search,
                              size: 16,
                              color: colors.primary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'REQUIREMENT INSPECTION',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: colors.primary,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          requirement.name,
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.md),
                children: [
                  // Badges
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: matchColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                        ),
                        child: Text(
                          isMatched
                              ? 'Strong Evidence Found'
                              : isPartial
                              ? 'Partial Evidence'
                              : 'Potential Gap',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: matchColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: colors.screenBackground,
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                          border: Border.all(color: colors.border),
                        ),
                        child: Text(
                          requirement.importance,
                          style: TextStyle(
                            fontSize: 11,
                            color: colors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Job Description Excerpt (Source Text)
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: colors.screenBackground,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      border: Border.all(color: colors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.description_outlined,
                              size: 16,
                              color: colors.primary,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Job Description Excerpt (Source Text)',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: colors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '“${requirement.sourceText ?? requirement.explanation}”',
                          style: TextStyle(
                            fontSize: 13,
                            fontStyle: FontStyle.italic,
                            color: colors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Extracted from Section: Technical Responsibilities',
                          style: TextStyle(
                            fontSize: 11,
                            color: colors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Resume Evidence Match
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: isMatched
                          ? const Color(0xFFE1F4F1)
                          : colors.surface,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      border: Border.all(
                        color: isMatched
                            ? const Color(0xFF087E78).withOpacity(0.3)
                            : colors.border,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.history_edu,
                              size: 16,
                              color: isMatched
                                  ? const Color(0xFF087E78)
                                  : colors.textSecondary,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Resume Evidence Match',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: isMatched
                                    ? const Color(0xFF087E78)
                                    : colors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          requirement.evidence != null &&
                                  requirement.evidence!.isNotEmpty
                              ? requirement.evidence!
                              : 'No explicit keyword match identified in baseline resume.',
                          style: TextStyle(
                            fontSize: 13,
                            color: colors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // Actions
                  AppButton(
                    label: 'Include in Tailored Suggestions',
                    onPressed: () {
                      Navigator.pop(context);
                      onIncludeInSuggestions();
                    },
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  OutlinedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      onDismiss();
                    },
                    child: const Text('Mark as Not Relevant'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
