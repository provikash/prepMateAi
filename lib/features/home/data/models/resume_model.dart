class ResumeModel {
  final String id;
  final String title;
  final String thumbnailUrl;
  final String pdfUrl;
  final String syncStatus;
  final String? templateId;
  final Map<String, dynamic> data;
  final DateTime? updatedAt;
  final bool isCompleted;

  ResumeModel({
    required this.id,
    required this.title,
    required this.thumbnailUrl,
    required this.pdfUrl,
    this.syncStatus = 'synced',
    this.templateId,
    this.data = const {},
    this.updatedAt,
    this.isCompleted = false,
  });

  factory ResumeModel.fromJson(Map<String, dynamic> json) {
    final pdf = json['pdf_url'] as String? ?? json['pdfUrl'] as String? ?? '';
    final updated = json['updated_at'] != null
        ? DateTime.tryParse(json['updated_at'].toString())
        : null;

    return ResumeModel(
      id: json['id'].toString(),
      title: json['title'] as String? ?? 'Untitled Resume',
      thumbnailUrl:
          json['thumbnail_url'] as String? ??
          json['thumbnailUrl'] as String? ??
          '',
      pdfUrl: pdf,
      syncStatus: json['sync_status'] as String? ?? 'synced',
      templateId:
          json['template_id']?.toString() ?? json['template']?.toString(),
      data: json['data'] is Map
          ? Map<String, dynamic>.from(json['data'] as Map)
          : const {},
      updatedAt: updated,
      isCompleted: pdf.isNotEmpty || json['is_completed'] == true,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'thumbnail_url': thumbnailUrl,
    'pdf_url': pdfUrl,
    'sync_status': syncStatus,
    'template_id': templateId,
    'data': data,
    'updated_at': updatedAt?.toIso8601String(),
    'is_completed': isCompleted,
  };
}
