import 'package:dio/dio.dart';
import '../../domain/repositories/course_repository.dart';
import '../models/course_model.dart';

class CourseRepositoryImpl implements CourseRepository {
  final Dio _dio;

  CourseRepositoryImpl(this._dio);

  @override
  Future<CourseCategoryResponse> getCourses() async {
    try {
      // In a real app, this would be: final response = await _dio.get('courses/');
      return _getMockData();
    } catch (e) {
      return _getMockData();
    }
  }

  // REUSABLE HELPER: Use this to add more courses easily
  Course _createCourse({
    required String id,
    required String title,
    required String thumb,
    required String url,
    CourseType type = CourseType.youtubeVideo,
    String duration = '2h 30m',
    int count = 12,
    double rating = 4.8,
  }) {
    return Course(
      id: id,
      title: title,
      thumbnail: thumb,
      duration: duration,
      lessonsCount: count,
      rating: rating,
      reviewCount: (rating * 200).toInt(),
      type: type,
      url: url,
    );
  }

  CourseCategoryResponse _getMockData() {
    return CourseCategoryResponse(
      continueLearning: [
        _createCourse(
          id: '1',
          title: 'Python for Automation',
          thumb: 'https://images.unsplash.com/photo-1526374965328-7f61d4dc18c5',
          url: 'https://www.youtube.com/watch?v=rfscVS0vtbw',
          duration: '5h 20m',
          count: 32,
        ).copyWith(
          lessonInfo: 'Lesson 4 • Functions',
          progress: 66,
          remainingTime: "3h 10m left", progressPercentage:55,
        ),
      ],
      careerGrowth: [
        _createCourse(id: 'cg1', title: 'Resume Mastery', thumb: 'https://images.unsplash.com/photo-1586281380349-632531db7ed4', url: 'https://www.youtube.com/playlist?list=PLBIn1_S4I_f9G3v17H8jD8S6pBf_8A8z7', type: CourseType.playlist),
        _createCourse(id: 'cg2', title: 'LinkedIn Networking', thumb: 'https://images.unsplash.com/photo-1616469829581-73993eb86b02', url: 'https://www.youtube.com/watch?v=y8Yv38WzG9A'),
        _createCourse(id: 'cg3', title: 'Interview Body Language', thumb: 'https://images.unsplash.com/photo-1573497019940-1c28c88b4f3e', url: 'https://www.youtube.com/watch?v=PCp2i2JZF1Y'),
        _createCourse(id: 'cg4', title: 'Salary Negotiation', thumb: 'https://images.unsplash.com/photo-1454165833767-027ffea9e77b', url: 'https://www.youtube.com/watch?v=XY5SeCl_8NE'),
        _createCourse(id: 'cg5', title: 'Portfolio Building', thumb: 'https://images.unsplash.com/photo-1507238691740-187a5b1d37b8', url: 'https://www.youtube.com/watch?v=hZlowLIn3vY'),
      ],
      technicalSkills: [
        _createCourse(id: 'ts1', title: 'Frontend React Basics', thumb: 'https://images.unsplash.com/photo-1633356122544-f134324a6cee', url: 'https://www.youtube.com/watch?v=bMknfKXIFA8'),
        _createCourse(id: 'ts2', title: 'Backend with Node.js', thumb: 'https://images.unsplash.com/photo-1504639725590-34d0984388bd', url: 'https://www.youtube.com/watch?v=TlB_eWDSMt4'),
        _createCourse(id: 'ts3', title: 'Data Science Intro', thumb: 'https://images.unsplash.com/photo-1551288049-bebda4e38f71', url: 'https://www.youtube.com/watch?v=ua-CiDNNj30'),
        _createCourse(id: 'ts4', title: 'Mobile App Dev (Flutter)', thumb: 'https://images.unsplash.com/photo-1512941937669-90a1b58e7e9c', url: 'https://www.youtube.com/watch?v=uK7_y9_oFNo'),
        _createCourse(id: 'ts5', title: 'Clean Code Principles', thumb: 'https://images.unsplash.com/photo-1515879218367-8466d910aaa4', url: 'https://www.youtube.com/watch?v=7EmboKQH8lE'),
      ],
      softSkills: [
        _createCourse(id: 'ss1', title: 'Public Speaking', thumb: 'https://images.unsplash.com/photo-1475721027187-402ad2989a38', url: 'https://www.youtube.com/watch?v=i5mYphUoOCs'),
        _createCourse(id: 'ss2', title: 'Conflict Resolution', thumb: 'https://images.unsplash.com/photo-1521791136064-7986c2959210', url: 'https://www.youtube.com/watch?v=FjS6Y1G_o-I', type: CourseType.playlist),
        _createCourse(id: 'ss3', title: 'Time Management', thumb: 'https://images.unsplash.com/photo-1434030216411-0b793f4b4173', url: 'https://www.youtube.com/watch?v=iONDebHX9qk', type: CourseType.pdf, count: 25),
        _createCourse(id: 'ss4', title: 'Emotional Intelligence', thumb: 'https://images.unsplash.com/photo-1516321318423-f06f85e504b3', url: 'https://www.youtube.com/watch?v=LgUCyWhJf6s'),
        _createCourse(id: 'ss5', title: 'Leadership Basics', thumb: 'https://images.unsplash.com/photo-1519085360753-af0119f7cbe7', url: 'https://www.youtube.com/watch?v=7XAeLSN1yOk'),
      ],
    );
  }
}
