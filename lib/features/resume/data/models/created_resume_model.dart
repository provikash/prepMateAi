class CreatedResumeModel {
  final String id;
  final String title;
  final int revision;
  final bool queued;

  const CreatedResumeModel({
    required this.id,
    required this.title,
    this.revision = 0,
    this.queued = false,
  });

  factory CreatedResumeModel.fromJson(Map<String, dynamic> json) {
    return CreatedResumeModel(
      id: json['id'].toString(),
      title: json['title'] as String? ?? 'Resume',
      revision: (json['revision'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'revision': revision,
    'queued': queued,
  };
}
