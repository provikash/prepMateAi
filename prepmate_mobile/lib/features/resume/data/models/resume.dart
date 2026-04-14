class Resume {
  final int id; // Using int based on your deleteResume(int id) method
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

  // Factory method to parse the JSON coming from your Django API
  factory Resume.fromJson(Map<String, dynamic> json) {
    return Resume(
      id: json['id'] as int,
      title: json['title'] as String,
      // Default to empty list if canvas_data is null from backend
      canvasData: json['canvas_data'] as List<dynamic>? ?? [],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
    );
  }

  // Method to send data back to Django
  Map<String, dynamic> toJson() {
    return {'id': id, 'title': title, 'canvas_data': canvasData};
  }
}
