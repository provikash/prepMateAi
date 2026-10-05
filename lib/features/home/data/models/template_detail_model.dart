class TemplateDetailModel {
  final String id;
  final String title;
  final String category;
  final String? thumbnailUrl;
  final String htmlStructure;
  final String css;
  final Map<String, dynamic> metadata;

  TemplateDetailModel({
    required this.id,
    required this.title,
    required this.category,
    required this.thumbnailUrl,
    required this.htmlStructure,
    required this.css,
    required this.metadata,
  });

  factory TemplateDetailModel.fromJson(Map<String, dynamic> json) {
    return TemplateDetailModel(
      id: json['id'].toString(),
      title: json['title'] as String? ?? 'Template',
      category: json['category'] as String? ?? 'General',
      thumbnailUrl: json['thumbnail_url'] as String?,
      htmlStructure: json['html_structure'] as String? ?? '',
      css: json['css'] as String? ?? '',
      metadata:
          (json['metadata'] as Map<String, dynamic>?) ?? <String, dynamic>{},
    );
  }
}
