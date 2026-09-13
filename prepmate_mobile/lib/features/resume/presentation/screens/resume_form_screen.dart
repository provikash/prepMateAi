import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/theme.dart';
import '../../../../core/providers/form_provider.dart';
import '../../../profile/presentation/providers/profile_provider.dart';
import '../../data/models/template_detail_model.dart';
import '../providers/resume_builder_provider.dart';
import '../providers/resume_providers.dart';
import '../widgets/resume_step_indicator.dart';
import '../widgets/schema_form_section.dart';

/// The route keeps its original name so all existing template-selection links
/// remain valid. Its content is now a backend-schema-driven, step-by-step
/// resume builder.
class ResumeFormScreen extends ConsumerStatefulWidget {
  final String? templateId;

  const ResumeFormScreen({super.key, this.templateId});

  @override
  ConsumerState<ResumeFormScreen> createState() => _ResumeFormScreenState();
}

class _ResumeFormScreenState extends ConsumerState<ResumeFormScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _configuredTemplateId;
  bool _profilePrefilled = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(profileProvider.notifier).loadProfile());
  }

  void _prefillProfile() {
    if (_profilePrefilled) return;
    final user = ref.read(profileProvider).user;
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
    final profile = ref.watch(profileProvider);
    final templateAsync = widget.templateId == null
        ? null
        : ref.watch(templateDetailProvider(widget.templateId!));

    if (profile.user != null && !_profilePrefilled) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _prefillProfile());
    }

    if (templateAsync == null) {
      return _noTemplate(context);
    }
    return templateAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, _) => Scaffold(body: _error(context, error.toString())),
      data: (template) {
        if (_configuredTemplateId != template.id) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted || _configuredTemplateId == template.id) return;
            ref.read(resumeBuilderProvider.notifier).configure(template);
            _configuredTemplateId = template.id;
          });
        }
        return _builder(context, template);
      },
    );
  }

  Widget _noTemplate(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Create Resume')),
    body: _error(context, 'Select a resume template before starting the builder.'),
  );

  Widget _error(BuildContext context, String message) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text(message, textAlign: TextAlign.center),
        const SizedBox(height: 16),
        FilledButton(onPressed: () => context.pop(), child: const Text('Go back')),
      ]),
    ),
  );

  Widget _builder(BuildContext context, TemplateDetailModel template) {
    final colors = AppColors.of(context);
    final builder = ref.watch(resumeBuilderProvider);
    final section = builder.currentSection;
    if (section == null) return Scaffold(body: _error(context, 'This template has no editable sections.'));

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (!didPop && await _confirmExit(context) && mounted) context.pop();
      },
      child: Scaffold(
        backgroundColor: colors.screenBackground,
        appBar: AppBar(
          backgroundColor: colors.screenBackground,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () async {
              if (await _confirmExit(context) && mounted) context.pop();
            },
          ),
          title: Text(builder.title),
          actions: [
            Center(child: Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Text('${builder.currentStep + 1}/${builder.totalSteps}'),
            )),
          ],
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Column(children: [
              ResumeStepIndicator(
                currentStep: builder.currentStep,
                totalSteps: builder.totalSteps,
                onStepTapped: (index) => ref.read(resumeBuilderProvider.notifier).goToStep(index),
              ),
              const SizedBox(height: 18),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(section.title, style: Theme.of(context).textTheme.titleLarge),
              ),
              const SizedBox(height: 4),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(_descriptionFor(section), style: TextStyle(color: colors.textSecondary)),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: Form(
                  key: _formKey,
                  child: ListView(children: [
                    SchemaFormSection(
                      key: ValueKey('${section.key}-${builder.currentStep}'),
                      section: section,
                      aiActions: section.aiActions,
                      onAiAction: (action) => _openAiAction(context, action),
                      onAiPressed: section.aiActions.isEmpty
                          ? null
                          : () => _openAiAction(context, section.aiActions.first),
                    ),
                  ]),
                ),
              ),
              if (builder.errorMessage != null) Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(builder.errorMessage!, style: const TextStyle(color: Colors.red)),
              ),
              Row(children: [
                if (builder.currentStep > 0)
                  Expanded(child: OutlinedButton(onPressed: builder.isSaving ? null : () => ref.read(resumeBuilderProvider.notifier).previousStep(), child: const Text('Back'))),
                if (builder.currentStep > 0) const SizedBox(width: 12),
                Expanded(child: FilledButton(
                  onPressed: builder.isSaving ? null : () => _continue(template),
                  child: builder.isSaving
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : Text(builder.currentStep == builder.totalSteps - 1 ? 'Save & Preview' : 'Continue'),
                )),
              ]),
            ]),
          ),
        ),
      ),
    );
  }

  String _descriptionFor(FormSectionModel section) {
    if (section.type == SectionType.repeatable || section.type == SectionType.list) {
      return 'Add as many entries as you need. You can edit or remove them at any time.';
    }
    return 'Complete this section before continuing.';
  }

  Future<void> _continue(TemplateDetailModel template) async {
    if (!(_formKey.currentState?.validate() ?? true)) return;
    final notifier = ref.read(resumeBuilderProvider.notifier);
    final builder = ref.read(resumeBuilderProvider);
    if (builder.currentStep < builder.totalSteps - 1) {
      notifier.nextStep();
      return;
    }

    final form = ref.read(resumeFormProvider);
    final name = form.basics['name']?.toString().trim() ?? '';
    notifier.setSaving(true);
    final created = await ref.read(createResumeProvider.notifier).submit(
      templateId: template.id,
      title: name.isEmpty ? '${template.title} Resume' : "$name's Resume",
      formData: form.data,
    );
    notifier.setSaving(false);
    if (!mounted) return;
    if (created == null) {
      notifier.setError(ref.read(createResumeProvider).error ?? 'Failed to save resume. Your draft is still available.');
      return;
    }
    ref.invalidate(storedResumesProvider);
    context.go('/resume/pdf/${created.id}');
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

  Future<bool> _confirmExit(BuildContext context) async =>
      await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Leave resume builder?'),
          content: const Text('Your current draft will remain in this session, but it has not been saved to the server yet.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Stay')),
            FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Leave')),
          ],
        ),
      ) ?? false;
}
