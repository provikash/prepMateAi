class ResumeTemplate {
  final String id;
  final String name;
  final String previewImage;
  final String htmlStructure;
  final DateTime createdAt;
  final DateTime updatedAt;

  ResumeTemplate({
    required this.id,
    required this.name,
    required this.previewImage,
    required this.htmlStructure,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ResumeTemplate.fromJson(Map<String, dynamic> json) {
    return ResumeTemplate(
      id: json["id"].toString(),
      name: json["name"] ?? 'Untitled Template',
      previewImage: json["preview_image"] ?? '',
      htmlStructure: json["html_structure"] ?? '',
      createdAt: DateTime.parse(json["created_at"]),
      updatedAt: DateTime.parse(json["updated_at"]),
    );
  }
}
