enum SectionType { single, repeatable, list }

class TemplateDetailModel {
  final String id;
  final String title;
  final int version;
  final String? thumbnailUrl;
  final List<FormSectionModel> sections;
  final Map<String, dynamic> rawSchema;

  const TemplateDetailModel({
    required this.id,
    required this.title,
    this.version = 1,
    this.thumbnailUrl,
    required this.sections,
    this.rawSchema = const {},
  });

  factory TemplateDetailModel.fromJson(Map<String, dynamic> json) {
    final metadata =
        (json['metadata'] as Map<String, dynamic>?) ?? <String, dynamic>{};
    final schema =
        (json['form_schema'] as Map<String, dynamic>?) ??
        (metadata['form_schema'] as Map<String, dynamic>?) ??
        <String, dynamic>{};

    // Sometimes the backend sends sections at the root of schema, or nested.
    final rawSections = (schema['sections'] as List?) ?? const [];

    List<FormSectionModel> sectionsList = rawSections
        .whereType<Map<String, dynamic>>()
        .map(FormSectionModel.fromJson)
        .toList();

    // If schema doesn't define sections, try to infer from common JSON Resume keys
    if (sectionsList.isEmpty) {
      // Basics
      final basicsFields = <FormFieldModel>[];
      basicsFields.add(
        FormFieldModel(key: 'name', label: 'Full Name', type: 'text'),
      );
      basicsFields.add(
        FormFieldModel(key: 'email', label: 'Email', type: 'text'),
      );
      basicsFields.add(
        FormFieldModel(key: 'phone', label: 'Phone', type: 'text'),
      );
      basicsFields.add(
        FormFieldModel(key: 'label', label: 'Job Title', type: 'text'),
      );
      basicsFields.add(
        FormFieldModel(key: 'summary', label: 'Summary', type: 'textarea'),
      );

      sectionsList.add(
        FormSectionModel(
          title: 'Personal Information',
          key: 'basics',
          type: SectionType.single,
          aiActions: const [],
          fields: basicsFields,
        ),
      );

      // Canonical work section; fallback submissions must not use aliases.
      sectionsList.add(
        FormSectionModel(
          title: 'Work Experience',
          key: 'work',
          type: SectionType.repeatable,
          aiActions: const [],
          fields: [
            FormFieldModel(
              key: 'work',
              label: 'Experience',
              type: 'list_object',
              objectFields: const [
                FormObjectFieldModel(key: 'position', label: 'Job Title'),
                FormObjectFieldModel(key: 'name', label: 'Company'),
                FormObjectFieldModel(key: 'startDate', label: 'Start Date'),
                FormObjectFieldModel(key: 'endDate', label: 'End Date'),
                FormObjectFieldModel(key: 'summary', label: 'Description'),
              ],
            ),
          ],
        ),
      );

      // Canonical skills are an array of objects.
      sectionsList.add(
        FormSectionModel(
          title: 'Skills',
          key: 'skills',
          type: SectionType.repeatable,
          aiActions: const [],
          fields: const [
            FormFieldModel(
              key: 'skills',
              label: 'Skills',
              type: 'list_object',
              objectFields: [
                FormObjectFieldModel(key: 'name', label: 'Category'),
                FormObjectFieldModel(key: 'level', label: 'Level'),
                FormObjectFieldModel(
                  key: 'keywords',
                  label: 'Skills',
                  type: 'list',
                ),
              ],
            ),
          ],
        ),
      );

      // Education
      sectionsList.add(
        FormSectionModel(
          title: 'Education',
          key: 'education',
          type: SectionType.repeatable,
          aiActions: const [],
          fields: [
            FormFieldModel(
              key: 'education',
              label: 'Education',
              type: 'list_object',
              objectFields: const [
                FormObjectFieldModel(key: 'institution', label: 'Institution'),
                FormObjectFieldModel(key: 'area', label: 'Area of Study'),
                FormObjectFieldModel(key: 'studyType', label: 'Degree'),
                FormObjectFieldModel(key: 'startDate', label: 'Start Date'),
                FormObjectFieldModel(key: 'endDate', label: 'End Date'),
              ],
            ),
          ],
        ),
      );
    }

    return TemplateDetailModel(
      id: json['id'].toString(),
      title: json['title'] as String? ?? 'Template',
      version: (json['version'] as num?)?.toInt() ?? 1,
      thumbnailUrl: json['thumbnail_url'] as String?,
      sections: sectionsList,
      rawSchema: schema,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'version': version,
    'thumbnail_url': thumbnailUrl,
    'form_schema': {
      ...rawSchema,
      'sections': sections.map((section) => section.toJson()).toList(),
    },
  };
}

class FormSectionModel {
  final String title;
  final String key;
  final SectionType type;
  final List<String> aiActions;
  final List<FormFieldModel> fields;
  final String group;
  final bool defaultVisible;
  final int order;
  final bool canSkip;
  final List<String> recommendedFor;

  const FormSectionModel({
    required this.title,
    required this.key,
    required this.type,
    required this.aiActions,
    required this.fields,
    this.group = 'core',
    this.defaultVisible = true,
    this.order = 0,
    this.canSkip = true,
    this.recommendedFor = const [],
  });

  factory FormSectionModel.fromJson(Map<String, dynamic> json) {
    final rawFields = (json['fields'] as List?) ?? const [];
    final rawAiActions =
        (json['ai_actions'] as List?) ?? (json['ai'] as List?) ?? const [];

    final typeStr = json['type'] as String? ?? 'single';
    SectionType type = SectionType.single;
    if (typeStr == 'repeatable') type = SectionType.repeatable;
    if (typeStr == 'list') type = SectionType.list;

    // Fallback key if not provided
    final titleFallback = (json['title'] as String? ?? 'section')
        .toLowerCase()
        .replaceAll(' ', '_');

    return FormSectionModel(
      title: json['title'] as String? ?? 'Section',
      key: json['key'] as String? ?? titleFallback,
      type: type,
      aiActions: rawAiActions.map((e) => e.toString()).toList(),
      fields: rawFields
          .whereType<Map<String, dynamic>>()
          .map(FormFieldModel.fromJson)
          .toList(),
      group: json['group'] as String? ?? 'core',
      defaultVisible: json['default_visible'] as bool? ?? true,
      order: (json['order'] as num?)?.toInt() ?? 0,
      canSkip: json['can_skip'] as bool? ?? true,
      recommendedFor:
          (json['recommended_for'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
    );
  }

  Map<String, dynamic> toJson() => {
    'title': title,
    'key': key,
    'type': type.name,
    'ai_actions': aiActions,
    'fields': fields.map((field) => field.toJson()).toList(),
    'group': group,
    'default_visible': defaultVisible,
    'order': order,
    'can_skip': canSkip,
    'recommended_for': recommendedFor,
  };

  FormSectionModel copyWith({String? title, List<FormFieldModel>? fields}) =>
      FormSectionModel(
        title: title ?? this.title,
        key: key,
        type: type,
        aiActions: aiActions,
        fields: fields ?? this.fields,
        group: group,
        defaultVisible: defaultVisible,
        order: order,
        canSkip: canSkip,
        recommendedFor: recommendedFor,
      );
}

class FormFieldModel {
  final String key;
  final String label;
  final String type; // e.g. text, textarea, list_object, etc.
  final bool required;
  final String requirement;
  final List<String> options;
  final List<String> aiActions;
  final String? help;
  final List<FormObjectFieldModel> objectFields;

  const FormFieldModel({
    required this.key,
    required this.label,
    required this.type,
    this.required = false,
    this.requirement = 'optional',
    this.options = const [],
    this.aiActions = const [],
    this.help,
    this.objectFields = const [],
  });

  bool get isList => type.toLowerCase() == 'list';
  bool get isListObject => type.toLowerCase() == 'list_object';

  factory FormFieldModel.fromJson(Map<String, dynamic> json) {
    final rawObjectFields =
        (json['item_fields'] as List?) ?? (json['fields'] as List?) ?? const [];
    final type = json['type'] as String? ?? 'text';
    final rawOptions = (json['options'] as List?) ?? const [];
    final rawAiActions =
        (json['ai_actions'] as List?) ?? (json['ai'] as List?) ?? const [];
    final parsedObjectFields = rawObjectFields
        .whereType<Map<String, dynamic>>()
        .map(FormObjectFieldModel.fromJson)
        .toList();
    if (type.toLowerCase() == 'list_object' && parsedObjectFields.isEmpty) {
      parsedObjectFields.add(
        const FormObjectFieldModel(key: 'value', label: 'Value'),
      );
    }

    return FormFieldModel(
      key: json['key'] as String? ?? '',
      label: json['label'] as String? ?? '',
      type: type,
      required: json['required'] as bool? ?? false,
      requirement:
          json['requirement'] as String? ??
          ((json['required'] as bool? ?? false)
              ? 'entry_required'
              : 'optional'),
      options: rawOptions.map((value) => value.toString()).toList(),
      aiActions: rawAiActions.map((value) => value.toString()).toList(),
      help: json['help'] as String?,
      objectFields: parsedObjectFields,
    );
  }

  Map<String, dynamic> toJson() => {
    'key': key,
    'label': label,
    'type': type,
    'required': required,
    'requirement': requirement,
    'options': options,
    'ai_actions': aiActions,
    'help': help,
    'item_fields': objectFields.map((field) => field.toJson()).toList(),
  };
}

class FormObjectFieldModel {
  final String key;
  final String label;
  final String type;
  final bool required;
  final String requirement;
  final String? help;
  final List<String> aiActions;

  const FormObjectFieldModel({
    required this.key,
    required this.label,
    this.type = 'text',
    this.required = false,
    this.requirement = 'optional',
    this.help,
    this.aiActions = const [],
  });

  factory FormObjectFieldModel.fromJson(Map<String, dynamic> json) {
    return FormObjectFieldModel(
      key: json['key'] as String? ?? '',
      label: json['label'] as String? ?? 'Value',
      type: json['type'] as String? ?? 'text',
      required: json['required'] as bool? ?? false,
      requirement:
          json['requirement'] as String? ??
          ((json['required'] as bool? ?? false)
              ? 'entry_required'
              : 'optional'),
      help: json['help'] as String?,
      aiActions:
          ((json['ai_actions'] as List?) ?? (json['ai'] as List?) ?? const [])
              .map((value) => value.toString())
              .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'key': key,
    'label': label,
    'type': type,
    'required': required,
    'requirement': requirement,
    'help': help,
    'ai_actions': aiActions,
  };
}
