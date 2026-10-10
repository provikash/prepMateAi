import '../../home/data/models/template_model.dart';
import 'models/template_detail_model.dart';

const _builtInDefinitions = <Map<String, dynamic>>[
  {
    'id': 'offline-professional',
    'title': 'Professional',
    'category': 'Professional',
    'version': 1,
    'thumbnail_url': '',
  },
  {
    'id': 'offline-modern',
    'title': 'Modern',
    'category': 'Modern',
    'version': 1,
    'thumbnail_url': '',
  },
  {
    'id': 'offline-simple',
    'title': 'Simple',
    'category': 'ATS Friendly',
    'version': 1,
    'thumbnail_url': '',
  },
];

List<TemplateModel> get builtInTemplates =>
    _builtInDefinitions.map(TemplateModel.fromJson).toList(growable: false);

TemplateDetailModel? builtInTemplateDetail(String id) {
  for (final definition in _builtInDefinitions) {
    if (definition['id'] == id) {
      return TemplateDetailModel.fromJson(definition);
    }
  }
  return null;
}

List<TemplateModel> mergeBuiltInTemplates(List<TemplateModel> remote) {
  final merged = <String, TemplateModel>{
    for (final template in builtInTemplates) template.id: template,
    for (final template in remote) template.id: template,
  };
  return merged.values.toList(growable: false);
}
