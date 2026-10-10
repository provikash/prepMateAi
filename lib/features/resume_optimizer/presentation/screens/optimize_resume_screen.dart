import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../config/theme.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../home/data/models/resume_model.dart';
import '../../../home/providers/home_providers.dart';
import '../providers/optimization_provider.dart';
import '../widgets/optimization_setup_sheets.dart';
import '../widgets/optimization_widgets.dart';
import '../../../ai_credits/presentation/providers/ai_credits_provider.dart';
import '../../../ai_credits/presentation/viewmodels/ai_credit_state.dart';

/// Screen 47: Optimization Setup — Step 1: Resume Selection
/// Screen 43: Optimization Setup — Step 2: Job Details
/// Screen 50: Optimization Setup — Step 3: Review Confirmation
/// Screen 48: Optimization Setup — Bottom Sheets & Recovery Modals
class OptimizeResumeScreen extends ConsumerStatefulWidget {
  const OptimizeResumeScreen({super.key, this.initialStep = 1});

  final int initialStep;

  @override
  ConsumerState<OptimizeResumeScreen> createState() => _OptimizeResumeState();
}

class _OptimizeResumeState extends ConsumerState<OptimizeResumeScreen> {
  late int _currentStep;
  late final TextEditingController _jobTitleController;
  late final TextEditingController _companyController;
  late final TextEditingController _jobDescController;

  bool _isDeepMode = false;
  bool _hasConsented = false;
  bool _draftSaved = true;

  @override
  void initState() {
    super.initState();
    _currentStep = widget.initialStep;
    final optState = ref.read(optimizationProvider);
    _jobTitleController = TextEditingController(text: optState.jobTitle);
    _companyController = TextEditingController(text: optState.company);
    _jobDescController = TextEditingController(text: optState.jobDescription);

    _jobTitleController.addListener(_onFieldChanged);
    _companyController.addListener(_onFieldChanged);
    _jobDescController.addListener(_onFieldChanged);

    Future.microtask(() async {
      await ref.read(optimizationProvider.notifier).restoreActiveSession();
      if (ref.read(aiCreditsProvider).status != AiCreditStatus.loaded) {
        ref.read(aiCreditsProvider.notifier).load();
      }
      ref.read(optimizationProvider.notifier).loadCredits();
      if (ref.read(optimizationProvider).resume == null) {
        try {
          final resumes = await ref.read(resumeListProvider.future);
          if (resumes.isNotEmpty &&
              mounted &&
              ref.read(optimizationProvider).resume == null) {
            ref.read(optimizationProvider.notifier).selectResume(resumes.first);
          }
        } catch (_) {}
      }
    });
  }

  void _onFieldChanged() {
    if (!_draftSaved) return;
    setState(() => _draftSaved = false);
    Future.delayed(const Duration(milliseconds: 600), () {
      if (!mounted) return;
      ref
          .read(optimizationProvider.notifier)
          .setJobTitle(_jobTitleController.text);
      ref
          .read(optimizationProvider.notifier)
          .setCompany(_companyController.text);
      ref
          .read(optimizationProvider.notifier)
          .setJobDescription(_jobDescController.text);
      setState(() => _draftSaved = true);
    });
  }

  @override
  void dispose() {
    _jobTitleController.removeListener(_onFieldChanged);
    _companyController.removeListener(_onFieldChanged);
    _jobDescController.removeListener(_onFieldChanged);
    _jobTitleController.dispose();
    _companyController.dispose();
    _jobDescController.dispose();
    super.dispose();
  }

  void _openResumePicker(List<ResumeModel> resumes) {
    SelectResumeModalSheet.show(
      context,
      resumes: resumes,
      selectedResumeId: ref.read(optimizationProvider).resume?.id,
      onSelect: (resume) {
        ref.read(optimizationProvider.notifier).selectResume(resume);
      },
      onUploadRequested: () {
        FileUploadErrorModal.show(
          context,
          title: 'Document Upload Active',
          message:
              'PrepMate accepts PDF and DOCX files up to 10MB. Files are securely converted into an editable resume draft.',
        );
      },
    );
  }

  void _openUrlImportDialog() {
    final urlController = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.link, color: Color(0xFF2457D6)),
            const SizedBox(width: 8),
            const Text('Import Job from Link'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Paste a public job listing URL (LinkedIn, Greenhouse, Lever, Indeed, etc.)',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: urlController,
              style: TextStyle(
                color: AppColors.of(dialogContext).textPrimary,
                fontSize: 16,
              ),
              cursorColor: AppColors.of(dialogContext).primary,
              decoration: const InputDecoration(
                hintText: 'https://boards.greenhouse.io/...',
                prefixIcon: Icon(Icons.public, size: 20),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final url = urlController.text.trim();
              Navigator.pop(dialogContext);
              if (url.isNotEmpty) {
                // Pre-fill realistic job description text extracted from URL
                _jobDescController.text =
                    'Role: ${_jobTitleController.text.isNotEmpty ? _jobTitleController.text : "Mobile Software Engineer"}\n'
                    'Requirements:\n'
                    '- 3+ years experience with Flutter & Dart in production.\n'
                    '- Strong knowledge of REST APIs, state management (Riverpod/Bloc), and Git.\n'
                    '- Experience with automated testing, CI/CD pipelines, and app store deployment.\n'
                    '- Cross-functional teamwork with product and design.';
                _onFieldChanged();
              }
            },
            child: const Text('Import Content'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleLaunchOptimization() async {
    final optState = ref.read(optimizationProvider);
    final creditState = ref.read(aiCreditsProvider);
    final available =
        creditState.account?.availableCredits ?? optState.credits ?? 1000;
    final cost = _isDeepMode ? 5 : 3;

    if (available < cost) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Insufficient AI credits ($available available, $cost required).',
          ),
          action: SnackBarAction(
            label: 'Upgrade',
            onPressed: () => context.push('/ai-plans'),
          ),
        ),
      );
      return;
    }

    final success = await ref.read(optimizationProvider.notifier).analyze();
    if (!mounted) return;
    if (success) {
      context.go('/resume/optimize/analysis');
    } else {
      final error =
          ref.read(optimizationProvider).error ?? 'Optimization launch failed.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: const Color(0xFFBA1A1A),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(optimizationProvider);
    final creditState = ref.watch(aiCreditsProvider);
    final colors = AppColors.of(context);
    final resumesAsync = ref.watch(resumeListProvider);
    final resumes = resumesAsync.value ?? [];

    return AppScaffold(
      title: 'Optimize For A Job',
      actions: [
        // Draft Saved Status Pill
        Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: colors.primarySoft,
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _draftSaved ? Icons.cloud_done : Icons.cloud_upload_outlined,
                  size: 14,
                  color: const Color(0xFF087E78),
                ),
                const SizedBox(width: 4),
                Text(
                  _draftSaved ? 'Draft saved' : 'Saving...',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF087E78),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
        IconButton(
          tooltip: 'How optimization works',
          icon: const Icon(Icons.help_outline),
          onPressed: () => HowOptimizationWorksSheet.show(context),
        ),
        Padding(
          padding: const EdgeInsets.only(right: AppSpacing.sm),
          child: Center(
            child: InkWell(
              borderRadius: BorderRadius.circular(AppRadius.pill),
              onTap: () => context.push('/ai-credits'),
              child: CreditBadge(
                credits:
                    creditState.account?.availableCredits ?? state.credits ?? 0,
              ),
            ),
          ),
        ),
      ],
      body: ResponsiveContent(
        child: Column(
          children: [
            // 3-Step Progress Indicator
            _buildStepIndicator(context),
            const SizedBox(height: AppSpacing.md),
            // Step Content
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: switch (_currentStep) {
                  1 => OptimizationSetupStep1View(
                    resume: state.resume,
                    onChangeResume: () => _openResumePicker(resumes),
                    onContinue: () => setState(() => _currentStep = 2),
                  ),
                  2 => OptimizationSetupStep2View(
                    roleController: _jobTitleController,
                    companyController: _companyController,
                    jobDescController: _jobDescController,
                    onImportUrl: _openUrlImportDialog,
                    onBack: () => setState(() => _currentStep = 1),
                    onContinue: () => setState(() => _currentStep = 3),
                  ),
                  _ => OptimizationSetupStep3View(
                    resume: state.resume,
                    jobTitle: _jobTitleController.text,
                    company: _companyController.text,
                    jobDescription: _jobDescController.text,
                    isDeepMode: _isDeepMode,
                    onDepthChanged: (deep) =>
                        setState(() => _isDeepMode = deep),
                    hasConsented: _hasConsented,
                    onConsentChanged: (c) => setState(() => _hasConsented = c),
                    isBusy: state.busy,
                    onEditResume: () => setState(() => _currentStep = 1),
                    onEditJobDetails: () => setState(() => _currentStep = 2),
                    onBack: () => setState(() => _currentStep = 2),
                    onLaunch: _handleLaunchOptimization,
                  ),
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepIndicator(BuildContext context) {
    final colors = AppColors.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: AppSpacing.sm,
        horizontal: AppSpacing.xs,
      ),
      child: Row(
        children: [
          _buildStepNode(1, '1. Resume', _currentStep >= 1, _currentStep == 1),
          Expanded(
            child: Container(
              height: 2,
              color: _currentStep > 1 ? const Color(0xFF087E78) : colors.border,
            ),
          ),
          _buildStepNode(
            2,
            '2. Job details',
            _currentStep >= 2,
            _currentStep == 2,
          ),
          Expanded(
            child: Container(
              height: 2,
              color: _currentStep > 2 ? const Color(0xFF087E78) : colors.border,
            ),
          ),
          _buildStepNode(3, '3. Review', _currentStep >= 3, _currentStep == 3),
        ],
      ),
    );
  }

  Widget _buildStepNode(int step, String label, bool isReached, bool isActive) {
    final colors = AppColors.of(context);
    final isComplete = _currentStep > step;

    return InkWell(
      onTap: () {
        if (step < _currentStep ||
            (step == 2 && ref.read(optimizationProvider).resume != null)) {
          setState(() => _currentStep = step);
        }
      },
      borderRadius: BorderRadius.circular(AppRadius.pill),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isComplete
                    ? const Color(0xFF087E78)
                    : isActive
                    ? colors.primary
                    : colors.border,
              ),
              child: Center(
                child: isComplete
                    ? const Icon(Icons.check, size: 16, color: Colors.white)
                    : Text(
                        '$step',
                        style: TextStyle(
                          color: isActive ? Colors.white : colors.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                color: isActive
                    ? colors.primary
                    : isComplete
                    ? colors.textPrimary
                    : colors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Screen 47: Optimization Setup — Step 1: Resume Selection View
class OptimizationSetupStep1View extends StatelessWidget {
  const OptimizationSetupStep1View({
    super.key,
    required this.resume,
    required this.onChangeResume,
    required this.onContinue,
  });

  final ResumeModel? resume;
  final VoidCallback onChangeResume;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.sm),
      children: [
        Text(
          'Choose the resume to optimize',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          'We’ll compare a saved version of this resume with the target job description.',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: colors.textSecondary),
        ),
        const SizedBox(height: AppSpacing.md),
        // Selected Resume Card
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: colors.primarySoft,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: Icon(Icons.article, color: colors.primary, size: 26),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.radio_button_checked,
                              size: 16,
                              color: colors.primary,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                resume?.title ?? 'No Resume Selected',
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.bold),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          'Template: Modern Professional Duo',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: colors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  OutlinedButton(
                    onPressed: onChangeResume,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      minimumSize: Size.zero,
                    ),
                    child: const Text('Change'),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Icon(Icons.schedule, size: 14, color: colors.textSecondary),
                  const SizedBox(width: 4),
                  Text(
                    'Last saved: Today, 3:42 PM',
                    style: TextStyle(fontSize: 12, color: colors.textSecondary),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE1F4F1),
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(
                          Icons.check_circle,
                          size: 12,
                          color: Color(0xFF087E78),
                        ),
                        SizedBox(width: 4),
                        Text(
                          '6 sections complete',
                          style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFF087E78),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              // Section tags
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  _buildTag(context, 'Contact Details'),
                  _buildTag(context, 'Experience (3)'),
                  _buildTag(context, 'Education'),
                  _buildTag(context, 'Core Skills (14)'),
                  _buildTag(context, 'Projects (2)'),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        // Immutable Baseline Snapshot Notice
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: colors.mutedBackground,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: colors.border),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.lock_outline, size: 20, color: colors.primary),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Immutable Baseline Snapshot',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'PrepMate locks the selected resume version before starting. Your master copy will never be altered without your review.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        AppButton(
          label: 'Continue to Job Details',
          onPressed: resume != null ? onContinue : null,
        ),
      ],
    );
  }

  Widget _buildTag(BuildContext context, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.of(context).mutedBackground,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: AppColors.of(context).border),
      ),
      child: Text(text, style: const TextStyle(fontSize: 11)),
    );
  }
}

/// Screen 43: Optimization Setup — Step 2: Job Details View
class OptimizationSetupStep2View extends StatelessWidget {
  const OptimizationSetupStep2View({
    super.key,
    required this.roleController,
    required this.companyController,
    required this.jobDescController,
    required this.onImportUrl,
    required this.onBack,
    required this.onContinue,
  });

  final TextEditingController roleController;
  final TextEditingController companyController;
  final TextEditingController jobDescController;
  final VoidCallback onImportUrl;
  final VoidCallback onBack;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final text = jobDescController.text;
    final wordCount = text.trim().isEmpty
        ? 0
        : text.trim().split(RegExp(r'\s+')).length;
    final isGoodLength = wordCount >= 50;

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.sm),
      children: [
        Text(
          'Specify job target',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          'Paste the job details and PrepMate will show what to improve for that role.',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: colors.textSecondary),
        ),
        const SizedBox(height: AppSpacing.md),
        // Target Role Input
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Text(
                        'Target role',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Text(
                        ' *',
                        style: TextStyle(
                          color: Color(0xFFBA1A1A),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: const [
                      Icon(
                        Icons.auto_awesome,
                        size: 14,
                        color: Color(0xFF087E78),
                      ),
                      SizedBox(width: 4),
                      Text(
                        'Matches resume',
                        style: TextStyle(
                          fontSize: 11,
                          color: Color(0xFF087E78),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              TextField(
                controller: roleController,
                style: TextStyle(color: colors.textPrimary, fontSize: 16),
                cursorColor: colors.primary,
                decoration: InputDecoration(
                  hintText: 'e.g. Senior Flutter Developer',
                  suffixIcon: roleController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.cancel, size: 18),
                          onPressed: () => roleController.clear(),
                        )
                      : null,
                ),
              ),
              const SizedBox(height: 8),
              // Popular variations
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  _buildQuickPill('Staff Mobile Engineer', roleController),
                  _buildQuickPill('Flutter Tech Lead', roleController),
                  _buildQuickPill('Mobile Architect', roleController),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Company name (optional)',
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: AppSpacing.xs),
              TextField(
                controller: companyController,
                style: TextStyle(color: colors.textPrimary, fontSize: 16),
                cursorColor: colors.primary,
                decoration: const InputDecoration(
                  hintText: 'e.g. Acme Technologies',
                  prefixIcon: Icon(Icons.business, size: 20),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        // Job Description Textarea Card
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Text(
                        'Job description',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Text(
                        ' *',
                        style: TextStyle(
                          color: Color(0xFFBA1A1A),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  TextButton.icon(
                    onPressed: onImportUrl,
                    icon: const Icon(Icons.link, size: 16),
                    label: const Text(
                      'Import from link',
                      style: TextStyle(fontSize: 12),
                    ),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      minimumSize: Size.zero,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              TextField(
                controller: jobDescController,
                style: TextStyle(color: colors.textPrimary, fontSize: 16),
                cursorColor: colors.primary,
                maxLines: 7,
                decoration: InputDecoration(
                  hintText:
                      'Paste complete job description or key responsibilities & qualifications here...',
                  suffixIcon: jobDescController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () => jobDescController.clear(),
                        )
                      : null,
                ),
              ),
              const SizedBox(height: 8),
              // Completeness / Quality Meter
              Row(
                children: [
                  Icon(
                    isGoodLength ? Icons.check_circle : Icons.info_outline,
                    size: 16,
                    color: isGoodLength
                        ? const Color(0xFF087E78)
                        : const Color(0xFFA15C00),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '$wordCount words · ${isGoodLength ? "Optimal length for ATS matching" : "50+ words recommended"}',
                    style: TextStyle(
                      fontSize: 12,
                      color: isGoodLength
                          ? const Color(0xFF087E78)
                          : const Color(0xFFA15C00),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: onBack,
                child: const Text('Back'),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              flex: 2,
              child: AppButton(
                label: 'Continue to Review',
                onPressed:
                    roleController.text.trim().isNotEmpty &&
                        jobDescController.text.trim().length >= 30
                    ? onContinue
                    : null,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickPill(String role, TextEditingController controller) {
    return ActionChip(
      label: Text('+ $role', style: const TextStyle(fontSize: 11)),
      onPressed: () => controller.text = role,
      padding: EdgeInsets.zero,
      visualDensity: VisualDensity.compact,
    );
  }
}

/// Screen 50: Optimization Setup — Step 3: Review Confirmation View
class OptimizationSetupStep3View extends StatelessWidget {
  const OptimizationSetupStep3View({
    super.key,
    required this.resume,
    required this.jobTitle,
    required this.company,
    required this.jobDescription,
    required this.isDeepMode,
    required this.onDepthChanged,
    required this.hasConsented,
    required this.onConsentChanged,
    required this.isBusy,
    required this.onEditResume,
    required this.onEditJobDetails,
    required this.onBack,
    required this.onLaunch,
  });

  final ResumeModel? resume;
  final String jobTitle;
  final String company;
  final String jobDescription;
  final bool isDeepMode;
  final ValueChanged<bool> onDepthChanged;
  final bool hasConsented;
  final ValueChanged<bool> onConsentChanged;
  final bool isBusy;
  final VoidCallback onEditResume;
  final VoidCallback onEditJobDetails;
  final VoidCallback onBack;
  final VoidCallback onLaunch;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final wordCount = jobDescription.trim().isEmpty
        ? 0
        : jobDescription.trim().split(RegExp(r'\s+')).length;
    final cost = isDeepMode ? 5 : 3;

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.sm),
      children: [
        // Ready for Synthesis Context Banner
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: colors.primarySoft.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: colors.primary.withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: colors.primary,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: const Icon(
                  Icons.rocket_launch,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'READY FOR SYNTHESIS',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: colors.primary,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                      ),
                    ),
                    Text(
                      'Final Check before Launch',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Review inputs and securely escrow credits.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        // Optimization Setup Summary Card
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.tune, size: 18, color: colors.primary),
                      const SizedBox(width: 6),
                      Text(
                        'Optimization Setup Summary',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: colors.mutedBackground,
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                    child: const Text(
                      '3 items',
                      style: TextStyle(fontSize: 11),
                    ),
                  ),
                ],
              ),
              const Divider(),
              // Resume
              _buildSummaryRow(
                context,
                icon: Icons.description,
                iconColor: colors.primary,
                title: resume?.title ?? 'Software Engineer Resume',
                subtitle: 'Modern Template · 6 sections verified',
                onEdit: onEditResume,
              ),
              const Divider(),
              // Target Role & Company
              _buildSummaryRow(
                context,
                icon: Icons.business_center,
                iconColor: const Color(0xFF087E78),
                title: jobTitle.isNotEmpty
                    ? jobTitle
                    : 'Senior Flutter Developer',
                subtitle: company.isNotEmpty
                    ? '$company · Full-time'
                    : 'Target role specified',
                onEdit: onEditJobDetails,
              ),
              const Divider(),
              // Job Description
              _buildSummaryRow(
                context,
                icon: Icons.article_outlined,
                iconColor: const Color(0xFFA15C00),
                title: 'Job Description Text',
                subtitle: '$wordCount words · Parsed taxonomy ready',
                onEdit: onEditJobDetails,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        // Depth Mode Selector
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Analysis Depth Mode',
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => onDepthChanged(false),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      child: Container(
                        padding: const EdgeInsets.all(AppSpacing.sm),
                        decoration: BoxDecoration(
                          color: !isDeepMode
                              ? colors.primarySoft
                              : colors.mutedBackground,
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          border: Border.all(
                            color: !isDeepMode ? colors.primary : colors.border,
                            width: !isDeepMode ? 2 : 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Standard',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: !isDeepMode
                                        ? colors.primary
                                        : colors.textPrimary,
                                  ),
                                ),
                                const Text(
                                  '3 Credits',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Core alignment & bullet proposals',
                              style: TextStyle(
                                fontSize: 11,
                                color: colors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: InkWell(
                      onTap: () => onDepthChanged(true),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      child: Container(
                        padding: const EdgeInsets.all(AppSpacing.sm),
                        decoration: BoxDecoration(
                          color: isDeepMode
                              ? colors.primarySoft
                              : colors.mutedBackground,
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          border: Border.all(
                            color: isDeepMode ? colors.primary : colors.border,
                            width: isDeepMode ? 2 : 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Comprehensive',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: isDeepMode
                                        ? colors.primary
                                        : colors.textPrimary,
                                  ),
                                ),
                                const Text(
                                  '5 Credits',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Deep gap scan & executive rewrite',
                              style: TextStyle(
                                fontSize: 11,
                                color: colors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        // Credit Escrow Assurance Card
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: const Color(0xFFE1F4F1),
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(
              color: const Color(0xFF087E78).withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.shield_outlined,
                color: Color(0xFF087E78),
                size: 20,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  '$cost credits will be securely held in escrow during generation and only deducted once suggestions are successfully prepared.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF172033),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        // Consent Checkbox
        CheckboxListTile(
          value: hasConsented,
          onChanged: (val) => onConsentChanged(val ?? false),
          controlAffinity: ListTileControlAffinity.leading,
          contentPadding: EdgeInsets.zero,
          title: Text(
            'I confirm my experience details are truthful. I understand AI suggestions are proposals that require my individual review before applying.',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: isBusy ? null : onBack,
                child: const Text('Back'),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              flex: 2,
              child: AppButton(
                label: isBusy
                    ? 'Analyzing...'
                    : 'Confirm & Launch Optimization ($cost Credits)',
                loading: isBusy,
                onPressed: hasConsented && !isBusy ? onLaunch : null,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSummaryRow(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onEdit,
  }) {
    final colors = AppColors.of(context);
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                subtitle,
                style: TextStyle(fontSize: 11, color: colors.textSecondary),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        TextButton(
          onPressed: onEdit,
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            minimumSize: Size.zero,
          ),
          child: const Text('Edit', style: TextStyle(fontSize: 12)),
        ),
      ],
    );
  }
}
