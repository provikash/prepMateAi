class ResumeModel {
  final int id;
  final String title;
  final String thumbnailUrl;
  final String pdfUrl;

  ResumeModel({
    required this.id,
    required this.title,
    required this.thumbnailUrl,
    required this.pdfUrl,
  });

  factory ResumeModel.fromJson(Map<String, dynamic> json) {
    return ResumeModel(
      id: json['id'] as int,
      title: json['title'] as String? ?? 'Untitled Resume',
      thumbnailUrl: json['thumbnail_url'] as String? ?? '',
      pdfUrl: json['pdf_url'] as String? ?? '',
    );
  }
}
