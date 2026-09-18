/// AI Course Recommendation model from backend
class AICourse {
  final String id;
  final String title;
  final String channel;
  final String videoId;
  final String? playlistId;
  final String thumbnail;
  final String? duration;
  final int videoCount;
  final double matchScore;
  final String createdAt;

  AICourse({
    required this.id,
    required this.title,
    required this.channel,
    required this.videoId,
    this.playlistId,
    required this.thumbnail,
    this.duration,
    required this.videoCount,
    required this.matchScore,
    required this.createdAt,
  });

  factory AICourse.fromJson(Map<String, dynamic> json) => AICourse(
    id: json['id']?.toString() ?? json['playlist_id']?.toString() ?? '',
    title: json['title'] ?? '',
    channel: json['channel'] ?? '',
    videoId: json['video_id'] ?? '',
    playlistId: json['playlist_id'],
    thumbnail: json['thumbnail'] ?? '',
    duration: json['duration'],
    videoCount: (json['video_count'] ?? 0) as int,
    matchScore: (json['match_score'] ?? 0).toDouble(),
    createdAt: json['created_at'] ?? DateTime.now().toIso8601String(),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'channel': channel,
    'video_id': videoId,
    'playlist_id': playlistId,
    'thumbnail': thumbnail,
    'duration': duration,
    'video_count': videoCount,
    'match_score': matchScore,
    'created_at': createdAt,
  };

  AICourse copyWith({
    String? id,
    String? title,
    String? channel,
    String? videoId,
    String? thumbnail,
    String? duration,
    int? videoCount,
    double? matchScore,
    String? createdAt,
  }) {
    return AICourse(
      id: id ?? this.id,
      title: title ?? this.title,
      channel: channel ?? this.channel,
      videoId: videoId ?? this.videoId,
      playlistId: playlistId,
      thumbnail: thumbnail ?? this.thumbnail,
      duration: duration ?? this.duration,
      videoCount: videoCount ?? this.videoCount,
      matchScore: matchScore ?? this.matchScore,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

/// Course Progress model
class CourseProgress {
  final String? id;
  final String videoId;
  final int watchedSeconds;
  final int totalSeconds;
  final double watchPercentage;
  final String? lastUpdated;

  CourseProgress({
    this.id,
    required this.videoId,
    required this.watchedSeconds,
    required this.totalSeconds,
    required this.watchPercentage,
    this.lastUpdated,
  });

  factory CourseProgress.fromJson(Map<String, dynamic> json) => CourseProgress(
    id: json['id']?.toString(),
    videoId: json['video_id']?.toString() ?? '',
    watchedSeconds: (json['watched_seconds'] as num?)?.toInt() ?? 0,
    totalSeconds: (json['total_seconds'] as num?)?.toInt() ?? 0,
    watchPercentage: (json['watch_percentage'] as num?)?.toDouble() ?? 0,
    lastUpdated: json['last_updated']?.toString(),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'video_id': videoId,
    'watched_seconds': watchedSeconds,
    'total_seconds': totalSeconds,
    'watch_percentage': watchPercentage,
    'last_updated': lastUpdated,
  };

  bool get isCompleted => watchPercentage >= 95.0;

  bool get hasStarted => watchedSeconds > 0;

  CourseProgress copyWith({
    String? id,
    String? videoId,
    int? watchedSeconds,
    int? totalSeconds,
    double? watchPercentage,
    String? lastUpdated,
  }) {
    return CourseProgress(
      id: id ?? this.id,
      videoId: videoId ?? this.videoId,
      watchedSeconds: watchedSeconds ?? this.watchedSeconds,
      totalSeconds: totalSeconds ?? this.totalSeconds,
      watchPercentage: watchPercentage ?? this.watchPercentage,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}

/// Request model for course recommendations
class CourseRecommendationRequest {
  final List<String> skills;

  CourseRecommendationRequest({required this.skills});

  Map<String, dynamic> toJson() => {'skills': skills};
}
