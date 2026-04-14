// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
//
// import '../providers/home_providers.dart';
//
// // --- PROGRESS CARD WIDGET ---
// class ProgressCard extends ConsumerWidget {
//   const ProgressCard({Key? key}) : super(key: key);
//
//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     final userDataAsync = ref.watch(userDataProvider);
//
//     return Container(
//       padding: const EdgeInsets.all(20),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(16),
//         boxShadow: const [
//           BoxShadow(
//             color: Colors.black12,
//             blurRadius: 10,
//             offset: Offset(0, 4),
//           ),
//         ],
//       ),
//       child: userDataAsync.when(
//         data: (data) => Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 Row(
//                   children: [
//                     const Icon(Icons.trending_up, color: Colors.blue),
//                     const SizedBox(width: 8),
//                     const Text(
//                       'Current Progress',
//                       style: TextStyle(
//                         fontWeight: FontWeight.w600,
//                         fontSize: 16,
//                       ),
//                     ),
//                   ],
//                 ),
//                 Container(
//                   padding: const EdgeInsets.symmetric(
//                     horizontal: 12,
//                     vertical: 4,
//                   ),
//                   decoration: BoxDecoration(
//                     color: const Color(0xFFE3F2FD), // Light blue
//                     borderRadius: BorderRadius.circular(12),
//                   ),
//                   child: const Text(
//                     'Draft',
//                     style: TextStyle(
//                       color: Colors.blue,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 24),
//             Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 Text(
//                   data['role'],
//                   style: const TextStyle(
//                     fontSize: 18,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//                 Text(
//                   '${(data['progress'] * 100).toInt()}%',
//                   style: const TextStyle(
//                     fontSize: 18,
//                     fontWeight: FontWeight.bold,
//                     color: Colors.blue,
//                   ),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 12),
//             ClipRRect(
//               borderRadius: BorderRadius.circular(8),
//               child: LinearProgressIndicator(
//                 value: data['progress'],
//                 minHeight: 10,
//                 backgroundColor: const Color(0xFFEEEEEE),
//                 color: Colors.blue,
//               ),
//             ),
//             const SizedBox(height: 20),
//             Container(
//               padding: const EdgeInsets.all(12),
//               decoration: BoxDecoration(
//                 color: const Color(0xFFF4F8FF),
//                 borderRadius: BorderRadius.circular(12),
//               ),
//               child: Row(
//                 children: [
//                   const Icon(Icons.account_tree, color: Colors.blue),
//                   const SizedBox(width: 12),
//                   Expanded(
//                     child: Text(
//                       data['suggestion'],
//                       style: const TextStyle(color: Colors.black87),
//                     ),
//                   ),
//                   const Icon(Icons.chevron_right, color: Colors.grey),
//                 ],
//               ),
//             ),
//           ],
//         ),
//         loading: () => const Center(child: CircularProgressIndicator()),
//         error: (err, stack) => const Text('Failed to load progress'),
//       ),
//     );
//   }
// }
