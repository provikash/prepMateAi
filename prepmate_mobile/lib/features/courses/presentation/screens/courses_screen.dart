// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:shimmer/shimmer.dart';
// import '../providers/course_providers.dart';
// import '../screens/category_courses_screen.dart';
// import '../widgets/continue_learning_card.dart';
// import '../widgets/section_widget.dart';
// import '../../data/models/course_model.dart';

// class CoursesScreen extends ConsumerWidget {
//   const CoursesScreen({super.key});

//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     final coursesAsync = ref.watch(courseListProvider);

//     return RefreshIndicator(
//       onRefresh: () => ref.read(courseListProvider.notifier).refresh(),
//       child: CustomScrollView(
//         slivers: [
//           // Header
//           SliverPadding(
//             padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
//             sliver: SliverToBoxAdapter(
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   const Text(
//                     'Courses',
//                     style: TextStyle(
//                       fontSize: 28,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                   const SizedBox(height: 16),
//                   _buildSearchBar(),
//                 ],
//               ),
//             ),
//           ),

//           coursesAsync.when(
//             data: (data) => SliverList(
//               delegate: SliverChildListDelegate([
//                 if (data.continueLearning.isNotEmpty) ...[
//                   const Padding(
//                     padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
//                     child: Row(
//                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                       children: [
//                         Text(
//                           'Continue Learning',
//                           style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//                         ),
//                         Text('View all', style: TextStyle(color: Colors.blueAccent)),
//                       ],
//                     ),
//                   ),
//                   Padding(
//                     padding: const EdgeInsets.symmetric(horizontal: 20),
//                     child: ContinueLearningCard(
//                       course: data.continueLearning.first,
//                       onTap: () => _handleCourseTap(context, ref, data.continueLearning.first),
//                     ),
//                   ),
//                 ],
//                 const SizedBox(height: 10),
//                 SectionWidget(
//                   title: 'Career Growth',
//                   courses: data.careerGrowth,
//                   onCourseTap: (course) => _handleCourseTap(context, ref, course),
//                   onViewAll: () => _navigateToCategory(context, ref, 'Career Growth', data.careerGrowth),
//                 ),
//                 SectionWidget(
//                   title: 'Technical Skills',
//                   courses: data.technicalSkills,
//                   onCourseTap: (course) => _handleCourseTap(context, ref, course),
//                   onViewAll: () => _navigateToCategory(context, ref, 'Technical Skills', data.technicalSkills),
//                 ),
//                 SectionWidget(
//                   title: 'Soft Skills',
//                   courses: data.softSkills,
//                   onCourseTap: (course) => _handleCourseTap(context, ref, course),
//                   onViewAll: () => _navigateToCategory(context, ref, 'Soft Skills', data.softSkills),
//                 ),
//                 _buildStatsGrid(),
//                 const SizedBox(height: 100), // Increased space for bottom nav
//               ]),
//             ),
//             loading: () => const SliverFillRemaining(
//               child: CoursesSkeleton(),
//             ),
//             error: (err, stack) => SliverFillRemaining(
//               child: Center(
//                 child: Column(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     const Text('Failed to load courses'),
//                     ElevatedButton(
//                       onPressed: () => ref.read(courseListProvider.notifier).refresh(),
//                       child: const Text('Retry'),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildSearchBar() {
//     return Container(
//       decoration: BoxDecoration(
//         color: const Color(0xFFF5F6F9),
//         borderRadius: BorderRadius.circular(15),
//       ),
//       child: const TextField(
//         decoration: InputDecoration(
//           hintText: 'Search courses, topics or skills...',
//           prefixIcon: Icon(Icons.search, color: Colors.grey),
//           border: InputBorder.none,
//           contentPadding: EdgeInsets.symmetric(vertical: 15),
//         ),
//       ),
//     );
//   }

//   Widget _buildStatsGrid() {
//     return Container(
//       margin: const EdgeInsets.all(20),
//       padding: const EdgeInsets.all(20),
//       decoration: BoxDecoration(
//         border: Border.all(color: Colors.grey[200]!),
//         borderRadius: BorderRadius.circular(20),
//       ),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceAround,
//         children: [
//           _buildStatItem(Icons.play_circle_outline, '50+', 'Courses', Colors.blue),
//           _buildStatItem(Icons.access_time, '120+', 'Hours', Colors.green),
//           _buildStatItem(Icons.book_outlined, '300+', 'Lessons', Colors.orange),
//           _buildStatItem(Icons.people_outline, '10K+', 'Learners', Colors.purple),
//         ],
//       ),
//     );
//   }

//   Widget _buildStatItem(IconData icon, String count, String label, Color color) {
//     return Column(
//       children: [
//         Icon(icon, color: color, size: 28),
//         const SizedBox(height: 8),
//         Text(count, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
//         Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
//       ],
//     );
//   }

//   void _navigateToCategory(BuildContext context, WidgetRef ref, String title, List<Course> courses) {
//     Navigator.of(context).push(
//       MaterialPageRoute(
//         builder: (context) => CategoryCoursesScreen(
//           categoryTitle: title,
//           courses: courses,
//           onCourseTap: (course) => _handleCourseTap(context, ref, course),
//         ),
//       ),
//     );
//   }

//   void _handleCourseTap(BuildContext context, WidgetRef ref, Course course) async {
//     try {
//       await ref.read(courseActionProvider).openCourse(context, course);
//     } catch (e) {
//       if (context.mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Could not open course: $e')),
//         );
//       }
//     }
//   }
// }

// class CoursesSkeleton extends StatelessWidget {
//   const CoursesSkeleton({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Shimmer.fromColors(
//       baseColor: Colors.grey[300]!,
//       highlightColor: Colors.grey[100]!,
//       child: ListView.builder(
//         itemCount: 3,
//         itemBuilder: (_, __) => Padding(
//           padding: const EdgeInsets.all(20),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Container(width: 150, height: 20, color: Colors.white),
//               const SizedBox(height: 20),
//               Container(width: double.infinity, height: 150, color: Colors.white),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
