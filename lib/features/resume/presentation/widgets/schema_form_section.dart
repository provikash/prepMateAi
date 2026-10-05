import 'package:prepmate_mobile/core/widgets/app_loading.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../config/theme.dart';
import '../../../../core/providers/form_provider.dart';
import '../../data/models/template_detail_model.dart';
import '../providers/field_enhance_provider.dart';
import 'chip_input.dart';
import 'resume_widgets.dart';

class FieldEnhanceTarget {
  const FieldEnhanceTarget({
    required this.fieldPath,
    required this.originalValue,
    required this.latestValue,
    required this.apply,
    required this.schemaActions,
    this.context = const {},
  });

  final String fieldPath;
  final dynamic originalValue;
  final dynamic Function() latestValue;
  final ValueChanged<dynamic> apply;
  final List<String> schemaActions;
  final Map<String, dynamic> context;
}

class SchemaFormSection extends StatelessWidget {
  final FormSectionModel section;
  final List<String> aiActions;
  final VoidCallback? onAiPressed;
  final ValueChanged<String>? onAiAction;
  final ValueChanged<FieldEnhanceTarget>? onEnhance;
  final String? enhancingPath;
  final Map<String, String> backendErrors;

  const SchemaFormSection({
    super.key,
    required this.section,
    this.aiActions = const [],
    this.onAiPressed,
    this.onAiAction,
    this.onEnhance,
    this.enhancingPath,
    this.backendErrors = const {},
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
        onEnhance: onEnhance,
        enhancingPath: enhancingPath,
        backendErrors: backendErrors,
      );
    }
    return _SingleSchemaSection(
      section: section,
      aiActions: aiActions,
      onAiPressed: onAiPressed,
      onAiAction: onAiAction,
      onEnhance: onEnhance,
      enhancingPath: enhancingPath,
      backendErrors: backendErrors,
    );
  }
}

class _SingleSchemaSection extends ConsumerStatefulWidget {
  final FormSectionModel section;
  final List<String> aiActions;
  final VoidCallback? onAiPressed;
  final ValueChanged<String>? onAiAction;
  final ValueChanged<FieldEnhanceTarget>? onEnhance;
  final String? enhancingPath;
  final Map<String, String> backendErrors;

  const _SingleSchemaSection({
    required this.section,
    required this.aiActions,
    required this.onAiPressed,
    required this.onAiAction,
    required this.onEnhance,
    required this.enhancingPath,
    required this.backendErrors,
  });

  @override
  ConsumerState<_SingleSchemaSection> createState() =>
      _SingleSchemaSectionState();
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
    final sectionData = ref
        .watch(resumeFormProvider)
        .sectionMap(widget.section.key);

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
                onEnhance: widget.onEnhance,
                enhancingPath: widget.enhancingPath,
                backendError:
                    widget.backendErrors['${widget.section.key}.${field.key}'],
              ),
            );
          }),
        ],
      ),
    );
  }

  TextEditingController _controllerFor(String key, Object? value) {
    final text = value is List
        ? value.join('\n')
        : value is Map
        ? ''
        : value?.toString() ?? '';
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
  final ValueChanged<FieldEnhanceTarget>? onEnhance;
  final String? enhancingPath;
  final Map<String, String> backendErrors;

  const _RepeatableSchemaSection({
    required this.section,
    required this.aiActions,
    required this.onAiPressed,
    required this.onAiAction,
    required this.onEnhance,
    required this.enhancingPath,
    required this.backendErrors,
  });

  @override
  ConsumerState<_RepeatableSchemaSection> createState() =>
      _RepeatableSchemaSectionState();
}

class _RepeatableSchemaSectionState
    extends ConsumerState<_RepeatableSchemaSection> {
  final Map<String, TextEditingController> _controllers = {};
  final List<Key> _itemKeys = [];
  int? _expandedIndex;

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final items = ref
        .watch(resumeFormProvider)
        .sectionItems(widget.section.key);
    final colors = AppColors.of(context);
    while (_itemKeys.length < items.length) {
      _itemKeys.add(UniqueKey());
    }
    if (_itemKeys.length > items.length) {
      _itemKeys.removeRange(items.length, _itemKeys.length);
    }

    return SectionCard(
      title: widget.section.title,
      icon: _iconForSection(widget.section.key),
      onAdd: () {
        _itemKeys.add(UniqueKey());
        setState(() => _expandedIndex = items.length);
        ref
            .read(resumeFormProvider.notifier)
            .addSectionItem(widget.section.key, _emptyItem(widget.section));
      },
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
                key: _itemKeys[entry.key],
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
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _itemTitle(entry.value, entry.key),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: colors.textPrimary,
                                  ),
                                ),
                                if (_itemSubtitle(entry.value).isNotEmpty)
                                  Text(
                                    _itemSubtitle(entry.value),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: colors.textSecondary,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          IconButton(
                            tooltip: _expandedIndex == entry.key
                                ? 'Collapse item'
                                : 'Edit item',
                            onPressed: () => setState(() {
                              _expandedIndex = _expandedIndex == entry.key
                                  ? null
                                  : entry.key;
                            }),
                            icon: Icon(
                              _expandedIndex == entry.key
                                  ? Icons.expand_less
                                  : Icons.edit_outlined,
                            ),
                          ),
                          IconButton(
                            tooltip: 'Move up',
                            onPressed: entry.key == 0
                                ? null
                                : () => _moveItem(entry.key, entry.key - 1),
                            icon: const Icon(Icons.arrow_upward),
                          ),
                          IconButton(
                            tooltip: 'Move down',
                            onPressed: entry.key == items.length - 1
                                ? null
                                : () => _moveItem(entry.key, entry.key + 1),
                            icon: const Icon(Icons.arrow_downward),
                          ),
                          IconButton(
                            tooltip: 'Delete item',
                            onPressed: () => _confirmRemove(
                              context,
                              entry.key,
                              _itemTitle(entry.value, entry.key),
                            ),
                            icon: const Icon(Icons.delete_outline),
                          ),
                        ],
                      ),
                      if (_expandedIndex == entry.key) ...[
                        ..._primaryFields(
                          widget.section,
                        ).map((field) => _entryField(entry, field)),
                        if (_secondaryFields(widget.section).isNotEmpty)
                          Card(
                            elevation: 0,
                            child: ExpansionTile(
                              title: const Text('More details'),
                              subtitle: const Text('Optional information'),
                              childrenPadding: const EdgeInsets.fromLTRB(
                                12,
                                0,
                                12,
                                8,
                              ),
                              children: [
                                for (final field in _secondaryFields(
                                  widget.section,
                                ))
                                  _entryField(entry, field),
                              ],
                            ),
                          ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _entryField(
    MapEntry<int, Map<String, dynamic>> entry,
    FormFieldModel field,
  ) {
    final value = entry.value[field.key];
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: _SchemaFieldInput(
        key: ValueKey('${widget.section.key}-${entry.key}-${field.key}'),
        sectionKey: widget.section.key,
        field: field,
        value: value,
        controller: _controllerFor(entry.key, field.key, value),
        aiActions: field.aiActions,
        onAiAction: widget.onAiAction,
        onChanged: (nextValue) =>
            ref.read(resumeFormProvider.notifier).updateSectionItem(
              widget.section.key,
              entry.key,
              {field.key: nextValue},
            ),
        itemIndex: entry.key,
        itemContext: entry.value,
        onEnhance: widget.onEnhance,
        enhancingPath: widget.enhancingPath,
        backendError: widget
            .backendErrors['${widget.section.key}[${entry.key}].${field.key}'],
      ),
    );
  }

  List<FormFieldModel> _primaryFields(FormSectionModel section) {
    final fields = _entryFields(section);
    final secondary = _secondaryKeys(section.key);
    return fields.where((field) => !secondary.contains(field.key)).toList();
  }

  List<FormFieldModel> _secondaryFields(FormSectionModel section) {
    final secondary = _secondaryKeys(section.key);
    return _entryFields(
      section,
    ).where((field) => secondary.contains(field.key)).toList();
  }

  Set<String> _secondaryKeys(String sectionKey) => switch (sectionKey) {
    'work' => {'url', 'location', 'summary'},
    'education' => {'score', 'location', 'url', 'courses'},
    _ => const <String>{},
  };

  String _itemTitle(Map<String, dynamic> item, int index) {
    for (final key in const ['position', 'name', 'institution', 'title']) {
      final value = item[key]?.toString().trim() ?? '';
      if (value.isNotEmpty) return value;
    }
    return '${widget.section.title} ${index + 1}';
  }

  String _itemSubtitle(Map<String, dynamic> item) {
    final parts = <String>[];
    for (final key in const ['name', 'institution', 'area']) {
      final value = item[key]?.toString().trim() ?? '';
      if (value.isNotEmpty && !parts.contains(value)) parts.add(value);
    }
    final start = item['startDate']?.toString().trim() ?? '';
    final end = item['endDate'];
    if (start.isNotEmpty) {
      parts.add(
        '$start - ${end == null || end.toString().trim().isEmpty ? 'Present' : end}',
      );
    }
    return parts.take(2).join(' · ');
  }

  Future<void> _confirmRemove(
    BuildContext context,
    int index,
    String title,
  ) async {
    final remove = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete this item?'),
        content: Text('“$title” will be removed from this resume.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (remove != true || !mounted) return;
    setState(() {
      _itemKeys.removeAt(index);
      _expandedIndex = null;
      _clearControllers();
    });
    ref
        .read(resumeFormProvider.notifier)
        .removeSectionItem(widget.section.key, index);
  }

  Map<String, dynamic> _emptyItem(FormSectionModel section) {
    final item = <String, dynamic>{};
    for (final field in _entryFields(section)) {
      item[field.key] = field.isList ? <dynamic>[] : '';
    }
    return item;
  }

  TextEditingController _controllerFor(int index, String key, Object? value) {
    final controllerKey = '$index:$key';
    final text = value is List ? value.join('\n') : value?.toString() ?? '';
    final existing = _controllers[controllerKey];
    if (existing != null) {
      if (existing.text != text) existing.text = text;
      return existing;
    }
    return _controllers[controllerKey] = TextEditingController(text: text);
  }

  /// A repeatable schema can describe an entry as a `list_object` field. Once
  /// the section owns the list, its object fields are the fields for every
  /// individual card.
  List<FormFieldModel> _entryFields(FormSectionModel section) => [
    for (final field in section.fields)
      if (field.isListObject)
        ...field.objectFields.map(
          (itemField) => FormFieldModel(
            key: itemField.key,
            label: itemField.label,
            type: itemField.type,
            required: itemField.required,
            requirement: itemField.requirement,
            help: itemField.help,
            aiActions: itemField.aiActions,
          ),
        )
      else
        field,
  ];

  void _moveItem(int from, int to) {
    final key = _itemKeys.removeAt(from);
    _itemKeys.insert(to, key);
    _clearControllers();
    ref
        .read(resumeFormProvider.notifier)
        .reorderSectionItem(widget.section.key, from, to);
  }

  void _clearControllers() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    _controllers.clear();
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
  final int? itemIndex;
  final Map<String, dynamic>? itemContext;
  final ValueChanged<FieldEnhanceTarget>? onEnhance;
  final String? enhancingPath;
  final String? backendError;

  const _SchemaFieldInput({
    super.key,
    required this.sectionKey,
    required this.field,
    required this.value,
    required this.controller,
    required this.aiActions,
    required this.onAiAction,
    required this.onChanged,
    this.itemIndex,
    this.itemContext,
    this.onEnhance,
    this.enhancingPath,
    this.backendError,
  });

  @override
  State<_SchemaFieldInput> createState() => _SchemaFieldInputState();
}

class _SchemaFieldInputState extends State<_SchemaFieldInput> {
  late bool _ongoing;

  @override
  void initState() {
    super.initState();
    _ongoing = widget.field.key == 'endDate' && widget.value == null;
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
    final label = field.required
        ? '${field.label} *'
        : field.requirement == 'recommended'
        ? '${field.label} (recommended)'
        : '${field.label} (optional)';
    final helper = field.help;
    final type = field.type.toLowerCase();
    const supportedTypes = {
      'text',
      'textarea',
      'email',
      'phone',
      'url',
      'date',
      'list',
      'select',
      'location',
      'profiles',
    };
    if (!supportedTypes.contains(type)) {
      return Semantics(
        liveRegion: true,
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: label,
            errorText: 'Unsupported form field type: ${field.type}',
          ),
          child: Text('This field cannot be edited in this app version.'),
        ),
      );
    }

    if (type == 'location') {
      return _LocationFieldInput(
        label: label,
        helper: helper,
        value: widget.value,
        onChanged: widget.onChanged,
      );
    }
    if (type == 'profiles') {
      return _ProfilesFieldInput(
        label: label,
        helper: helper,
        value: widget.value,
        onChanged: widget.onChanged,
      );
    }
    if (type == 'list' &&
        widget.sectionKey == 'skills' &&
        field.key == 'keywords') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.titleSmall),
          if (helper != null) Text(helper),
          const SizedBox(height: 8),
          ChipInput(
            initial: (widget.value as List? ?? const [])
                .whereType<String>()
                .toList(),
            onChanged: widget.onChanged,
          ),
        ],
      );
    }

    if (type == 'select') {
      final options = field.options;
      final current = widget.value?.toString();
      return DropdownButtonFormField<String>(
        initialValue: options.contains(current) ? current : null,
        decoration: InputDecoration(
          labelText: label,
          helperText: helper,
          errorText: widget.backendError,
        ),
        items: options
            .map(
              (option) => DropdownMenuItem(value: option, child: Text(option)),
            )
            .toList(),
        onChanged: (value) => widget.onChanged(value ?? ''),
        validator: (value) =>
            field.required && (value == null || value.trim().isEmpty)
            ? '${field.label} is required'
            : null,
      );
    }

    if (type == 'date' && field.key == 'endDate') {
      return Column(
        children: [
          TextFormField(
            controller: widget.controller,
            enabled: !_ongoing,
            keyboardType: TextInputType.datetime,
            decoration: InputDecoration(
              labelText: label,
              helperText: helper ?? 'Use YYYY, YYYY-MM, or YYYY-MM-DD.',
              errorText: widget.backendError,
            ),
            onChanged: widget.onChanged,
            validator: _validateText,
          ),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('This is current / ongoing'),
            value: _ongoing,
            onChanged: (checked) {
              setState(() => _ongoing = checked ?? false);
              if (_ongoing) {
                widget.controller.clear();
                widget.onChanged(null);
              } else {
                widget.onChanged('');
              }
            },
          ),
        ],
      );
    }

    final maxLines = switch (type) {
      'textarea' => 5,
      'list' => 3,
      _ => 1,
    };
    final keyboardType = switch (type) {
      'email' => TextInputType.emailAddress,
      'phone' => TextInputType.phone,
      'url' => TextInputType.url,
      _ => TextInputType.text,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: widget.controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          decoration: InputDecoration(
            labelText: label,
            helperText: helper,
            errorText: widget.backendError,
          ),
          onChanged: (value) => widget.onChanged(_outputValue(value)),
          validator: _validateText,
        ),
        if (_canEnhance()) ...[
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: _hasEnhanceableValue() && widget.enhancingPath == null
                  ? _requestEnhancement
                  : null,
              icon: widget.enhancingPath == _fieldPath()
                  ? const SizedBox.square(
                      dimension: 16,
                      child: AppLoading(strokeWidth: 2),
                    )
                  : const Icon(Icons.auto_awesome, size: 18),
              label: const Text('Enhance with AI'),
            ),
          ),
        ],
      ],
    );
  }

  String? _validateText(String? value) {
    final text = value?.trim() ?? '';
    if (widget.field.required && text.isEmpty) {
      return '${widget.field.label} is required';
    }
    if (text.isEmpty) return null;
    final type = widget.field.type.toLowerCase();
    if (type == 'email' &&
        !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(text)) {
      return 'Enter a valid email address';
    }
    if (type == 'url') {
      final uri = Uri.tryParse(text.contains('://') ? text : 'https://$text');
      if (uri == null ||
          !uri.hasAuthority ||
          !{'http', 'https'}.contains(uri.scheme)) {
        return 'Enter a valid http or https URL';
      }
    }
    if (type == 'date' &&
        !RegExp(r'^\d{4}(-\d{2})?(-\d{2})?$').hasMatch(text)) {
      return 'Use YYYY, YYYY-MM, or YYYY-MM-DD';
    }
    if (widget.field.key == 'endDate') {
      final start = widget.itemContext?['startDate']?.toString() ?? '';
      if (start.isNotEmpty && text.compareTo(start) < 0) {
        return 'End date cannot be before start date';
      }
    }
    return null;
  }

  String _textValue(dynamic value) {
    if (value == null) return '';
    if (value is List) {
      if (widget.field.type.toLowerCase() == 'profiles') {
        return value
            .whereType<Map>()
            .map((profile) {
              final network = profile['network']?.toString() ?? 'Profile';
              final url = profile['url']?.toString() ?? '';
              return '$network | $url';
            })
            .join('\n');
      }
      return value.join('\n');
    }
    if (value is Map && widget.field.type.toLowerCase() == 'location') {
      return value['city']?.toString() ?? '';
    }
    if (value is Map) return '';
    return value.toString();
  }

  dynamic _outputValue(String value) {
    final type = widget.field.type.toLowerCase();
    if (type == 'list') {
      return value
          .split(RegExp(r'\r?\n'))
          .map((item) => item.trim())
          .where((item) => item.isNotEmpty)
          .toList();
    }
    return value;
  }

  String _fieldPath() => widget.itemIndex == null
      ? '${widget.sectionKey}.${widget.field.key}'
      : '${widget.sectionKey}[].${widget.field.key}';

  bool _canEnhance() =>
      FieldEnhanceMapping.resolve(_fieldPath(), widget.field.aiActions) != null;

  bool _hasEnhanceableValue() => widget.value is List
      ? (widget.value as List).isNotEmpty
      : widget.value is String && (widget.value as String).trim().isNotEmpty;

  void _requestEnhancement() {
    final original = widget.value is List
        ? List<String>.from(widget.value as List)
        : widget.value;
    widget.onEnhance?.call(
      FieldEnhanceTarget(
        fieldPath: _fieldPath(),
        originalValue: original,
        latestValue: () => widget.value,
        apply: widget.onChanged,
        schemaActions: widget.field.aiActions,
        context: Map<String, dynamic>.from(widget.itemContext ?? const {}),
      ),
    );
  }
}

class _LocationFieldInput extends StatefulWidget {
  final String label;
  final String? helper;
  final dynamic value;
  final ValueChanged<dynamic> onChanged;

  const _LocationFieldInput({
    required this.label,
    required this.helper,
    required this.value,
    required this.onChanged,
  });

  @override
  State<_LocationFieldInput> createState() => _LocationFieldInputState();
}

class _LocationFieldInputState extends State<_LocationFieldInput> {
  static const _parts = <(String, String)>[
    ('address', 'Address'),
    ('city', 'City'),
    ('region', 'Region / State'),
    ('postalCode', 'Postal code'),
    ('countryCode', 'Country code'),
  ];
  late Map<String, dynamic> _location;
  final Map<String, TextEditingController> _controllers = {};

  @override
  void initState() {
    super.initState();
    _location = _readLocation(widget.value);
  }

  @override
  void didUpdateWidget(covariant _LocationFieldInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    final incoming = _readLocation(widget.value);
    if (!_deepValueEquals(_location, incoming)) {
      _location = incoming;
      for (final part in _parts) {
        final text = _location[part.$1]?.toString() ?? '';
        if (_controllers[part.$1]?.text != text) {
          _controllers[part.$1]?.text = text;
        }
      }
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Map<String, dynamic> _readLocation(dynamic value) =>
      value is Map ? Map<String, dynamic>.from(value) : <String, dynamic>{};

  TextEditingController _controller(String field) => _controllers.putIfAbsent(
    field,
    () => TextEditingController(text: _location[field]?.toString() ?? ''),
  );

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.label, style: Theme.of(context).textTheme.titleSmall),
        if (widget.helper != null) Text(widget.helper!),
        const SizedBox(height: 8),
        _locationPart(('city', 'City')),
        Card(
          margin: EdgeInsets.zero,
          child: ExpansionTile(
            title: const Text('Full location'),
            subtitle: const Text(
              'Address, region, postal code, and country · Optional',
            ),
            childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
            children: [
              for (final part in _parts.where((part) => part.$1 != 'city'))
                _locationPart(part),
            ],
          ),
        ),
      ],
    );
  }

  Widget _locationPart((String, String) part) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: TextFormField(
      controller: _controller(part.$1),
      decoration: InputDecoration(labelText: part.$2),
      onChanged: (value) {
        _location[part.$1] = value.trim();
        widget.onChanged(Map<String, dynamic>.from(_location));
      },
    ),
  );
}

class _ProfilesFieldInput extends StatefulWidget {
  final String label;
  final String? helper;
  final dynamic value;
  final ValueChanged<dynamic> onChanged;

  const _ProfilesFieldInput({
    required this.label,
    required this.helper,
    required this.value,
    required this.onChanged,
  });

  @override
  State<_ProfilesFieldInput> createState() => _ProfilesFieldInputState();
}

class _ProfilesFieldInputState extends State<_ProfilesFieldInput> {
  late List<Map<String, dynamic>> _profiles;
  final Map<String, TextEditingController> _controllers = {};

  @override
  void initState() {
    super.initState();
    _profiles = _readProfiles(widget.value);
  }

  @override
  void didUpdateWidget(covariant _ProfilesFieldInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    final incoming = _readProfiles(widget.value);
    if (!_deepValueEquals(_profiles, incoming)) {
      _profiles = incoming;
      _disposeControllers();
    }
  }

  @override
  void dispose() {
    _disposeControllers();
    super.dispose();
  }

  void _disposeControllers() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    _controllers.clear();
  }

  List<Map<String, dynamic>> _readProfiles(dynamic value) => value is List
      ? value
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList()
      : <Map<String, dynamic>>[];

  TextEditingController _controller(int index, String field) {
    final key = '$index:$field';
    return _controllers.putIfAbsent(
      key,
      () => TextEditingController(
        text: _profiles[index][field]?.toString() ?? '',
      ),
    );
  }

  void _emit() => widget.onChanged(
    _profiles.map((item) => Map<String, dynamic>.from(item)).toList(),
  );

  void _move(int from, int to) {
    if (to < 0 || to >= _profiles.length) return;
    setState(() {
      final item = _profiles.removeAt(from);
      _profiles.insert(to, item);
      _disposeControllers();
    });
    _emit();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.label, style: Theme.of(context).textTheme.titleSmall),
        if (widget.helper != null) Text(widget.helper!),
        for (var index = 0; index < _profiles.length; index++)
          Card(
            margin: const EdgeInsets.only(top: 8),
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                children: [
                  for (final part in const <(String, String)>[
                    ('network', 'Network'),
                    ('username', 'Username'),
                    ('url', 'Profile URL'),
                  ])
                    TextFormField(
                      controller: _controller(index, part.$1),
                      keyboardType: part.$1 == 'url'
                          ? TextInputType.url
                          : TextInputType.text,
                      decoration: InputDecoration(labelText: part.$2),
                      onChanged: (value) {
                        _profiles[index][part.$1] = value.trim();
                        _emit();
                      },
                    ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      IconButton(
                        tooltip: 'Move profile up',
                        onPressed: index == 0
                            ? null
                            : () => _move(index, index - 1),
                        icon: const Icon(Icons.arrow_upward),
                      ),
                      IconButton(
                        tooltip: 'Move profile down',
                        onPressed: index == _profiles.length - 1
                            ? null
                            : () => _move(index, index + 1),
                        icon: const Icon(Icons.arrow_downward),
                      ),
                      IconButton(
                        tooltip: 'Remove profile',
                        onPressed: () {
                          setState(() {
                            _profiles.removeAt(index);
                            _disposeControllers();
                          });
                          _emit();
                        },
                        icon: const Icon(Icons.delete_outline),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        TextButton.icon(
          onPressed: () {
            setState(() {
              _profiles.add({'network': '', 'username': '', 'url': ''});
            });
            _emit();
          },
          icon: const Icon(Icons.add),
          label: const Text('Add profile'),
        ),
      ],
    );
  }
}

bool _deepValueEquals(dynamic left, dynamic right) {
  if (identical(left, right)) return true;
  if (left is Map && right is Map) {
    if (left.length != right.length) return false;
    for (final key in left.keys) {
      if (!right.containsKey(key) || !_deepValueEquals(left[key], right[key])) {
        return false;
      }
    }
    return true;
  }
  if (left is List && right is List) {
    if (left.length != right.length) return false;
    for (var index = 0; index < left.length; index++) {
      if (!_deepValueEquals(left[index], right[index])) return false;
    }
    return true;
  }
  return left == right;
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
