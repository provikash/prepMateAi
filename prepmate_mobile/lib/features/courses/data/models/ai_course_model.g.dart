// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ai_course_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AICourse _$AICourseFromJson(Map<String, dynamic> json) => AICourse(
  id: json['id'] as String,
  title: json['title'] as String,
  channel: json['channel'] as String,
  videoId: json['video_id'] as String,
  thumbnail: json['thumbnail'] as String,
  duration: json['duration'] as String?,
  videoCount: (json['video_count'] as num).toInt(),
  matchScore: (json['match_score'] as num).toDouble(),
  createdAt: json['created_at'] as String,
);

Map<String, dynamic> _$AICourseToJson(AICourse instance) => <String, dynamic>{
  'id': instance.id,
  'title': instance.title,
  'channel': instance.channel,
  'video_id': instance.videoId,
  'thumbnail': instance.thumbnail,
  'duration': instance.duration,
  'video_count': instance.videoCount,
  'match_score': instance.matchScore,
  'created_at': instance.createdAt,
};

CourseProgress _$CourseProgressFromJson(Map<String, dynamic> json) =>
    CourseProgress(
      id: json['id'] as String?,
      videoId: json['video_id'] as String,
      watchedSeconds: (json['watched_seconds'] as num).toInt(),
      totalSeconds: (json['total_seconds'] as num).toInt(),
      watchPercentage: (json['watch_percentage'] as num).toDouble(),
      lastUpdated: json['last_updated'] as String?,
    );

Map<String, dynamic> _$CourseProgressToJson(CourseProgress instance) =>
    <String, dynamic>{
      'id': instance.id,
      'video_id': instance.videoId,
      'watched_seconds': instance.watchedSeconds,
      'total_seconds': instance.totalSeconds,
      'watch_percentage': instance.watchPercentage,
      'last_updated': instance.lastUpdated,
    };
