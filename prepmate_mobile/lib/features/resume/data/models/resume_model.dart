class ResumeModel {
  final String id;
  final String title;
  final String? pdfUrl;

  const ResumeModel({
    required this.id,
    required this.title,
    required this.pdfUrl,
  });

  factory ResumeModel.fromJson(Map<String, dynamic> json) {
    return ResumeModel(
      id: json['id'].toString(),
      title: json['title'] as String? ?? 'Untitled Resume',
      pdfUrl: json['pdf_url'] as String?,
    );
  }
}
