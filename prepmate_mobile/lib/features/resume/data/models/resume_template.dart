class ResumeTemplate {
  final String id;
  final String name;
  final String thumbnailUrl;

  ResumeTemplate({
    required this.id,
    required this.name,
    required this.thumbnailUrl,
  });

  factory ResumeTemplate.fromJson(Map<String, dynamic> json) {
    return ResumeTemplate(
      id: json["id"].toString(),
      name: json["name"] ?? 'Untitled Resume',
      thumbnailUrl: json["thumbnailUrl"],
    );
  }
}

// class TemplateModel {
//   final String name;
//   final String subtitles;
//   final String image;
//   final String type;
//   final String value;
//
//   TemplateModel({
//     required this.name,
//     required this.subtitles,
//     required this.image,
//     required this.value,
//     required this.type,
//   });
// }

// final templatesList = [
//   TemplateModel(
//     name: "The Professional",
//     value: "modern",
//     subtitles: "Ideal for corporate & management roles",
//     image: "assets/images/template1.png",
//     type: "modern",
//   ),
//   TemplateModel(
//     name: "Tech Savvy",
//     value: "classic",
//     subtitles: "Optimized for engineering and IT",
//     image: "assets/images/template2.png",
//     type: "modern",
//   ),
//   TemplateModel(
//     name: "Pure Minimal",
//     value: "minimal",
//     subtitles: "Focus on content and achievements",
//     image: "assets/images/template3.png",
//     type: "minimal",
//   ),
// ];
