class CreatedResumeModel {
  final String id;
  final String title;

  const CreatedResumeModel({required this.id, required this.title});

  factory CreatedResumeModel.fromJson(Map<String, dynamic> json) {
    return CreatedResumeModel(
      id: json['id'].toString(),
      title: json['title'] as String? ?? 'Resume',
    );
  }
}
