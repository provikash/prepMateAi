// import 'package:flutter/material.dart';
//
// class HomeScreen extends StatelessWidget {
//   const HomeScreen({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.grey.shade100,
//
//       floatingActionButton: FloatingActionButton(
//         backgroundColor: Colors.blue,
//         onPressed: () {},
//         child: const Icon(Icons.add),
//       ),
//
//       bottomNavigationBar: BottomNavigationBar(
//         currentIndex: 0,
//         selectedItemColor: Colors.blue,
//         unselectedItemColor: Colors.grey,
//         items: const [
//           BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
//           BottomNavigationBarItem(icon: Icon(Icons.chat), label: "Interview"),
//           BottomNavigationBarItem(icon: Icon(Icons.speed), label: "ATS Score"),
//           BottomNavigationBarItem(icon: Icon(Icons.school), label: "Courses"),
//           BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
//         ],
//       ),
//
//       body: SafeArea(
//         child: ListView(
//           padding: const EdgeInsets.all(20),
//           children: [
//
//             /// Header
//             Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: const [
//                 Text(
//                   "PrepMate",
//                   style: TextStyle(
//                     fontSize: 24,
//                     fontWeight: FontWeight.bold,
//                     color: Colors.blue,
//                   ),
//                 ),
//                 Row(
//                   children: [
//                     Icon(Icons.add_box_outlined),
//                     SizedBox(width: 15),
//                     Icon(Icons.notifications_none),
//                   ],
//                 )
//               ],
//             ),
//
//             const SizedBox(height: 20),
//
//             /// Greeting
//             Row(
//               children: const [
//                 CircleAvatar(radius: 28),
//                 SizedBox(width: 15),
//                 Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(
//                       "Hello, Alex!",
//                       style:
//                       TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
//                     ),
//                     Text("Your career journey continues."),
//                   ],
//                 )
//               ],
//             ),
//
//             const SizedBox(height: 25),
//
//             /// Progress Card
//             Container(
//               padding: const EdgeInsets.all(16),
//               decoration: BoxDecoration(
//                 borderRadius: BorderRadius.circular(16),
//                 color: Colors.white,
//                 boxShadow: const [
//                   BoxShadow(color: Colors.black12, blurRadius: 8)
//                 ],
//               ),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: const [
//                   Text(
//                     "Current Progress",
//                     style:
//                     TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//                   ),
//                   SizedBox(height: 15),
//                   Text(
//                     "Senior Product Designer",
//                     style:
//                     TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
//                   ),
//                   SizedBox(height: 10),
//                   LinearProgressIndicator(value: 0.8),
//                 ],
//               ),
//             ),
//
//             const SizedBox(height: 25),
//
//             /// Fresh Template Title
//             Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: const [
//                 Text(
//                   "Fresh Template",
//                   style: TextStyle(
//                       fontSize: 20, fontWeight: FontWeight.bold),
//                 ),
//                 Text(
//                   "See all",
//                   style: TextStyle(color: Colors.blue),
//                 )
//               ],
//             ),
//
//             const SizedBox(height: 15),
//
//             /// Template Cards
//             SizedBox(
//               height: 180,
//               child: ListView(
//                 scrollDirection: Axis.horizontal,
//                 children: [
//
//                   templateCard("Modern Minimalist", "Professional"),
//                   templateCard("Executive Sidebar", "Corporate"),
//                   templateCard("Creative Resume", "Design"),
//
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
//
// /// Template Card Widget
// Widget templateCard(String title, String subtitle) {
//   return Container(
//     width: 150,
//     margin: const EdgeInsets.only(right: 15),
//     padding: const EdgeInsets.all(12),
//     decoration: BoxDecoration(
//       borderRadius: BorderRadius.circular(15),
//       color: Colors.white,
//       boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6)],
//     ),
//     child: Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Expanded(
//           child: Container(
//             decoration: BoxDecoration(
//               color: Colors.grey.shade300,
//               borderRadius: BorderRadius.circular(10),
//             ),
//           ),
//         ),
//         const SizedBox(height: 10),
//         Text(
//           title,
//           style: const TextStyle(fontWeight: FontWeight.bold),
//         ),
//         Text(
//           subtitle,
//           style: const TextStyle(color: Colors.grey),
//         ),
//       ],
//     ),
//   );
// }

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,

      appBar: AppBar(
        title: const Text("PrepMate AI"),
        centerTitle: true,
      ),

      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [

              /// TITLE
              const Text(
                "Build Your Resume Easily 🚀",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 20),

              /// SUBTITLE
              const Text(
                "Create, edit and manage professional resumes",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),

              const SizedBox(height: 40),

              /// BUTTON
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.blue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  onPressed: () {
                    /// 🔥 Navigate to Resume List
                    context.push("/resumes");
                  },
                  child: const Text(
                    "Go to Resume Builder",
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
