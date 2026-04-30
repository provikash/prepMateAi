import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/theme.dart';
import '../../data/models/template_detail_model.dart';
import '../providers/resume_providers.dart';
import '../../../../core/providers/form_provider.dart';
import '../widgets/resume_form_sections.dart';
import '../widgets/schema_form_section.dart';
import '../widgets/resume_widgets.dart';

class ResumeFormScreen extends ConsumerStatefulWidget {
  final String? templateId;

  const ResumeFormScreen({super.key, this.templateId});

  @override
  ConsumerState<ResumeFormScreen> createState() => _ResumeFormScreenState();
}

class _ResumeFormScreenState extends ConsumerState<ResumeFormScreen> {
  String? _appliedTemplateId;

  @override
  Widget build(BuildContext context) {
    final templateAsync = widget.templateId == null
        ? null
        : ref.watch(templateDetailProvider(widget.templateId!));
    final colors = AppColors.of(context);

    final template = templateAsync?.valueOrNull;
    if (template != null && _appliedTemplateId != template.id) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _applyTemplateSchema(template);
      });
    }

    return Scaffold(
      backgroundColor: colors.screenBackground,
      appBar: AppBar(
        backgroundColor: colors.screenBackground,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: Text(
          template?.title ?? 'My Resume',
          style: TextStyle(
            color: colors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: templateAsync == null
          ? _buildContent(context, template: null)
          : templateAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => _buildError(error.toString()),
              data: (template) => _buildContent(context, template: template),
            ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.all(16),
        child: AIButton(
          text: 'AI Assistant',
          onPressed: () => context.push('/resume/ai-assistant'),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, {TemplateDetailModel? template}) {
    final controls = _buildSchemaControls(template);
    final selectedTemplateId = template?.id ?? widget.templateId;
    final sections = template?.sections ?? const <FormSectionModel>[];
    final hasTemplateSections = sections.isNotEmpty;
    final visible = ref.watch(resumeFormProvider).visibleSections;
    final showAll = template == null;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
      children: [
        if (template != null)
          _TemplateHeader(template: template)
        else
          _TemplateHeader(template: null),
        const SizedBox(height: 8),
        if (hasTemplateSections)
          ...sections.map(
            (section) => SchemaFormSection(
              section: section,
              aiActions: controls[section.key.toLowerCase()] ?? section.aiActions,
              onAiAction: (action) => _openAiAction(context, [action]),
              onAiPressed: () => _openAiAction(
                context,
                controls[section.key.toLowerCase()] ?? section.aiActions,
              ),
            ),
          )
        else ...[
          if (showAll || visible.contains('basics')) const BasicInfoSection(),
          if (showAll || visible.contains('summary'))
            SummarySection(
              aiActions: controls['summary'] ?? const [],
              onAiPressed: () =>
                  _openAiAction(context, controls['summary'] ?? const []),
            ),
          if (showAll || visible.contains('experience'))
            ExperienceSection(
              aiActions: controls['experience'] ?? const [],
              onAiPressed: () =>
                  _openAiAction(context, controls['experience'] ?? const []),
            ),
          if (showAll || visible.contains('skills'))
            SkillsSection(
              aiActions: controls['skills'] ?? const [],
              onAiPressed: () =>
                  _openAiAction(context, controls['skills'] ?? const []),
            ),
        ],
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: () => _saveResume(context, selectedTemplateId),
          icon: const Icon(Icons.save_outlined),
          label: const Text('Save Resume'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      ],
    );
  }

  Widget _buildError(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(error, textAlign: TextAlign.center),
      ),
    );
  }

  void _applyTemplateSchema(TemplateDetailModel template) {
    final notifier = ref.read(resumeFormProvider.notifier);
    final visible = <String>{};
    final actions = <String, List<String>>{};

    for (final section in template.sections) {
      final key = section.key.toLowerCase();
      final actionList = section.aiActions
          .map((action) => action.toLowerCase())
          .toList();

      visible.add(key);

      if (key == 'basics' ||
          _hasField(section, 'name') ||
          _hasField(section, 'email') ||
          _hasField(section, 'phone')) {
        visible.add('basics');
        if (actionList.isNotEmpty) {
          actions['summary'] = [...?actions['summary'], ...actionList];
        }
      }

      if (key == 'summary' || _hasField(section, 'summary')) {
        visible.add('summary');
        if (actionList.isNotEmpty) {
          actions['summary'] = [...?actions['summary'], ...actionList];
        }
      }

      if (key == 'experience') {
        visible.add('experience');
        if (actionList.isNotEmpty) {
          actions['experience'] = [...?actions['experience'], ...actionList];
        }
      }

      if (key == 'skills') {
        visible.add('skills');
        if (actionList.isNotEmpty) {
          actions['skills'] = [...?actions['skills'], ...actionList];
        }
      }
    }

    notifier.applySchema(visibleSections: visible, sectionActions: actions);
    _appliedTemplateId = template.id;
  }

  Map<String, List<String>> _buildSchemaControls(
    TemplateDetailModel? template,
  ) {
    if (template == null) {
      return const {
        'summary': ['generate_summary', 'improve_section'],
        'experience': ['generate_bullets'],
        'skills': ['suggest_skills'],
      };
    }

    final controls = <String, List<String>>{};
    for (final section in template.sections) {
      final actions = section.aiActions
          .map((action) => action.toLowerCase())
          .toList();
      if (section.key.toLowerCase() == 'basics' ||
          _hasField(section, 'summary')) {
        controls['summary'] = [...?controls['summary'], ...actions];
      }
      if (section.key.toLowerCase() == 'experience') {
        controls['experience'] = [...?controls['experience'], ...actions];
      }
      if (section.key.toLowerCase() == 'skills') {
        controls['skills'] = [...?controls['skills'], ...actions];
      }
    }
    return controls;
  }

  bool _hasField(FormSectionModel section, String fieldKey) {
    return section.fields.any(
          (field) => field.key.toLowerCase() == fieldKey.toLowerCase(),
        ) ||
        section.fields.any(
          (field) => field.objectFields.any(
            (item) => item.key.toLowerCase() == fieldKey.toLowerCase(),
          ),
        );
  }

  void _openAiAction(BuildContext context, List<String> actions) {
    if (actions.isEmpty) return;

    final action = actions.first;
    final route = switch (action) {
      'generate_summary' => '/resume/ai-input/summary',
      'improve_section' => '/resume/ai-input/improve',
      'suggest_skills' => '/resume/ai-input/skills',
      'generate_bullets' => '/resume/ai-input/bullets',
      _ => '/resume/ai-assistant',
    };

    context.push(route);
  }

  Future<void> _saveResume(BuildContext context, String? templateId) async {
    if (templateId == null || templateId.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Select a template first.')));
      return;
    }

    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);
    final form = ref.read(resumeFormProvider);
    final created = await ref
        .read(createResumeProvider.notifier)
        .submit(templateId: templateId, formData: form.data);

    if (!mounted) return;

    if (created != null) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Resume saved successfully.')),
      );
      router.go('/home');
    } else {
      messenger.showSnackBar(
        const SnackBar(content: Text('Failed to save resume.')),
      );
    }
  }
}

class _TemplateHeader extends StatelessWidget {
  final TemplateDetailModel? template;

  const _TemplateHeader({required this.template});

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            template?.title ?? 'Resume Builder',
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Schema-driven sections with AI autofill.',
            style: TextStyle(color: colors.textSecondary),
          ),
        ],
      ),
    );
  }
}


