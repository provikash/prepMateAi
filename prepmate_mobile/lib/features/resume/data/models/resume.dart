class Resume {
  final int id;
  final String title;
  final List<dynamic> canvasData;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Resume({
    required this.id,
    required this.title,
    required this.canvasData,
    this.createdAt,
    this.updatedAt,
  });

  factory Resume.fromJson(Map<String, dynamic> json) {
    // Safely parse ID which could come as String or Int from backend
    final dynamic rawId = json['id'];
    final int parsedId = rawId is int
        ? rawId
        : int.tryParse(rawId?.toString() ?? '0') ?? 0;

    return Resume(
      id: parsedId,
      title: json['title'] as String? ?? 'Untitled Resume',
      // The backend field might be 'canvas_data' or 'data' based on your models.py
      canvasData: (json['canvas_data'] ?? json['data']) as List<dynamic>? ?? [],
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'title': title, 'canvas_data': canvasData};
  }
}
