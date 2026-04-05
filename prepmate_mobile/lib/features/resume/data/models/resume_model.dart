class Resume {
  final int id;
  final String title;
  final String template;
  final Map<String, dynamic> content;

  Resume({
    required this.id,
    required this.template,
    required this.content,
    required this.title,
  });

  factory Resume.fromJson(Map<String, dynamic> json) {
    return Resume(
      id: json["id"],
      title: json["title"] ?? 'Untitled Resume',
      template: json["template"] ?? '',
      content: json["content"] is Map ? Map<String, dynamic>.from(json["content"]) : {},
    );
  }
}

class TemplateModel {
  final String name;
  final String subtitles;
  final String image;
  final String type;
  final String value;

  TemplateModel({
    required this.name,
    required this.subtitles,
    required this.image,
    required this.value,
    required this.type,
  });
}

final templatesList = [
  TemplateModel(
    name: "The Professional",
    value: "modern",
    subtitles: "Ideal for corporate & management roles",
    image: "assets/images/template1.png",
    type: "modern",
  ),
  TemplateModel(
    name: "Tech Savvy",
    value: "classic",
    subtitles: "Optimized for engineering and IT",
    image: "assets/images/template2.png",
    type: "modern",
  ),
  TemplateModel(
    name: "Pure Minimal",
    value: "minimal",
    subtitles: "Focus on content and achievements",
    image: "assets/images/template3.png",
    type: "minimal",
  ),
];
