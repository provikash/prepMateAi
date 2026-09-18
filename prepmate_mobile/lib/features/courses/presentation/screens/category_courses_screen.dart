import 'package:flutter/material.dart';

import '../../../../config/theme.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/app_state.dart';
import '../../data/models/course_model.dart';
import '../widgets/course_card.dart';

class CategoryCoursesScreen extends StatelessWidget {
  const CategoryCoursesScreen({
    super.key,
    required this.categoryTitle,
    required this.courses,
    required this.onCourseTap,
  });

  final String categoryTitle;
  final List<Course> courses;
  final ValueChanged<Course> onCourseTap;

  @override
  Widget build(BuildContext context) => AppScaffold(
    title: categoryTitle,
    padding: EdgeInsets.zero,
    body: courses.isEmpty
        ? const AppEmptyState(
            icon: Icons.school_outlined,
            title: 'No courses found',
            message: 'New learning recommendations will appear here.',
          )
        : GridView.builder(
            padding: const EdgeInsets.all(AppSpacing.screen),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 260,
              childAspectRatio: 0.75,
              crossAxisSpacing: AppSpacing.md,
              mainAxisSpacing: AppSpacing.md,
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
