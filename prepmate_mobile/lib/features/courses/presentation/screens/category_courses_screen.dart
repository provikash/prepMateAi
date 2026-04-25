import 'package:flutter/material.dart';
import '../../data/models/course_model.dart';
import '../widgets/course_card.dart';

class CategoryCoursesScreen extends StatelessWidget {
  final String categoryTitle;
  final List<Course> courses;
  final Function(Course) onCourseTap;

  const CategoryCoursesScreen({
    super.key,
    required this.categoryTitle,
    required this.courses,
    required this.onCourseTap,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(categoryTitle),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(20),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.75,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: courses.length,
        itemBuilder: (context, index) {
          final course = courses[index];
          return CourseCard(
            course: course,
            onTap: () => onCourseTap(course),
          );
        },
      ),
    );
  }
}
