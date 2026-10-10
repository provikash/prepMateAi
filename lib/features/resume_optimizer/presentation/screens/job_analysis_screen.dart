import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../config/theme.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/app_state.dart';
import '../../domain/optimization_models.dart';
import '../providers/optimization_provider.dart';
import '../widgets/job_analysis_widgets.dart';

/// Screen 44: Job Analysis — Overview
/// Screen 45: Job Analysis — Lifecycle & Edge States
/// Screen 46: Job Analysis — Requirements & Keywords
/// Screen 49: Job Analysis — Source Evidence Inspection Sheets
class JobAnalysisScreen extends ConsumerStatefulWidget {
  const JobAnalysisScreen({super.key});

  @override
  ConsumerState<JobAnalysisScreen> createState() => _JobAnalysisScreenState();
}

class _JobAnalysisScreenState extends ConsumerState<JobAnalysisScreen> {
  int _activeTab =
      0; // 0: Overview, 1: Requirements & Keywords, 2: Lifecycle Simulation

  void _inspectRequirement(JobRequirement req) {
    JobAnalysisSourceEvidenceSheet.show(
      context,
      requirement: req,
      onIncludeInSuggestions: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Included "${req.name}" in tailored suggestions priorities.',
            ),
          ),
        );
      },
      onDismiss: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Marked "${req.name}" as not relevant for this review.',
            ),
          ),
        );
      },
    );
  }

  void _showJobDescriptionSheet(String title, String company, String desc) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(ctx).size.height * 0.75,
        ),
        decoration: BoxDecoration(
          color: Theme.of(ctx).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '$title · $company',
              style: Theme.of(
                ctx,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            const Text(
              'Job description source text',
              style: TextStyle(color: Colors.grey),
            ),
            const Divider(),
            Expanded(
              child: SingleChildScrollView(
                child: Text(
                  desc.isNotEmpty ? desc : 'No description provided.',
                  style: const TextStyle(fontSize: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final optState = ref.watch(optimizationProvider);
    final analysis = optState.analysis;
    final colors = AppColors.of(context);

    // If currently running analysis, show Screen 45 Lifecycle View
    if (optState.busy) {
      return AppScaffold(
        title: 'Job Analysis',
        body: JobAnalysisLifecycleView(
          jobTitle: optState.jobTitle,
          company: optState.company,
          stage: optState.analysisStage > 0 ? optState.analysisStage : 3,
          progressPercent: optState.analysisStage * 25,
          onContinueInBackground: () => context.go('/resume/optimize/history'),
        ),
      );
    }

    if (analysis == null) {
      return AppScaffold(
        title: 'Job Analysis',
        body: AppErrorState(
          message: 'Run a job analysis before viewing results.',
          actionLabel: 'Start analysis',
          onAction: () => context.go('/resume/optimize'),
        ),
      );
    }

    final displayTitle = optState.jobTitle.isNotEmpty
        ? optState.jobTitle
        : 'Senior Flutter Developer';
    final displayCompany = optState.company.isNotEmpty
        ? optState.company
        : 'Acme Technologies';

    return AppScaffold(
      title: 'Job Analysis',
      actions: [
        IconButton(
          tooltip: 'About this analysis',
          icon: const Icon(Icons.info_outline),
          onPressed: () {
            showDialog(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('About Job Analysis'),
                content: const Text(
                  'PrepMate extracts requirements and key taxonomy from the job description and evaluates grounding evidence from your selected resume version. Suggestions are drafted as proposals and never alter your master resume.',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Close'),
                  ),
                ],
              ),
            );
          },
        ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert),
          onSelected: (val) {
            switch (val) {
              case 'jd':
                _showJobDescriptionSheet(
                  displayTitle,
                  displayCompany,
                  optState.jobDescription,
                );
                break;
              case 'simulate_lifecycle':
                setState(() => _activeTab = 2);
                break;
              case 'refresh':
                ref.read(optimizationProvider.notifier).analyze();
                break;
            }
          },
          itemBuilder: (ctx) => [
            const PopupMenuItem(
              value: 'jd',
              child: Text('View Job Description'),
            ),
            const PopupMenuItem(
              value: 'simulate_lifecycle',
              child: Text('Lifecycle State Previews'),
            ),
            const PopupMenuItem(
              value: 'refresh',
              child: Text('Re-run Analysis'),
            ),
          ],
        ),
      ],
      body: Column(
        children: [
          // Navigation Tab Bar
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.xs,
            ),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: colors.mutedBackground,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: colors.border),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => setState(() => _activeTab = 0),
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: _activeTab == 0
                              ? colors.cardBackground
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                          boxShadow: _activeTab == 0
                              ? [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.04),
                                    blurRadius: 4,
                                  ),
                                ]
                              : null,
                        ),
                        child: Center(
                          child: Text(
                            'Overview',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: _activeTab == 0
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: _activeTab == 0
                                  ? colors.primary
                                  : colors.textSecondary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: InkWell(
                      onTap: () => setState(() => _activeTab = 1),
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: _activeTab == 1
                              ? colors.cardBackground
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                          boxShadow: _activeTab == 1
                              ? [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.04),
                                    blurRadius: 4,
                                  ),
                                ]
                              : null,
                        ),
                        child: Center(
                          child: Text(
                            'Requirements & Keywords',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: _activeTab == 1
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: _activeTab == 1
                                  ? colors.primary
                                  : colors.textSecondary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Active View
          Expanded(
            child: switch (_activeTab) {
              0 => JobAnalysisOverviewView(
                analysis: analysis,
                targetRole: displayTitle,
                company: displayCompany,
                onReviewSuggestions: () =>
                    context.go('/resume/optimize/suggestions'),
                onViewRequirements: () => setState(() => _activeTab = 1),
                onInspectRequirement: _inspectRequirement,
              ),
              1 => JobAnalysisRequirementsKeywordsView(
                requirements: analysis.requirements,
                keywords:
                    analysis.overview?.keywords ??
                    const [
                      'Flutter',
                      'Dart',
                      'REST APIs',
                      'Riverpod',
                      'Git',
                      'CI/CD',
                    ],
                onInspectRequirement: _inspectRequirement,
                onAddMissingSkill: (skill) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Added "$skill" to skill target candidates.',
                      ),
                    ),
                  );
                },
              ),
              _ => JobAnalysisLifecycleView(
                jobTitle: displayTitle,
                company: displayCompany,
                stage: 3,
                progressPercent: 65,
                isDelayed: true,
                isLowConfidence: false,
                isResumeEdited: true,
                onContinueInBackground: () => setState(() => _activeTab = 0),
              ),
            },
          ),
        ],
      ),
    );
  }
}
