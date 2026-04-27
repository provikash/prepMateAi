class TemplateDetailModel {
  final String id;
  final String title;
  final List<FormSectionModel> sections;

  const TemplateDetailModel({
    required this.id,
    required this.title,
    required this.sections,
  });

  factory TemplateDetailModel.fromJson(Map<String, dynamic> json) {
    final metadata = (json['metadata'] as Map<String, dynamic>?) ??
      <String, dynamic>{};
    final schema = (json['form_schema'] as Map<String, dynamic>?) ??
      (metadata['form_schema'] as Map<String, dynamic>?) ??
      <String, dynamic>{};
    final rawSections = (schema['sections'] as List?) ?? const [];

    return TemplateDetailModel(
      id: json['id'].toString(),
      title: json['title'] as String? ?? 'Template',
      sections: rawSections
          .whereType<Map<String, dynamic>>()
          .map(FormSectionModel.fromJson)
          .toList(),
    );
  }
}

class FormSectionModel {
  final String title;
  final List<FormFieldModel> fields;

  const FormSectionModel({required this.title, required this.fields});

  factory FormSectionModel.fromJson(Map<String, dynamic> json) {
    final rawFields = (json['fields'] as List?) ?? const [];
    return FormSectionModel(
      title: json['title'] as String? ?? 'Section',
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
  final String type;
  final List<FormObjectFieldModel> objectFields;

  const FormFieldModel({
    required this.key,
    required this.label,
    required this.type,
    this.objectFields = const [],
  });

  bool get isList => type.toLowerCase() == 'list';
  bool get isListObject => type.toLowerCase() == 'list_object';

  factory FormFieldModel.fromJson(Map<String, dynamic> json) {
    final rawObjectFields =
        (json['item_fields'] as List?) ?? (json['fields'] as List?) ?? const [];
    final type = json['type'] as String? ?? 'text';
    final parsedObjectFields = rawObjectFields
        .whereType<Map<String, dynamic>>()
        .map(FormObjectFieldModel.fromJson)
        .toList();
    if (type.toLowerCase() == 'list_object' && parsedObjectFields.isEmpty) {
      parsedObjectFields.add(const FormObjectFieldModel(key: 'value', label: 'Value'));
    }

    return FormFieldModel(
      key: json['key'] as String? ?? '',
      label: json['label'] as String? ?? '',
      type: type,
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
