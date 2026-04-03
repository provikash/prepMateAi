class Resume {
  final int id;
  final String title;
  final String template;
  final Map content;

  Resume({
    required this.id,
    required this.title,
    required this.template,
    required this.content,
  });

  factory Resume.fromJson(Map json) {
    return Resume(
      id: json["id"],
      title: json["title"],
      template: json["template"],
      content: json["content"],
    );
  }
}

class TemplateModel{
  final String name;
  final String subtitles;
  final String image;
  final String type;

  TemplateModel({
    required this.name,
    required this.subtitles,
    required this.image,
    required this.type

});
}

final templatesList = [
  TemplateModel(
    name: "The Professional",
    subtitles: "Ideal for corporate & management roles",
    image: "assets/images/template1.png",
    type: "modern",
  ),
  TemplateModel(
    name: "Tech Savvy",
    subtitles: "Optimized for engineering and IT",
    image: "assets/images/template2.png",
    type: "modern",
  ),
  TemplateModel(
    name: "Pure Minimal",
    subtitles: "Focus on content and achievements",
    image: "assets/images/template3.png",
    type: "minimal",
  ),
];