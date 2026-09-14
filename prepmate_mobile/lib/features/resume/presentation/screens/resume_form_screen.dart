import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/theme.dart';
import '../../../../core/providers/form_provider.dart';
import '../../../profile/presentation/providers/profile_provider.dart';
import '../../data/datasources/resume_remote_data_source.dart';
import '../../data/models/template_detail_model.dart';
import '../providers/resume_builder_provider.dart';
import '../providers/resume_providers.dart';
import '../providers/field_enhance_provider.dart';
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
  String? _enhancingPath;
  Map<String, String> _backendErrors = const {};

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
    ref.listen<int>(resumeFormProvider.select((state) => state.revision), (
      previous,
      next,
    ) {
      if (previous != next && _backendErrors.isNotEmpty && mounted) {
        setState(() => _backendErrors = const {});
      }
    });
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
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
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
    body: _error(
      context,
      'Select a resume template before starting the builder.',
    ),
  );

  Widget _error(BuildContext context, String message) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () => context.pop(),
            child: const Text('Go back'),
          ),
        ],
      ),
    ),
  );

  Widget _builder(BuildContext context, TemplateDetailModel template) {
    final colors = AppColors.of(context);
    final builder = ref.watch(resumeBuilderProvider);
    final section = builder.currentSection;
    if (section == null) {
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
            Center(
              child: Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Text('${builder.currentStep + 1}/${builder.totalSteps}'),
              ),
            ),
          ],
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Column(
              children: [
                ResumeStepIndicator(
                  currentStep: builder.currentStep,
                  totalSteps: builder.totalSteps,
                  sectionTitles: builder.steps
                      .map((step) => step.title)
                      .toList(),
                  onStepTapped: (index) =>
                      ref.read(resumeBuilderProvider.notifier).goToStep(index),
                  completedSteps: _completedSteps(template),
                ),
                const SizedBox(height: 18),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    section.title,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                const SizedBox(height: 4),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    _descriptionFor(section),
                    style: TextStyle(color: colors.textSecondary),
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: Form(
                    key: _formKey,
                    child: ListView(
                      children: [
                        SchemaFormSection(
                          key: ValueKey(
                            '${section.key}-${builder.currentStep}',
                          ),
                          section: section,
                          aiActions: section.aiActions,
                          onAiAction: (action) =>
                              _openAiAction(context, action),
                          onAiPressed: section.aiActions.isEmpty
                              ? null
                              : () => _openAiAction(
                                  context,
                                  section.aiActions.first,
                                ),
                          onEnhance: _enhanceField,
                          enhancingPath: _enhancingPath,
                          backendErrors: _backendErrors,
                        ),
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
                            : () => _save(template, draft: true),
                        child: const Text('Save Draft'),
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
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                builder.currentStep == builder.totalSteps - 1
                                    ? 'Preview'
                                    : 'Next',
                              ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  builder.saveStatus,
                  style: TextStyle(color: colors.textSecondary, fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _descriptionFor(FormSectionModel section) {
    if (section.type == SectionType.repeatable ||
        section.type == SectionType.list) {
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

    final invalidStep = _firstInvalidStep(template);
    if (invalidStep != null) {
      notifier.goToStep(invalidStep);
      notifier.setError(
        'Complete the required fields in ${template.sections[invalidStep].title}.',
      );
      return;
    }
    await _save(template, draft: false, preview: true);
  }

  Future<void> _save(
    TemplateDetailModel template, {
    required bool draft,
    bool preview = false,
  }) async {
    final notifier = ref.read(resumeBuilderProvider.notifier);
    final builder = ref.read(resumeBuilderProvider);
    if (builder.isSaving) return;
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
      if (ref.read(resumeFormProvider).revision == submittedRevision) {
        notifier.setSaved(saved.id, draft: draft);
      } else {
        notifier.setSavedWithNewerChanges(saved.id);
      }
      ref.invalidate(storedResumesProvider);
      if (preview && mounted) context.go('/resume/pdf/${saved.id}');
    } on ResumeSaveException catch (error) {
      if (mounted) setState(() => _backendErrors = error.fieldErrors);
      notifier.setError(error.message);
      _navigateToBackendError(template, error.fieldErrors.keys.join(' '));
    } catch (_) {
      notifier.setError('Could not save the resume. Please try again.');
    }
  }

  Set<int> _completedSteps(TemplateDetailModel template) {
    final data = ref.watch(resumeFormProvider).data;
    final completed = <int>{};
    for (var index = 0; index < template.sections.length; index++) {
      if (_sectionIsComplete(template.sections[index], data)) {
        completed.add(index);
      }
    }
    return completed;
  }

  bool _sectionIsComplete(FormSectionModel section, Map<String, dynamic> data) {
    final required = <String>{};
    for (final field in section.fields) {
      if (field.isListObject) {
        required.addAll(
          field.objectFields
              .where((item) => item.required)
              .map((item) => item.key),
        );
      } else if (field.required) {
        required.add(field.key);
      }
    }
    if (required.isEmpty) {
      final value = data[section.key];
      return value is Map
          ? value.values.any(_hasValue)
          : value is List && value.any(_hasValue);
    }
    if (section.type == SectionType.single) {
      final values = data[section.key] as Map? ?? const {};
      return required.every((key) => _hasValue(values[key]));
    }
    final items = data[section.key] as List? ?? const [];
    return items.isNotEmpty &&
        items.whereType<Map>().every(
          (item) => required.every((key) => _hasValue(item[key])),
        );
  }

  bool _hasValue(dynamic value) {
    if (value is String) return value.trim().isNotEmpty;
    if (value is List) return value.isNotEmpty;
    if (value is Map) return value.values.any(_hasValue);
    return value != null;
  }

  int? _firstInvalidStep(TemplateDetailModel template) {
    final data = ref.read(resumeFormProvider).data;
    for (var index = 0; index < template.sections.length; index++) {
      final section = template.sections[index];
      final fields = section.fields.expand(
        (field) => field.isListObject
            ? field.objectFields.map((item) => item.key)
            : [field.key],
      );
      final required = section.fields.expand((field) {
        if (field.isListObject) {
          return field.objectFields
              .where((item) => item.required)
              .map((item) => item.key);
        }
        return field.required ? [field.key] : const <String>[];
      }).toSet();
      if (required.isEmpty) continue;
      if (section.type == SectionType.single) {
        final values = data[section.key] as Map? ?? const {};
        if (required.any(
          (key) => (values[key]?.toString().trim() ?? '').isEmpty,
        )) {
          return index;
        }
      } else {
        final items = data[section.key] as List? ?? const [];
        for (final raw in items.whereType<Map>()) {
          final hasContent = fields.any((key) {
            final value = raw[key];
            return value is List
                ? value.isNotEmpty
                : (value?.toString().trim() ?? '').isNotEmpty;
          });
          if (hasContent &&
              required.any((key) {
                final value = raw[key];
                return value is List
                    ? value.isEmpty
                    : (value?.toString().trim() ?? '').isEmpty;
              })) {
            return index;
          }
        }
      }
    }
    return null;
  }

  void _navigateToBackendError(TemplateDetailModel template, String message) {
    for (var index = 0; index < template.sections.length; index++) {
      if (message.contains(template.sections[index].key)) {
        ref.read(resumeBuilderProvider.notifier).goToStep(index);
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
                  'You edited this field while AI was working. Review carefully before applying.',
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
            onPressed: () {
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

  Future<bool> _confirmExit(BuildContext context) async =>
      await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Leave resume builder?'),
          content: const Text(
            'Your current draft will remain in this session, but it has not been saved to the server yet.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Stay'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Leave'),
            ),
          ],
        ),
      ) ??
      false;
}

const _retryEnhancement = _RetryEnhancement();

class _RetryEnhancement {
  const _RetryEnhancement();
}
