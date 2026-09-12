class ResumeDetailModel {
  final String id;
  final String title;
  final String? pdfUrl;
  final String? thumbnailUrl;
  final Map<String, dynamic> data;
  final String? templateId;

  ResumeDetailModel({
    required this.id,
    required this.title,
    required this.pdfUrl,
    required this.thumbnailUrl,
    required this.data,
    required this.templateId,
  });

  factory ResumeDetailModel.fromJson(Map<String, dynamic> json) {
    return ResumeDetailModel(
      id: json['id'].toString(),
      title: json['title'] as String? ?? 'Untitled Resume',
      pdfUrl: json['pdf_url'] as String?,
      thumbnailUrl: json['thumbnail_url'] as String?,
      data: (json['data'] as Map<String, dynamic>?) ?? <String, dynamic>{},
      templateId: json['template']?.toString(),
    );
  }
}
