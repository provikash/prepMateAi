import 'package:json_annotation/json_annotation.dart';

part 'ai_course_model.g.dart';

/// AI Course Recommendation model from backend
@JsonSerializable()
class AICourse {
  final String id;
  final String title;
  final String channel;
  @JsonKey(name: 'video_id')
  final String videoId;
  final String thumbnail;
  final String? duration;
  @JsonKey(name: 'video_count')
  final int videoCount;
  @JsonKey(name: 'match_score')
  final double matchScore;
  @JsonKey(name: 'created_at')
  final String createdAt;

  AICourse({
    required this.id,
    required this.title,
    required this.channel,
    required this.videoId,
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
      thumbnail: thumbnail ?? this.thumbnail,
      duration: duration ?? this.duration,
      videoCount: videoCount ?? this.videoCount,
      matchScore: matchScore ?? this.matchScore,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

/// Course Progress model
@JsonSerializable()
class CourseProgress {
  final String? id;
  @JsonKey(name: 'video_id')
  final String videoId;
  @JsonKey(name: 'watched_seconds')
  final int watchedSeconds;
  @JsonKey(name: 'total_seconds')
  final int totalSeconds;
  @JsonKey(name: 'watch_percentage')
  final double watchPercentage;
  @JsonKey(name: 'last_updated')
  final String? lastUpdated;

  CourseProgress({
    this.id,
    required this.videoId,
    required this.watchedSeconds,
    required this.totalSeconds,
    required this.watchPercentage,
    this.lastUpdated,
  });

  factory CourseProgress.fromJson(Map<String, dynamic> json) =>
      _$CourseProgressFromJson(json);

  Map<String, dynamic> toJson() => _$CourseProgressToJson(this);

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

  Map<String, dynamic> toJson() => {
    'skills': skills,
  };
}
