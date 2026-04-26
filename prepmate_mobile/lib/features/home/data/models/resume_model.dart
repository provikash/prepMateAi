class ResumeModel {
  final String id;
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
      id: json['id'].toString(),
      title: json['title'] as String? ?? 'Untitled Resume',
      thumbnailUrl:
          json['thumbnail_url'] as String? ??
          json['thumbnailUrl'] as String? ??
          '',
      pdfUrl: json['pdf_url'] as String? ?? json['pdfUrl'] as String? ?? '',
    );
  }
}
