import 'package:flutter/material.dart';
import '../../../../config/theme.dart';
import '../../data/models/course_model.dart';
import 'course_card.dart';

class SectionWidget extends StatelessWidget {
  final String title;
  final List<Course> courses;
  final Function(Course) onCourseTap;
  final VoidCallback onViewAll;

  const SectionWidget({
    super.key,
    required this.title,
    required this.courses,
    required this.onCourseTap,
    required this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    if (courses.isEmpty) return const SizedBox.shrink();
    final colors = AppColors.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: colors.textPrimary,
                ),
              ),
              TextButton(
                onPressed: onViewAll,
                child: Text(
                  'View all',
                  style: TextStyle(color: colors.primary),
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 280,
          child: ListView.builder(
            padding: const EdgeInsets.only(left: 20, bottom: 25),
            scrollDirection: Axis.horizontal,
            itemCount: courses.length,
            itemBuilder: (context, index) {
              return CourseCard(
                course: courses[index],
                onTap: () => onCourseTap(courses[index]),
              );
            },
          ),
        ),
      ],
    );
  }
}
