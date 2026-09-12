class TemplateModel {
  final String id;
  final String title;
  final String category;
  final String thumbnailUrl;

  TemplateModel({
    required this.id,
    required this.title,
    required this.category,
    required this.thumbnailUrl,
  });

  factory TemplateModel.fromJson(Map<String, dynamic> json) {
    return TemplateModel(
      id: json['id'].toString(),
      title: json['title'] as String? ?? 'Modern Template',
      category: json['category'] as String? ?? 'Professional',
      thumbnailUrl: json['thumbnail_url'] ?? '',
    );
  }
}
