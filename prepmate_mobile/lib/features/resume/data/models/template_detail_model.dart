enum SectionType { single, repeatable, list }

class TemplateDetailModel {
  final String id;
  final String title;
  final List<FormSectionModel> sections;
  final Map<String, dynamic> rawSchema;

  const TemplateDetailModel({
    required this.id,
    required this.title,
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
      basicsFields.add(FormFieldModel(key: 'basics.name', label: 'Full Name', type: 'text'));
      basicsFields.add(FormFieldModel(key: 'basics.email', label: 'Email', type: 'text'));
      basicsFields.add(FormFieldModel(key: 'basics.phone', label: 'Phone', type: 'text'));
      basicsFields.add(FormFieldModel(key: 'basics.label', label: 'Job Title', type: 'text'));
      basicsFields.add(FormFieldModel(key: 'basics.summary', label: 'Summary', type: 'textarea'));

      sectionsList.add(FormSectionModel(
        title: 'Personal Information',
        key: 'basics',
        type: SectionType.single,
        aiActions: const [],
        fields: basicsFields,
      ));

      // Work / Experience
      sectionsList.add(FormSectionModel(
        title: 'Work Experience',
        key: 'experience',
        type: SectionType.repeatable,
        aiActions: const [],
        fields: [
          FormFieldModel(
            key: 'experience',
            label: 'Experience',
            type: 'list_object',
            objectFields: const [
              FormObjectFieldModel(key: 'title', label: 'Job Title'),
              FormObjectFieldModel(key: 'company', label: 'Company'),
              FormObjectFieldModel(key: 'startDate', label: 'Start Date'),
              FormObjectFieldModel(key: 'endDate', label: 'End Date'),
              FormObjectFieldModel(key: 'summary', label: 'Description'),
            ],
          ),
        ],
      ));

      // Skills
      sectionsList.add(FormSectionModel(
        title: 'Skills',
        key: 'skills',
        type: SectionType.single,
        aiActions: const [],
        fields: [FormFieldModel(key: 'skills', label: 'Skills', type: 'list')],
      ));

      // Education
      sectionsList.add(FormSectionModel(
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
      ));
    }

    return TemplateDetailModel(
      id: json['id'].toString(),
      title: json['title'] as String? ?? 'Template',
      sections: sectionsList,
      rawSchema: schema,
    );
  }
}

class FormSectionModel {
  final String title;
  final String key;
  final SectionType type;
  final List<String> aiActions;
  final List<FormFieldModel> fields;

  const FormSectionModel({
    required this.title,
    required this.key,
    required this.type,
    required this.aiActions,
    required this.fields,
  });

  factory FormSectionModel.fromJson(Map<String, dynamic> json) {
    final rawFields = (json['fields'] as List?) ?? const [];
    final rawAiActions = (json['ai_actions'] as List?) ?? (json['ai'] as List?) ?? const [];

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
    );
  }
}

class FormFieldModel {
  final String key;
  final String label;
  final String type; // e.g. text, textarea, list_object, etc.
  final bool required;
  final List<String> options;
  final List<String> aiActions;
  final String? help;
  final List<FormObjectFieldModel> objectFields;

  const FormFieldModel({
    required this.key,
    required this.label,
    required this.type,
    this.required = false,
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
    final rawAiActions = (json['ai_actions'] as List?) ?? (json['ai'] as List?) ?? const [];
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
      options: rawOptions.map((value) => value.toString()).toList(),
      aiActions: rawAiActions.map((value) => value.toString()).toList(),
      help: json['help'] as String?,
      objectFields: parsedObjectFields,
    );
  }
}

class FormObjectFieldModel {
  final String key;
  final String label;

  const FormObjectFieldModel({required this.key, required this.label});

  factory FormObjectFieldModel.fromJson(Map<String, dynamic> json) {
    return FormObjectFieldModel(
      key: json['key'] as String? ?? '',
      label: json['label'] as String? ?? 'Value',
    );
  }
}
