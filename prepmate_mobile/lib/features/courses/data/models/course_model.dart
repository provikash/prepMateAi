enum CourseType {
  youtubeVideo,
  playlist,
  drive,
  pdf,
  link;

  static CourseType fromString(String value) {
    switch (value) {
      case 'youtubeVideo':
        return CourseType.youtubeVideo;
      case 'playlist':
        return CourseType.playlist;
      case 'drive':
        return CourseType.drive;
      case 'pdf':
        return CourseType.pdf;
      default:
        return CourseType.link;
    }
  }

  String toJson() => name;
}

class Course {
  final String id;
  final String title;
  final String thumbnail;
  final String duration;
  final int lessonsCount;
  final double rating;
  final int? reviewCount;
  final CourseType type;
  final String url;
  final bool isOpened;
  final String? lessonInfo;
  final int? progressPercentage;
  final String? remainingTime;

  Course({
    required this.id,
    required this.title,
    required this.thumbnail,
    required this.duration,
    required this.lessonsCount,
    required this.rating,
    this.reviewCount,
    required this.type,
    required this.url,
    this.isOpened = false,
    this.lessonInfo,
    this.progressPercentage,
    this.remainingTime,
  });

  factory Course.fromJson(Map<String, dynamic> json) {
    return Course(
      id: json['id']?.toString() ?? '',
      title: json['title'] ?? '',
      thumbnail: json['thumbnail'] ?? '',
      duration: json['duration'] ?? '',
      lessonsCount: json['lessons_count'] ?? 0,
      rating: (json['rating'] ?? 0.0).toDouble(),
      reviewCount: json['review_count'],
      type: CourseType.fromString(json['type'] ?? ''),
      url: json['url'] ?? '',
      isOpened: json['is_opened'] ?? false,
      lessonInfo: json['lesson_info'],
      progressPercentage: json['progress_percentage'],
      remainingTime: json['remaining_time'],
    );
  }

  Course copyWith({bool? isOpened}) {
    return Course(
      id: id,
      title: title,
      thumbnail: thumbnail,
      duration: duration,
      lessonsCount: lessonsCount,
      rating: rating,
      reviewCount: reviewCount,
      type: type,
      url: url,
      isOpened: isOpened ?? this.isOpened,
      lessonInfo: lessonInfo,
      progressPercentage: progressPercentage,
      remainingTime: remainingTime,
    );
  }
}

class CourseCategoryResponse {
  final List<Course> continueLearning;
  final List<Course> careerGrowth;
  final List<Course> technicalSkills;
  final List<Course> softSkills;

  CourseCategoryResponse({
    required this.continueLearning,
    required this.careerGrowth,
    required this.technicalSkills,
    required this.softSkills,
  });

  factory CourseCategoryResponse.fromJson(Map<String, dynamic> json) {
    return CourseCategoryResponse(
      continueLearning: (json['continue_learning'] as List?)
              ?.map((e) => Course.fromJson(e))
              .toList() ??
          [],
      careerGrowth: (json['career_growth'] as List?)
              ?.map((e) => Course.fromJson(e))
              .toList() ??
          [],
      technicalSkills: (json['technical_skills'] as List?)
              ?.map((e) => Course.fromJson(e))
              .toList() ??
          [],
      softSkills: (json['soft_skills'] as List?)
              ?.map((e) => Course.fromJson(e))
              .toList() ??
          [],
    );
  }
}
