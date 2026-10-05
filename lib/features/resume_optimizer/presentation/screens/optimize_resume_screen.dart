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
import '../widgets/optimization_widgets.dart';
import '../../../ai_credits/presentation/providers/ai_credits_provider.dart';
import '../../../ai_credits/presentation/viewmodels/ai_credit_state.dart';
import '../../../ai_credits/presentation/widgets/credit_widgets.dart';
import '../../../ai_credits/domain/entities/ai_credit_models.dart';

class OptimizeResumeScreen extends ConsumerStatefulWidget {
  const OptimizeResumeScreen({super.key});

  @override
  ConsumerState<OptimizeResumeScreen> createState() => _OptimizeResumeState();
}

class _OptimizeResumeState extends ConsumerState<OptimizeResumeScreen> {
  late final TextEditingController _jobTitle;
  late final TextEditingController _company;
  late final TextEditingController _jobDescription;

  @override
  void initState() {
    super.initState();
    final optState = ref.read(optimizationProvider);
    _jobTitle = TextEditingController(text: optState.jobTitle);
    _company = TextEditingController(text: optState.company);
    _jobDescription = TextEditingController(text: optState.jobDescription);

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

  @override
  void dispose() {
    _jobTitle.dispose();
    _company.dispose();
    _jobDescription.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(optimizationProvider);
    final creditState = ref.watch(aiCreditsProvider);
    final account = creditState.account;
    final operation =
        creditState.operationById('resume_optimization') ??
        creditState.operationById('jd_optimization') ??
        AiOperation(
          operation: 'resume_optimization',
          displayName: 'Resume Optimization',
          description: 'Tailor your resume to a specific job opportunity.',
          creditCost: 10,
        );
    final availableCredits =
        account?.availableCredits ??
        ref.watch(optimizationProvider).credits ??
        1000;
    final colors = AppColors.of(context);

    return AppScaffold(
      title: 'Optimize Resume',
      description: 'Tailor your resume to a specific job opportunity.',
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: AppSpacing.sm),
          child: Center(
            child: InkWell(
              borderRadius: BorderRadius.circular(AppRadius.pill),
              onTap: () => context.push('/ai-credits'),
              child: CreditBadge(credits: account?.availableCredits ?? 0),
            ),
          ),
        ),
      ],
      body: ResponsiveContent(
        child: Column(
          children: [
            const OptimizationStepHeader(step: 1),
            const SizedBox(height: AppSpacing.lg),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'SELECTED RESUME',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: colors.textSecondary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    AppCard(child: _resumeTile(context, state.resume, colors)),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      'TARGET ROLE & COMPANY',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: colors.textSecondary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _jobTitle,
                            textCapitalization: TextCapitalization.words,
                            onChanged: (val) => ref
                                .read(optimizationProvider.notifier)
                                .setJobTitle(val),
                            decoration: const InputDecoration(
                              hintText: 'Job Title (e.g. Flutter Developer)',
                              prefixIcon: Icon(Icons.badge_outlined, size: 20),
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: TextField(
                            controller: _company,
                            textCapitalization: TextCapitalization.words,
                            onChanged: (val) => ref
                                .read(optimizationProvider.notifier)
                                .setCompany(val),
                            decoration: const InputDecoration(
                              hintText: 'Company (e.g. TechNova)',
                              prefixIcon: Icon(
                                Icons.business_outlined,
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'JOB DESCRIPTION',
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                color: colors.textSecondary,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        Row(
                          children: [
                            Text(
                              '${_jobDescription.text.length} / 8000',
                              style: Theme.of(context).textTheme.labelSmall
                                  ?.copyWith(
                                    color: _jobDescription.text.length < 80
                                        ? colors.warning
                                        : colors.textSecondary,
                                  ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            TextButton.icon(
                              key: const Key('fillSampleJdButton'),
                              onPressed: () {
                                const sampleJd =
                                    'We are seeking a Senior Full Stack Software Engineer to join our high-growth platform team. '
                                    'Key responsibilities include architecting scalable REST APIs in Python/Django, crafting '
                                    'cross-platform mobile applications using Flutter and Riverpod, integrating generative AI '
                                    'features, and optimizing PostgreSQL database performance with Docker and Redis caching. '
                                    'Requirements: 3+ years experience with Python, Django, Flutter, and cloud deployments.';
                                _jobDescription.text = sampleJd;
                                if (_jobTitle.text.isEmpty) {
                                  _jobTitle.text = 'Senior Full Stack Engineer';
                                  ref
                                      .read(optimizationProvider.notifier)
                                      .setJobTitle(
                                        'Senior Full Stack Engineer',
                                      );
                                }
                                if (_company.text.isEmpty) {
                                  _company.text = 'TechNova Labs';
                                  ref
                                      .read(optimizationProvider.notifier)
                                      .setCompany('TechNova Labs');
                                }
                                ref
                                    .read(optimizationProvider.notifier)
                                    .setJobDescription(sampleJd);
                                setState(() {});
                              },
                              icon: const Icon(Icons.paste, size: 14),
                              label: const Text(
                                'Fill Sample JD',
                                style: TextStyle(fontSize: 12),
                              ),
                              style: TextButton.styleFrom(
                                visualDensity: VisualDensity.compact,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    TextField(
                      controller: _jobDescription,
                      minLines: 8,
                      maxLines: 14,
                      maxLength: 8000,
                      onChanged: (value) {
                        ref
                            .read(optimizationProvider.notifier)
                            .setJobDescription(value);
                        setState(() {});
                      },
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        hintText:
                            'Paste the target job description here (minimum 80 characters)...',
                        alignLabelWithHint: true,
                        counterText: '',
                        suffixIcon: _jobDescription.text.isEmpty
                            ? null
                            : IconButton(
                                tooltip: 'Clear job description',
                                icon: const Icon(Icons.close),
                                onPressed: () {
                                  _jobDescription.clear();
                                  ref
                                      .read(optimizationProvider.notifier)
                                      .setJobDescription('');
                                  setState(() {});
                                },
                              ),
                      ),
                    ),
                    if (_jobDescription.text.isNotEmpty &&
                        _jobDescription.text.trim().length < 80) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'Minimum 80 characters required (${80 - _jobDescription.text.trim().length} more characters needed)',
                        style: Theme.of(
                          context,
                        ).textTheme.bodySmall?.copyWith(color: colors.warning),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.md),
                    InformationBanner(
                      icon: Icons.auto_awesome,
                      title: account == null
                          ? 'Loading AI credit balance'
                          : '${account.availableCredits} AI credits remaining',
                      message:
                          'This analysis uses ${operation.creditCost} credits. Your master resume remains unchanged.',
                    ),
                    const SizedBox(height: AppSpacing.xl),
                  ],
                ),
              ),
            ),
            if (state.busy) ...[
              const SizedBox(height: AppSpacing.md),
              AppCard(
                child: Column(
                  children: [
                    for (var index = 0; index < _analysisSteps.length; index++)
                      ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(
                          index < state.analysisStage
                              ? Icons.check_circle
                              : index == state.analysisStage
                              ? Icons.radio_button_checked
                              : Icons.radio_button_unchecked,
                          color: index <= state.analysisStage
                              ? colors.primary
                              : colors.disabled,
                        ),
                        title: Text(_analysisSteps[index]),
                      ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.md),
            if (creditState.status == AiCreditStatus.loading && account == null)
              const AppPrimaryButton(
                label: 'Loading AI cost...',
                onPressed: null,
              )
            else
              AiActionButton(
                label: 'Analyze & Match Job',
                creditCost: operation.creditCost,
                availableCredits: availableCredits,
                state: state.busy
                    ? AiActionButtonState.loading
                    : AiActionButtonState.idle,
                onInsufficientCredits: () => showInsufficientCreditsSheet(
                  context: context,
                  operation: operation.displayName,
                  requiredCredits: operation.creditCost,
                  availableCredits: availableCredits,
                  resetDate: account?.resetDate,
                  onViewPlans: () => context.push('/ai-plans'),
                ),
                onPressed: () async {
                  if (state.resume == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please choose a master resume first.'),
                      ),
                    );
                    return;
                  }
                  if (_jobDescription.text.trim().length < 80) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Job description must be at least 80 characters long.',
                        ),
                      ),
                    );
                    return;
                  }
                  final ok = await ref
                      .read(optimizationProvider.notifier)
                      .analyze();
                  if (!context.mounted) return;
                  if (ok) {
                    await ref
                        .read(aiCreditsProvider.notifier)
                        .refreshAfterAiOperation();
                    if (!context.mounted) return;
                    context.push('/resume/optimize/analysis');
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          ref.read(optimizationProvider).error ??
                              'Analysis failed. Try again.',
                        ),
                      ),
                    );
                  }
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _resumeTile(
    BuildContext context,
    ResumeModel? resume,
    AppColors colors,
  ) {
    if (resume == null) {
      return ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Icon(Icons.description_outlined, color: colors.primary),
        title: const Text('Choose a master resume'),
        subtitle: const Text(
          'Select the resume you want to optimize for this JD',
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => _chooseResume(context),
      );
    }
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: colors.primarySoft,
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        child: Icon(Icons.description_outlined, color: colors.primary),
      ),
      title: Text(resume.title),
      subtitle: const Text('Master resume · Original remains unchanged'),
      trailing: TextButton(
        onPressed: () => _chooseResume(context),
        child: const Text('Change'),
      ),
    );
  }

  Future<void> _chooseResume(BuildContext context) async {
    List<ResumeModel> resumes =
        ref.read(resumeListProvider).valueOrNull ?? const <ResumeModel>[];
    if (resumes.isEmpty) {
      try {
        resumes = await ref.read(resumeListProvider.future);
      } catch (_) {}
    }
    if (!context.mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Choose Resume',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: AppSpacing.md),
              if (resumes.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                  child: Text(
                    'No resumes found. Please create a master resume first.',
                  ),
                )
              else
                ...resumes.map((resume) => _resumeOption(sheetContext, resume)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _resumeOption(
    BuildContext sheetContext,
    ResumeModel resume, {
    bool demo = false,
  }) => ListTile(
    leading: const Icon(Icons.description_outlined),
    title: Text(resume.title),
    subtitle: Text(
      demo ? 'Sample resume with projects and skills' : 'Master resume',
    ),
    onTap: () {
      ref.read(optimizationProvider.notifier).selectResume(resume);
      Navigator.pop(sheetContext);
    },
  );

  static const _analysisSteps = [
    'Reading job description',
    'Analyzing requirements & keywords',
    'Finding resume evidence',
    'Matching requirements',
  ];
}
