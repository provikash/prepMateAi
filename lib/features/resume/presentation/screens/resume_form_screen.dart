import 'package:prepmate_mobile/core/widgets/app_scaffold.dart';
import 'package:prepmate_mobile/core/widgets/app_state.dart';
import 'package:prepmate_mobile/core/widgets/app_loading.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/theme.dart';
import '../../../../core/providers/form_provider.dart';
import '../../../../core/drafts/resume_draft_store.dart';
import '../../../profile/presentation/providers/profile_provider.dart';
import '../../../auth/presentation/viewmodel/auth_viewmodel.dart';
import '../../../home/providers/home_providers.dart' as home;
import '../../data/datasources/resume_remote_data_source.dart';
import '../../data/models/template_detail_model.dart';
import '../providers/resume_builder_provider.dart';
import '../providers/resume_providers.dart';
import '../providers/field_enhance_provider.dart';
import '../models/resume_journey.dart';
import '../widgets/resume_step_indicator.dart';
import '../widgets/schema_form_section.dart';
import '../widgets/unsaved_changes_modal.dart';
import '../widgets/add_more_sections_sheet.dart';
import '../widgets/skills_cloud_widget.dart';
import '../widgets/resume_error_banner.dart';

/// The route keeps its original name so all existing template-selection links
/// remain valid. Its content is now a backend-schema-driven, step-by-step
/// resume builder.
class ResumeFormScreen extends ConsumerStatefulWidget {
  final String? templateId;

  const ResumeFormScreen({super.key, this.templateId});

  @override
  ConsumerState<ResumeFormScreen> createState() => _ResumeFormScreenState();
}

class _ResumeFormScreenState extends ConsumerState<ResumeFormScreen>
    with WidgetsBindingObserver {
  final _formKey = GlobalKey<FormState>();
  String? _configuredTemplateId;
  bool _profilePrefilled = false;
  String? _enhancingPath;
  Map<String, String> _backendErrors = const {};
  String? _draftRestoredForTemplate;
  int _experienceTab = 0;
  bool _showHiringTips = true;
  bool _showExpTips = true;
  bool _offlineToastShown = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      ref.read(resumeDraftControllerProvider.notifier).flush();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    ref.read(resumeDraftControllerProvider.notifier).flush();
    super.dispose();
  }

  void _prefillProfile() {
    if (_profilePrefilled) return;
    final user =
        ref.read(profileProvider).user ?? ref.read(authViewModelProvider).user;
    if (user == null) return;
    _profilePrefilled = true;
    ref.read(resumeFormProvider.notifier).prefillFromProfile({
      'full_name': user.fullName,
      'email': user.email,
      'phone_number': user.phoneNumber,
      'location': user.location,
      'title': user.title,
      'bio': user.bio,
      'linkedin': user.linkedin,
      'github': user.github,
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<int>(resumeFormProvider.select((state) => state.revision), (
      previous,
      next,
    ) {
      if (previous != next && _backendErrors.isNotEmpty && mounted) {
        setState(() => _backendErrors = const {});
      }
      final templateId = widget.templateId;
      if (previous != next && templateId != null) {
        final builder = ref.read(resumeBuilderProvider);
        ref
            .read(resumeDraftControllerProvider.notifier)
            .schedule(
              templateId: templateId,
              data: ref.read(resumeFormProvider).data,
              remoteResumeId: builder.savedResumeId,
            );
      }
    });
    final profile = ref.watch(profileProvider);
    final authUser = ref.watch(authViewModelProvider).user;
    final templateAsync = widget.templateId == null
        ? null
        : ref.watch(templateDetailProvider(widget.templateId!));

    if ((profile.user != null || authUser != null) && !_profilePrefilled) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _prefillProfile());
    }

    if (templateAsync == null) {
      return _noTemplate(context);
    }
    return templateAsync.when(
      loading: () => const Scaffold(
        body: AppLoadingState(label: 'Preparing your resume builder'),
      ),
      error: (error, _) => Scaffold(body: _error(context, error.toString())),
      data: (template) {
        if (_configuredTemplateId != template.id) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted || _configuredTemplateId == template.id) return;
            _configureAndRestore(template);
          });
        }
        return _builder(context, template);
      },
    );
  }

  Widget _noTemplate(BuildContext context) => AppScaffold(
    title: 'Create resume',
    body: _error(
      context,
      'Select a resume template before starting the builder.',
    ),
  );

  Widget _error(BuildContext context, String message) => AppErrorState(
    title: 'Resume builder unavailable',
    message: message.replaceFirst('Exception: ', ''),
    actionLabel: 'Go back',
    onAction: () => context.pop(),
  );

  Widget _builder(BuildContext context, TemplateDetailModel template) {
    final colors = AppColors.of(context);
    final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;
    final builder = ref.watch(resumeBuilderProvider);
    final draftState = ref.watch(resumeDraftControllerProvider);
    if (draftState == DraftSyncState.localOnly && !_offlineToastShown) {
      _offlineToastShown = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        Fluttertoast.showToast(
          msg: 'Offline mode: your changes are saved safely on this device.',
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.BOTTOM,
        );
      });
    } else if (draftState != DraftSyncState.localOnly) {
      _offlineToastShown = false;
    }
    final step = builder.currentStepData;
    if (step == null) {
      return Scaffold(
        body: _error(context, 'This template has no editable sections.'),
      );
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (!didPop && await _confirmExit(context) && context.mounted) {
          context.pop();
        }
      },
      child: Scaffold(
        backgroundColor: colors.screenBackground,
        appBar: AppBar(
          backgroundColor: colors.screenBackground,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () async {
              if (await _confirmExit(context) && context.mounted) {
                context.pop();
              }
            },
          ),
          title: Text(builder.title),
          actions: [
            IconButton(
              tooltip: 'Preview PDF',
              icon: const Icon(Icons.picture_as_pdf_outlined),
              onPressed: builder.isSaving
                  ? null
                  : () => _save(template, draft: true, preview: true),
            ),
            Center(
              child: Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Text(
                  'Step ${builder.currentStep + 1} of ${builder.totalSteps}',
                ),
              ),
            ),
          ],
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Column(
              children: [
                if (!keyboardOpen)
                  ResumeStepIndicator(
                    currentStep: builder.currentStep,
                    totalSteps: builder.totalSteps,
                    sectionTitles: builder.steps
                        .map((step) => step.title)
                        .toList(),
                    onStepTapped: (index) => ref
                        .read(resumeBuilderProvider.notifier)
                        .goToStep(index),
                    completedSteps: _completedJourneySteps(builder),
                    completionPercent: ResumeCompletion.calculate(
                      ref.watch(resumeFormProvider).data,
                    ).percent,
                  ),
                if (!keyboardOpen) const SizedBox(height: 12),
                if (!keyboardOpen)
                  _buildHorizontalSectionChips(context, builder, colors),
                if (!keyboardOpen) const SizedBox(height: 12),
                if (builder.errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: SyncFailureAlert(
                      subtitle: builder.errorMessage!,
                      onRetry: () => _continue(template),
                    ),
                  ),
                Expanded(
                  child: Form(
                    key: _formKey,
                    child: ListView(
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      padding: const EdgeInsets.only(bottom: 12),
                      children: [
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: colors.primarySoft,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.lightbulb_outline,
                                color: colors.primary,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Fill in what you know. Optional fields can be skipped, and you can preview your resume at any time.',
                                  style: TextStyle(
                                    color: colors.textPrimary,
                                    height: 1.35,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          step.title,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          step.description,
                          style: TextStyle(color: colors.textSecondary),
                        ),
                        const SizedBox(height: 16),
                        _stepContent(context, template, step),
                      ],
                    ),
                  ),
                ),
                if (builder.errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      builder.errorMessage!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                if (step.canSkip &&
                    builder.currentStep < builder.totalSteps - 1)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton(
                      onPressed: builder.isSaving
                          ? null
                          : () => ref
                                .read(resumeBuilderProvider.notifier)
                                .nextStep(),
                      child: const Text('Skip for now'),
                    ),
                  ),
                Row(
                  children: [
                    if (builder.currentStep > 0)
                      Expanded(
                        child: OutlinedButton(
                          onPressed: builder.isSaving
                              ? null
                              : () => ref
                                    .read(resumeBuilderProvider.notifier)
                                    .previousStep(),
                          child: const Text('Back'),
                        ),
                      ),
                    if (builder.currentStep > 0) const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: builder.isSaving
                            ? null
                            : () => _saveAndExit(template),
                        child: const Text('Save and exit'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FilledButton(
                        onPressed: builder.isSaving
                            ? null
                            : () => _continue(template),
                        child: builder.isSaving
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: AppLoading(strokeWidth: 2),
                              )
                            : Text(
                                builder.currentStep == builder.totalSteps - 1
                                    ? 'Save resume'
                                    : 'Next',
                              ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  _saveStatusLabel(
                    builder.saveStatus,
                    ref.watch(resumeDraftControllerProvider),
                  ),
                  style: TextStyle(color: colors.textSecondary, fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHorizontalSectionChips(
    BuildContext context,
    ResumeBuilderState builder,
    AppColors colors,
  ) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (var i = 0; i < builder.steps.length; i++) ...[
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                selected: builder.currentStep == i,
                label: Text(builder.steps[i].title),
                onSelected: (_) =>
                    ref.read(resumeBuilderProvider.notifier).goToStep(i),
                backgroundColor: colors.surface,
                selectedColor: colors.primarySoft,
                labelStyle: TextStyle(
                  color: builder.currentStep == i
                      ? colors.primary
                      : colors.textPrimary,
                  fontWeight: builder.currentStep == i
                      ? FontWeight.w600
                      : FontWeight.normal,
                  fontSize: 13,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(
                    color: builder.currentStep == i
                        ? colors.primary
                        : colors.border,
                  ),
                ),
                showCheckmark: false,
              ),
            ),
          ],
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: ActionChip(
              avatar: Icon(Icons.add, size: 16, color: colors.primary),
              label: Text(
                'Add Section',
                style: TextStyle(
                  color: colors.primary,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
              backgroundColor: colors.primarySoft.withValues(alpha: 0.5),
              side: BorderSide(color: colors.primary.withValues(alpha: 0.3)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              onPressed: () => AddMoreSectionsSheet.show(
                context,
                onSectionSelected: (key) {
                  ref
                      .read(resumeFormProvider.notifier)
                      .ensureSectionInitialized(key);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Section "$key" added to your resume.'),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _stepContent(
    BuildContext context,
    TemplateDetailModel template,
    ResumeJourneyStep step,
  ) {
    final colors = AppColors.of(context);
    switch (step.key) {
      case ResumeJourneyStepKey.about:
        final section = step.sections.first;
        const essentials = {'name', 'label', 'email', 'phone', 'location'};
        final primary = section.copyWith(
          fields: section.fields
              .where((field) => essentials.contains(field.key))
              .toList(),
        );
        final additional = section.copyWith(
          title: 'More contact details',
          fields: section.fields
              .where((field) => !essentials.contains(field.key))
              .toList(),
        );
        final basics = ref.watch(resumeFormProvider).basics;
        final candidateName = basics['name']?.toString() ?? '';
        final initialLetter = candidateName.trim().isNotEmpty
            ? candidateName.trim().substring(0, 1).toUpperCase()
            : 'U';

        return Column(
          children: [
            // Screen 15: Hiring tip banner
            if (_showHiringTips)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFE9EFFF),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF2457D6).withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.tips_and_updates_outlined,
                      color: Color(0xFF2457D6),
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Hiring Tip for Personal Details',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                              color: Color(0xFF172033),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Recruiters spend 6–7 seconds scanning basics. Ensure your title, professional email, and phone number are active.',
                            style: TextStyle(
                              fontSize: 12,
                              color: colors.textSecondary,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                    InkWell(
                      onTap: () => setState(() => _showHiringTips = false),
                      child: const Icon(
                        Icons.close,
                        size: 16,
                        color: Color(0xFF2457D6),
                      ),
                    ),
                  ],
                ),
              ),
            // Screen 15: Profile context & avatar summary card
            Container(
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: colors.border),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: colors.primarySoft,
                    child: Text(
                      initialLetter,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: colors.primary,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          candidateName.trim().isNotEmpty
                              ? candidateName
                              : 'Personal Profile',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          'Verified Profile Details · Synced with template',
                          style: TextStyle(
                            color: colors.textSecondary,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.verified, color: colors.secondary, size: 18),
                ],
              ),
            ),
            _schema(context, primary),
            if (additional.fields.isNotEmpty)
              Card(
                clipBehavior: Clip.antiAlias,
                child: ExpansionTile(
                  title: const Text('More contact details'),
                  subtitle: const Text(
                    'Website and professional profiles · Optional',
                  ),
                  childrenPadding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                  children: [_schema(context, additional)],
                ),
              ),
          ],
        );
      case ResumeJourneyStepKey.experienceProjects:
        final available = step.sections;
        final safeTab = _experienceTab.clamp(0, available.length - 1);
        return Column(
          children: [
            // Screen 16: ATS Advice Banner
            if (_showExpTips)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFE1F4F1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF087E78).withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.fact_check_outlined,
                      color: Color(0xFF087E78),
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'ATS Work Experience Guidelines',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                              color: Color(0xFF172033),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Start bullets with strong action verbs (e.g. "Architected", "Engineered") and quantify results with numbers, metrics, or team sizes.',
                            style: TextStyle(
                              fontSize: 12,
                              color: colors.textSecondary,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                    InkWell(
                      onTap: () => setState(() => _showExpTips = false),
                      child: const Icon(
                        Icons.close,
                        size: 16,
                        color: Color(0xFF087E78),
                      ),
                    ),
                  ],
                ),
              ),
            // Screen 16: Fresher guidance card
            Container(
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: colors.border),
              ),
              child: Row(
                children: [
                  Icon(Icons.school_outlined, color: colors.primary, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'No formal work experience? Include internships, freelance projects, hackathons, or university club roles.',
                      style: TextStyle(
                        fontSize: 12,
                        color: colors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (available.length > 1)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: SegmentedButton<int>(
                  segments: [
                    for (var index = 0; index < available.length; index++)
                      ButtonSegment(
                        value: index,
                        label: Text(available[index].title),
                        icon: Icon(
                          available[index].key == 'work'
                              ? Icons.work_outline
                              : Icons.folder_open_outlined,
                        ),
                      ),
                  ],
                  selected: {safeTab},
                  onSelectionChanged: (selection) {
                    setState(() => _experienceTab = selection.first);
                  },
                ),
              ),
            _schema(context, available[safeTab]),
          ],
        );
      case ResumeJourneyStepKey.educationSkills:
        return Column(
          children: [
            for (final section in step.sections) ...[
              if (section.key == 'skills')
                const Padding(
                  padding: EdgeInsets.only(bottom: 16),
                  child: SkillsCloudWidget(),
                )
              else ...[
                _schema(context, section),
                const SizedBox(height: 12),
              ],
            ],
            if (!step.sections.any((s) => s.key == 'skills'))
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: SkillsCloudWidget(),
              ),
          ],
        );
      case ResumeJourneyStepKey.summary:
        final form = ref.watch(resumeFormProvider);
        final summary = form.summary;
        final canDraft =
            (form.basics['label']?.toString().trim().isNotEmpty ?? false) &&
            form.skills.isNotEmpty;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _schema(context, step.sections.first),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: canDraft && _enhancingPath == null
                    ? _draftSummaryFromDetails
                    : null,
                icon: _enhancingPath == 'basics.summary.draft'
                    ? const SizedBox.square(
                        dimension: 16,
                        child: AppLoading(strokeWidth: 2),
                      )
                    : const Icon(Icons.auto_awesome_outlined),
                label: const Text('Draft from my details'),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              child: Text(
                '${summary.length} characters · Aim for 80–300 characters using only facts you supplied.',
                style: TextStyle(color: AppColors.of(context).textSecondary),
              ),
            ),
          ],
        );
      case ResumeJourneyStepKey.review:
        return _reviewStep(context, template);
    }
  }

  Widget _schema(
    BuildContext context,
    FormSectionModel section,
  ) => SchemaFormSection(
    key: ValueKey(
      '${section.key}-${section.fields.map((field) => field.key).join(',')}',
    ),
    section: section,
    aiActions: section.aiActions,
    onAiAction: (action) => _openAiAction(context, action),
    onAiPressed: section.aiActions.isEmpty
        ? null
        : () => _openAiAction(context, section.aiActions.first),
    onEnhance: _enhanceField,
    enhancingPath: _enhancingPath,
    backendErrors: _backendErrors,
  );

  Widget _reviewStep(BuildContext context, TemplateDetailModel template) {
    final data = ref.watch(resumeFormProvider).data;
    final completion = ResumeCompletion.calculate(data);
    final colors = AppColors.of(context);
    final optional = ref.watch(resumeBuilderProvider).journey.optionalSections;
    final populatedOptional = optional
        .where((section) => _hasValue(data[section.key]))
        .toList();
    const canonicalKeys = {
      'basics',
      'work',
      'education',
      'skills',
      'projects',
      'certificates',
      'languages',
      'awards',
      'volunteer',
      'publications',
      'interests',
      'references',
    };
    final availableKeys = template.sections
        .map((section) => section.key)
        .toSet();
    final hiddenPopulated = canonicalKeys
        .where((key) => !availableKeys.contains(key) && _hasValue(data[key]))
        .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                if (template.thumbnailUrl != null &&
                    template.thumbnailUrl!.isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(
                      template.thumbnailUrl!,
                      width: 64,
                      height: 84,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const SizedBox.square(
                        dimension: 64,
                        child: Icon(Icons.description_outlined),
                      ),
                    ),
                  )
                else
                  const SizedBox.square(
                    dimension: 64,
                    child: Icon(Icons.description_outlined, size: 36),
                  ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        template.title,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text('Template version ${template.version}'),
                      const SizedBox(height: 8),
                      Text('${completion.percent}% complete'),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () => context.push('/template'),
                  child: const Text('Change'),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        if (completion.blockingIssues.isNotEmpty)
          Card(
            color: colors.errorSoft,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Required before export',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  for (final issue in completion.blockingIssues)
                    Text('• $issue'),
                ],
              ),
            ),
          ),
        if (completion.recommendations.isNotEmpty) ...[
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Ways to strengthen it',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  for (final suggestion in completion.recommendations.take(4))
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text('• $suggestion'),
                    ),
                ],
              ),
            ),
          ),
        ],
        if (hiddenPopulated.isNotEmpty) ...[
          const SizedBox(height: 12),
          Card(
            color: colors.warningSoft,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'This template does not display ${hiddenPopulated.join(', ')}. '
                'Your content is still preserved and will reappear in a supported template.',
              ),
            ),
          ),
        ],
        const SizedBox(height: 12),
        if (populatedOptional.isNotEmpty) ...[
          Text(
            'Additional sections',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 6),
          for (final section in populatedOptional)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(_optionalIcon(section.key)),
              title: Text(section.title),
              subtitle: Text('${_itemCount(data[section.key])} added'),
              trailing: const Icon(Icons.edit_outlined),
              onTap: () => _showOptionalSections(
                context,
                initialSectionKey: section.key,
              ),
            ),
          const SizedBox(height: 6),
        ],
        OutlinedButton.icon(
          onPressed: () => _showOptionalSections(context),
          icon: const Icon(Icons.add_circle_outline),
          label: Text(
            populatedOptional.isEmpty
                ? 'Add another section'
                : 'Optional sections (${populatedOptional.length})',
          ),
        ),
        const SizedBox(height: 8),
        FilledButton.icon(
          onPressed:
              completion.blockingIssues.isEmpty &&
                  !ref.watch(resumeBuilderProvider).isSaving
              ? () => _save(template, draft: false, preview: true)
              : null,
          icon: const Icon(Icons.picture_as_pdf_outlined),
          label: const Text('Save latest and view PDF'),
        ),
      ],
    );
  }

  Future<void> _showOptionalSections(
    BuildContext context, {
    String? initialSectionKey,
  }) async {
    String? selectedKey = initialSectionKey;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) => Consumer(
          builder: (context, ref, _) {
            final sections = ref
                .watch(resumeBuilderProvider)
                .journey
                .optionalSections;
            final data = ref.watch(resumeFormProvider).data;
            FormSectionModel? selected;
            for (final section in sections) {
              if (section.key == selectedKey) {
                selected = section;
                break;
              }
            }
            return DraggableScrollableSheet(
              expand: false,
              initialChildSize: .82,
              minChildSize: .5,
              maxChildSize: .95,
              builder: (_, controller) => ListView(
                controller: controller,
                padding: const EdgeInsets.all(16),
                children: [
                  Text(
                    'Add another section',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Optional sections never become extra required steps.',
                  ),
                  const SizedBox(height: 16),
                  for (final section in sections)
                    Card(
                      child: ListTile(
                        minVerticalPadding: 12,
                        leading: Icon(_optionalIcon(section.key)),
                        title: Text(section.title),
                        subtitle: Text(
                          '${_itemCount(data[section.key])} added · ${_optionalDescription(section.key)}',
                        ),
                        trailing: TextButton(
                          onPressed: () => setSheetState(() {
                            selectedKey = selectedKey == section.key
                                ? null
                                : section.key;
                          }),
                          child: Text(
                            selectedKey == section.key ? 'Close' : 'Add / edit',
                          ),
                        ),
                      ),
                    ),
                  if (selected != null) ...[
                    const SizedBox(height: 12),
                    _schema(context, selected),
                    if (_hasValue(data[selected.key]))
                      TextButton.icon(
                        onPressed: () async {
                          final selectedSection = selected!;
                          final remove = await showDialog<bool>(
                            context: context,
                            builder: (dialogContext) => AlertDialog(
                              title: Text('Remove ${selectedSection.title}?'),
                              content: const Text(
                                'This removes the entries from this resume.',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(dialogContext, false),
                                  child: const Text('Cancel'),
                                ),
                                FilledButton(
                                  onPressed: () =>
                                      Navigator.pop(dialogContext, true),
                                  child: const Text('Remove'),
                                ),
                              ],
                            ),
                          );
                          if (remove == true) {
                            ref
                                .read(resumeFormProvider.notifier)
                                .clearSection(selectedSection.key);
                          }
                        },
                        icon: const Icon(Icons.delete_outline),
                        label: const Text('Remove section content'),
                      ),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _saveAndExit(TemplateDetailModel template) async {
    final saved = await _save(template, draft: true);
    if (saved && mounted) context.pop();
  }

  Set<int> _completedJourneySteps(ResumeBuilderState builder) {
    final complete = ResumeCompletion.calculate(
      ref.watch(resumeFormProvider).data,
    );
    return {
      for (var index = 0; index < builder.steps.length; index++)
        if (complete.completedSteps.contains(builder.steps[index].key)) index,
    };
  }

  int _itemCount(dynamic value) => value is List
      ? value.where((item) => _hasValue(item)).length
      : _hasValue(value)
      ? 1
      : 0;

  IconData _optionalIcon(String key) => switch (key) {
    'certificates' => Icons.workspace_premium_outlined,
    'languages' => Icons.language_outlined,
    'awards' => Icons.emoji_events_outlined,
    'volunteer' => Icons.volunteer_activism_outlined,
    'publications' => Icons.menu_book_outlined,
    'interests' => Icons.interests_outlined,
    'references' => Icons.people_outline,
    _ => Icons.add_box_outlined,
  };

  String _optionalDescription(String key) => switch (key) {
    'certificates' => 'Credentials and professional training',
    'languages' => 'Languages and fluency',
    'awards' => 'Recognition and achievements',
    'volunteer' => 'Community and unpaid experience',
    'publications' => 'Articles, papers, and published work',
    'interests' => 'Relevant interests outside work',
    'references' => 'Professional references',
    _ => 'Additional resume information',
  };

  Future<void> _continue(TemplateDetailModel template) async {
    if (!(_formKey.currentState?.validate() ?? true)) return;
    final notifier = ref.read(resumeBuilderProvider.notifier);
    final builder = ref.read(resumeBuilderProvider);
    if (builder.currentStep < builder.totalSteps - 1) {
      notifier.nextStep();
      return;
    }

    final completion = ResumeCompletion.calculate(
      ref.read(resumeFormProvider).data,
    );
    if (completion.blockingIssues.isNotEmpty) {
      final aboutIndex = builder.journey.steps.indexWhere(
        (step) => step.key == ResumeJourneyStepKey.about,
      );
      if (aboutIndex >= 0) notifier.goToStep(aboutIndex);
      notifier.setError(completion.blockingIssues.first);
      return;
    }
    await _save(template, draft: false, preview: true);
  }

  Future<bool> _save(
    TemplateDetailModel template, {
    required bool draft,
    bool preview = false,
  }) async {
    final notifier = ref.read(resumeBuilderProvider.notifier);
    final builder = ref.read(resumeBuilderProvider);
    if (builder.isSaving) return false;
    ref.read(resumeFormProvider.notifier).sanitizeForSubmission();
    final form = ref.read(resumeFormProvider);
    final submittedRevision = form.revision;
    final name = form.basics['name']?.toString().trim() ?? '';
    notifier.setSaving(true);
    try {
      final saved = await ref
          .read(resumeRepositoryProvider)
          .saveResume(
            resumeId: builder.savedResumeId,
            templateId: template.id,
            title: name.isEmpty ? '${template.title} Resume' : "$name's Resume",
            data: form.data,
            draft: draft,
          );
      if (saved.queued) {
        notifier.setQueued(saved.id);
      } else if (ref.read(resumeFormProvider).revision == submittedRevision) {
        notifier.setSaved(saved.id, draft: draft);
      } else {
        notifier.setSavedWithNewerChanges(saved.id);
      }
      if (saved.queued) {
        await ref.read(resumeDraftControllerProvider.notifier).flush();
      } else {
        await ref
            .read(resumeDraftControllerProvider.notifier)
            .markSynced(templateId: template.id, remoteResumeId: saved.id);
      }
      ref.invalidate(storedResumesProvider);
      ref.invalidate(home.resumeListProvider);
      ref.invalidate(home.dashboardProvider);
      if (preview && mounted) {
        if (saved.queued) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Saved on this device. Opening preview.'),
            ),
          );
        }
        context.go('/resume/pdf/${saved.id}');
      }
      return true;
    } on ResumeSaveException catch (error) {
      if (mounted) setState(() => _backendErrors = error.fieldErrors);
      notifier.setError(error.message);
      _navigateToBackendError(template, error.fieldErrors.keys.join(' '));
      return false;
    } catch (_) {
      notifier.setError('Could not save the resume. Please try again.');
      return false;
    }
  }

  Future<void> _configureAndRestore(TemplateDetailModel template) async {
    ref.read(resumeBuilderProvider.notifier).configure(template);
    _configuredTemplateId = template.id;
    if (_draftRestoredForTemplate == template.id) return;
    _draftRestoredForTemplate = template.id;
    final draft = await ref
        .read(resumeDraftControllerProvider.notifier)
        .restore(templateId: template.id);
    if (!mounted || draft == null) return;
    ref.read(resumeFormProvider.notifier).restoreData(draft.data);
  }

  String _saveStatusLabel(String remoteStatus, DraftSyncState localStatus) {
    if (remoteStatus == 'Saving…' || remoteStatus == 'Savingâ€¦') {
      return 'Syncing';
    }
    if (remoteStatus == 'Saved' || remoteStatus == 'Draft saved') {
      return 'Saved';
    }
    return switch (localStatus) {
      DraftSyncState.localOnly => 'Saved locally',
      DraftSyncState.syncing => 'Syncing',
      DraftSyncState.synced => 'Saved',
      DraftSyncState.failed => 'Local save failed',
      DraftSyncState.conflict => 'Sync conflict — review before saving',
    };
  }

  bool _hasValue(dynamic value) {
    if (value is String) return value.trim().isNotEmpty;
    if (value is List) return value.isNotEmpty;
    if (value is Map) return value.values.any(_hasValue);
    return value != null;
  }

  void _navigateToBackendError(TemplateDetailModel template, String message) {
    final builder = ref.read(resumeBuilderProvider);
    for (final section in template.sections) {
      if (message.contains(section.key)) {
        ref
            .read(resumeBuilderProvider.notifier)
            .goToStep(builder.journey.stepIndexForSection(section.key));
        return;
      }
    }
  }

  Future<void> _enhanceField(FieldEnhanceTarget target) async {
    if (_enhancingPath != null) return;
    setState(() => _enhancingPath = target.fieldPath);
    try {
      while (mounted) {
        final suggestion = await ref
            .read(fieldEnhanceAdapterProvider)
            .enhance(
              fieldPath: target.fieldPath,
              schemaActions: target.schemaActions,
              value: target.originalValue,
              context: target.context,
            );
        if (!mounted) return;
        final stale = !_valuesEqual(target.latestValue(), target.originalValue);
        final accepted = await _reviewSuggestion(
          target,
          suggestion,
          stale: stale,
        );
        if (identical(accepted, _retryEnhancement)) continue;
        if (accepted == null || !mounted) return;
        target.apply(accepted);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('AI suggestion applied.'),
            action: SnackBarAction(
              label: 'Undo',
              onPressed: () => target.apply(target.originalValue),
            ),
          ),
        );
        return;
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not enhance field: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _enhancingPath = null);
    }
  }

  Future<void> _draftSummaryFromDetails() async {
    if (_enhancingPath != null) return;
    const path = 'basics.summary.draft';
    final original = ref.read(resumeFormProvider).summary;
    setState(() => _enhancingPath = path);
    try {
      final target = FieldEnhanceTarget(
        fieldPath: 'basics.summary',
        originalValue: original,
        latestValue: () => ref.read(resumeFormProvider).summary,
        apply: (value) => ref
            .read(resumeFormProvider.notifier)
            .updateSummary(value.toString()),
        schemaActions: const ['generate_summary'],
      );
      while (mounted) {
        final suggestion = await ref
            .read(fieldEnhanceAdapterProvider)
            .draftSummaryFromDetails(ref.read(resumeFormProvider).data);
        if (!mounted) return;
        final accepted = await _reviewSuggestion(
          target,
          suggestion,
          stale: ref.read(resumeFormProvider).summary != original,
        );
        if (identical(accepted, _retryEnhancement)) continue;
        if (accepted == null || !mounted) return;
        target.apply(accepted);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('AI summary applied.'),
            action: SnackBarAction(
              label: 'Undo',
              onPressed: () => target.apply(original),
            ),
          ),
        );
        return;
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.toString())));
      }
    } finally {
      if (mounted) setState(() => _enhancingPath = null);
    }
  }

  Future<dynamic> _reviewSuggestion(
    FieldEnhanceTarget target,
    dynamic suggestion, {
    required bool stale,
  }) async {
    final isList = suggestion is List;
    final controller = TextEditingController(
      text: isList ? suggestion.join('\n') : suggestion.toString(),
    );
    final result = await showDialog<dynamic>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Review AI suggestion'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (stale)
                const Text(
                  'You edited this field while AI was working, so this result cannot replace your newer text. Cancel and run it again if needed.',
                  style: TextStyle(color: Colors.orange),
                ),
              const SizedBox(height: 8),
              const Text(
                'Original',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                target.originalValue is List
                    ? target.originalValue.join('\n')
                    : target.originalValue.toString(),
              ),
              const SizedBox(height: 12),
              const Text(
                'Suggested (editable)',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              TextField(controller: controller, maxLines: 8),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, _retryEnhancement),
            child: const Text('Try Again'),
          ),
          FilledButton(
            onPressed: stale
                ? null
                : () {
                    final value = isList
                        ? controller.text
                              .split(RegExp(r'\r?\n'))
                              .map((item) => item.trim())
                              .where((item) => item.isNotEmpty)
                              .toList()
                        : controller.text.trim();
                    Navigator.pop(dialogContext, value);
                  },
            child: const Text('Apply'),
          ),
        ],
      ),
    );
    controller.dispose();
    return result;
  }

  bool _valuesEqual(dynamic left, dynamic right) {
    if (left is List && right is List) {
      if (left.length != right.length) return false;
      for (var index = 0; index < left.length; index++) {
        if (!_valuesEqual(left[index], right[index])) return false;
      }
      return true;
    }
    if (left is Map && right is Map) {
      if (left.length != right.length) return false;
      return left.keys.every(
        (key) => right.containsKey(key) && _valuesEqual(left[key], right[key]),
      );
    }
    return left == right;
  }

  void _openAiAction(BuildContext context, String action) {
    final route = switch (action.toLowerCase()) {
      'generate_summary' => '/resume/ai-input/summary',
      'improve_section' => '/resume/ai-input/improve',
      'suggest_skills' => '/resume/ai-input/skills',
      'generate_bullets' => '/resume/ai-input/bullets',
      _ => '/resume/ai-assistant',
    };
    context.push(route);
  }

  Future<bool> _confirmExit(BuildContext context) async {
    final form = ref.read(resumeFormProvider);
    final hasEdits = form.revision > 0;
    if (!hasEdits) return true;

    final builder = ref.read(resumeBuilderProvider);
    final currentSectionName =
        builder.steps.isNotEmpty && builder.currentStep < builder.steps.length
        ? builder.steps[builder.currentStep].title
        : 'Personal details';

    final shouldLeave = await UnsavedChangesModal.show(
      context,
      sectionName: currentSectionName,
      onSaveDraftAndLeave: () async {
        await ref.read(resumeDraftControllerProvider.notifier).flush();
        if (context.mounted) {
          Navigator.of(context).pop(true);
        }
      },
      onDiscardChanges: () {
        Navigator.of(context).pop(true);
      },
      onKeepEditing: () {
        Navigator.of(context).pop(false);
      },
    );

    return shouldLeave ?? false;
  }
}

const _retryEnhancement = _RetryEnhancement();

class _RetryEnhancement {
  const _RetryEnhancement();
}
