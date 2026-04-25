import 'package:dio/dio.dart';
import '../../domain/repositories/course_repository.dart';
import '../models/course_model.dart';

class CourseRepositoryImpl implements CourseRepository {
  final Dio _dio;

  CourseRepositoryImpl(this._dio);

  @override
  Future<CourseCategoryResponse> getCourses() async {
    try {
      final response = await _dio.get('courses/');
      return CourseCategoryResponse.fromJson(response.data);
    } catch (e) {
      // For demo/offline purposes, returning mock data if API fails
      return _getMockData();
    }
  }

  CourseCategoryResponse _getMockData() {
    final pythonCourse = Course(
      id: '1',
      title: 'Python for Automation',
      thumbnail: 'https://images.unsplash.com/photo-1526374965328-7f61d4dc18c5',
      duration: '5h 20m',
      lessonsCount: 32,
      rating: 4.8,
      reviewCount: 2100,
      type: CourseType.youtubeVideo,
      url: 'https://www.youtube.com/watch?v=rfscVS0vtbw',
      lessonInfo: 'Lesson 4 • Functions in Python',
      progressPercentage: 66,
      remainingTime: '3h 10m left',
    );

    final resumeMastery = Course(
      id: '2',
      title: 'Resume Mastery',
      thumbnail: 'https://images.unsplash.com/photo-1586281380349-632531db7ed4',
      duration: '2h 15m',
      lessonsCount: 24,
      rating: 4.9,
      reviewCount: 1200,
      type: CourseType.playlist,
      url: 'https://www.youtube.com/playlist?list=PLBIn1_S4I_f9G3v17H8jD8S6pBf_8A8z7',
    );

    return CourseCategoryResponse(
      continueLearning: [pythonCourse],
      careerGrowth: [
        resumeMastery,
        Course(
          id: '3',
          title: 'LinkedIn Networking',
          thumbnail: 'https://images.unsplash.com/photo-1616469829581-73993eb86b02',
          duration: '1h 45m',
          lessonsCount: 18,
          rating: 4.7,
          reviewCount: 986,
          type: CourseType.playlist,
          url: 'https://www.youtube.com',
        ),
      ],
      technicalSkills: [
        Course(
          id: '4',
          title: 'Frontend React Basics',
          thumbnail: 'https://images.unsplash.com/photo-1633356122544-f134324a6cee',
          duration: '5h 20m',
          lessonsCount: 32,
          rating: 4.8,
          reviewCount: 2100,
          type: CourseType.youtubeVideo,
          url: 'https://www.youtube.com',
        ),
        pythonCourse.copyWith(),
      ],
      softSkills: [
        Course(
          id: '5',
          title: 'Public Speaking',
          thumbnail: 'https://images.unsplash.com/photo-1475721027187-402ad2989a38',
          duration: '1h 30m',
          lessonsCount: 12,
          rating: 4.9,
          reviewCount: 764,
          type: CourseType.youtubeVideo,
          url: 'https://www.youtube.com',
        ),
        Course(
          id: '6',
          title: 'Conflict Resolution',
          thumbnail: 'https://images.unsplash.com/photo-1521791136064-7986c2959210',
          duration: '2h 45m',
          lessonsCount: 15,
          rating: 4.5,
          reviewCount: 532,
          type: CourseType.playlist,
          url: 'https://www.youtube.com',
        ),
      ],
    );
  }
}
