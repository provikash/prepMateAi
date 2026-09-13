import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../config/theme.dart';
import '../../../../core/providers/form_provider.dart';
import '../../data/models/template_detail_model.dart';
import 'resume_widgets.dart';

class SchemaFormSection extends StatelessWidget {
  final FormSectionModel section;
  final List<String> aiActions;
  final VoidCallback? onAiPressed;
  final ValueChanged<String>? onAiAction;

  const SchemaFormSection({
    super.key,
    required this.section,
    this.aiActions = const [],
    this.onAiPressed,
    this.onAiAction,
  });

  @override
  Widget build(BuildContext context) {
    final type = section.type;
    if (type == SectionType.repeatable || type == SectionType.list) {
      return _RepeatableSchemaSection(
        section: section,
        aiActions: aiActions,
        onAiPressed: onAiPressed,
        onAiAction: onAiAction,
      );
    }
    return _SingleSchemaSection(
      section: section,
      aiActions: aiActions,
      onAiPressed: onAiPressed,
      onAiAction: onAiAction,
    );
  }
}

class _SingleSchemaSection extends ConsumerStatefulWidget {
  final FormSectionModel section;
  final List<String> aiActions;
  final VoidCallback? onAiPressed;
  final ValueChanged<String>? onAiAction;

  const _SingleSchemaSection({
    required this.section,
    required this.aiActions,
    required this.onAiPressed,
    required this.onAiAction,
  });

  @override
  ConsumerState<_SingleSchemaSection> createState() => _SingleSchemaSectionState();
}

class _SingleSchemaSectionState extends ConsumerState<_SingleSchemaSection> {
  final Map<String, TextEditingController> _controllers = {};

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sectionData = ref.watch(resumeFormProvider).sectionMap(widget.section.key);

    return SectionCard(
      title: widget.section.title,
      icon: _iconForSection(widget.section.key),
      child: Column(
        children: [
          ...widget.section.fields.map((field) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _SchemaFieldInput(
                sectionKey: widget.section.key,
                field: field,
                value: sectionData[field.key],
                controller: _controllerFor(field.key, sectionData[field.key]),
                aiActions: field.aiActions,
                onAiAction: widget.onAiAction,
                onChanged: (value) => ref
                    .read(resumeFormProvider.notifier)
                    .updateSectionField(widget.section.key, field.key, value),
              ),
            );
          }),
          if (widget.aiActions.isNotEmpty) ...[
            const SizedBox(height: 8),
            AIButton(
              text: 'AI ${widget.section.title}',
              onPressed: widget.onAiPressed ?? () {},
            ),
          ],
        ],
      ),
    );
  }

  TextEditingController _controllerFor(String key, Object? value) {
    final text = value?.toString() ?? '';
    final existing = _controllers[key];
    if (existing != null) {
      if (existing.text != text) {
        existing.text = text;
      }
      return existing;
    }
    final controller = TextEditingController(text: text);
    _controllers[key] = controller;
    return controller;
  }
}

class _RepeatableSchemaSection extends ConsumerStatefulWidget {
  final FormSectionModel section;
  final List<String> aiActions;
  final VoidCallback? onAiPressed;
  final ValueChanged<String>? onAiAction;

  const _RepeatableSchemaSection({
    required this.section,
    required this.aiActions,
    required this.onAiPressed,
    required this.onAiAction,
  });

  @override
  ConsumerState<_RepeatableSchemaSection> createState() => _RepeatableSchemaSectionState();
}

class _RepeatableSchemaSectionState extends ConsumerState<_RepeatableSchemaSection> {
  @override
  Widget build(BuildContext context) {
    final items = ref.watch(resumeFormProvider).sectionItems(widget.section.key);
    final colors = AppColors.of(context);

    return SectionCard(
      title: widget.section.title,
      icon: _iconForSection(widget.section.key),
      onAdd: () => ref.read(resumeFormProvider.notifier).addSectionItem(
            widget.section.key,
            _emptyItem(widget.section),
          ),
      child: Column(
        children: [
          if (items.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'Tap Add to create the first ${widget.section.title.toLowerCase()} item.',
                style: TextStyle(color: colors.textSecondary),
              ),
            ),
          ...items.asMap().entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Card(
                elevation: 0,
                color: colors.screenBackground,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: BorderSide(color: colors.border),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Text(
                            '${widget.section.title} ${entry.key + 1}',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: colors.textPrimary,
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            onPressed: () => ref
                                .read(resumeFormProvider.notifier)
                                .removeSectionItem(widget.section.key, entry.key),
                            icon: const Icon(Icons.delete_outline),
                          ),
                        ],
                      ),
                      ...widget.section.fields.map((field) {
                        final value = entry.value[field.key];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _SchemaFieldInput(
                            sectionKey: widget.section.key,
                            field: field,
                            value: value,
                            controller: TextEditingController(text: value?.toString() ?? ''),
                            aiActions: field.aiActions,
                            onAiAction: widget.onAiAction,
                            onChanged: (nextValue) {
                              ref.read(resumeFormProvider.notifier).updateSectionItem(
                                    widget.section.key,
                                    entry.key,
                                    {field.key: nextValue},
                                  );
                            },
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
            );
          }),
          if (widget.aiActions.isNotEmpty) ...[
            const SizedBox(height: 4),
            AIButton(
              text: 'AI ${widget.section.title}',
              onPressed: widget.onAiPressed ?? () {},
            ),
          ],
        ],
      ),
    );
  }

  Map<String, dynamic> _emptyItem(FormSectionModel section) {
    final item = <String, dynamic>{};
    for (final field in section.fields) {
      item[field.key] = field.isList || field.isListObject ? <dynamic>[] : '';
    }
    return item;
  }
}

class _SchemaFieldInput extends StatefulWidget {
  final String sectionKey;
  final FormFieldModel field;
  final dynamic value;
  final TextEditingController controller;
  final List<String> aiActions;
  final ValueChanged<String>? onAiAction;
  final ValueChanged<dynamic> onChanged;

  const _SchemaFieldInput({
    required this.sectionKey,
    required this.field,
    required this.value,
    required this.controller,
    required this.aiActions,
    required this.onAiAction,
    required this.onChanged,
  });

  @override
  State<_SchemaFieldInput> createState() => _SchemaFieldInputState();
}

class _SchemaFieldInputState extends State<_SchemaFieldInput> {
  @override
  void initState() {
    super.initState();
    widget.controller.text = _textValue(widget.value);
  }

  @override
  void didUpdateWidget(covariant _SchemaFieldInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    final nextValue = _textValue(widget.value);
    if (widget.controller.text != nextValue) {
      widget.controller.text = nextValue;
    }
  }

  @override
  Widget build(BuildContext context) {
    final field = widget.field;
    final label = field.required ? '${field.label} *' : field.label;
    final helper = field.help;
    final type = field.type.toLowerCase();

    if (type == 'select') {
      final options = field.options;
      final current = widget.value?.toString();
      return DropdownButtonFormField<String>(
        initialValue: options.contains(current) ? current : null,
        decoration: InputDecoration(labelText: label, helperText: helper),
        items: options
            .map((option) => DropdownMenuItem(value: option, child: Text(option)))
            .toList(),
        onChanged: (value) => widget.onChanged(value ?? ''),
      );
    }

    final maxLines = type == 'textarea' ? 5 : 1;
    final keyboardType = switch (type) {
      'email' => TextInputType.emailAddress,
      'phone' => TextInputType.phone,
      'url' => TextInputType.url,
      _ => TextInputType.text,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: widget.controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          decoration: InputDecoration(labelText: label, helperText: helper),
          onChanged: widget.onChanged,
        ),
        if (widget.aiActions.isNotEmpty) ...[
          const SizedBox(height: 8),
          AIButton(
            text: 'AI ${field.label}',
            onPressed: () {
              final action = widget.aiActions.first;
              widget.onAiAction?.call(action);
            },
          ),
        ],
      ],
    );
  }

  String _textValue(dynamic value) {
    if (value == null) return '';
    if (value is List) return value.join('\n');
    if (value is Map) return value.toString();
    return value.toString();
  }
}

IconData _iconForSection(String key) {
  switch (key.toLowerCase()) {
    case 'personal_info':
    case 'basics':
      return Icons.person_outline;
    case 'experience':
    case 'work':
      return Icons.work_outline;
    case 'education':
      return Icons.school_outlined;
    case 'skills':
      return Icons.auto_awesome;
    case 'projects':
      return Icons.folder_open_outlined;
    case 'awards':
    case 'certifications':
      return Icons.emoji_events_outlined;
    case 'languages':
      return Icons.language_outlined;
    case 'references':
    case 'volunteer':
      return Icons.people_outline;
    default:
      return Icons.description_outlined;
  }
}
