class Recommendation {
  final String title;
  final String channel;
  final String videoId;
  final String thumbnail;
  final int videoCount;
  final int matchScore;
  final String? description;

  Recommendation({
    required this.title,
    required this.channel,
    required this.videoId,
    required this.thumbnail,
    required this.videoCount,
    required this.matchScore,
    this.description,
  });

  factory Recommendation.fromJson(Map<String, dynamic> json) {
    return Recommendation(
      title: json['title'] ?? '',
      channel: json['channel'] ?? '',
      videoId: json['video_id'] ?? '',
      thumbnail: json['thumbnail'] ?? '',
      videoCount: json['video_count'] ?? 0,
      matchScore: json['match_score'] ?? 0,
      description: json['description'],
    );
  }
}

class CourseProgress {
  final String videoId;
  final int watchedSeconds;
  final int totalSeconds;

  CourseProgress({
    required this.videoId,
    required this.watchedSeconds,
    required this.totalSeconds,
  });

  factory CourseProgress.fromJson(Map<String, dynamic> json) {
    return CourseProgress(
      videoId: json['video_id'] ?? '',
      watchedSeconds: json['watched_seconds'] ?? 0,
      totalSeconds: json['total_seconds'] ?? 0,
    );
  }
}
