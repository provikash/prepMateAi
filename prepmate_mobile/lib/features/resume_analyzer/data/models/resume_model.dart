class ResumeModel {
  final String id;
  final String title;
  final String? pdfUrl;

  ResumeModel({
    required this.id,
    required this.title,
    this.pdfUrl,
  });

  factory ResumeModel.fromJson(Map<String, dynamic> json) {
    return ResumeModel(
      id: json['id'].toString(),
      title: json['title'] ?? '',
      pdfUrl: json['pdf_url'],
    );
  }
}
