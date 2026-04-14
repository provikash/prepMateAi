// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import '../../../features/home/providers/home_providers.dart';
//
// class UserProfileWidget extends ConsumerWidget {
//   const UserProfileWidget({Key? key}) : super(key: key);
//
//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     // Watch the provider
//     final userDataAsync = ref.watch(userDataProvider);
//
//     return userDataAsync.when(
//       data: (user) => Column(
//         children: [
//           Text('Name: ${user['first_name']} ${user['last_name']}'),
//           Text('Email: ${user['email']}'),
//         ],
//       ),
//       loading: () => const CircularProgressIndicator(),
//       error: (error, stack) => Text('Error loading profile: $error'),
//     );
//   }
// }
