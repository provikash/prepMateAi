import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:prepmate_mobile/features/auth/screens/otpVerification_screen.dart';
import 'package:prepmate_mobile/features/auth/screens/resetPassword_screen.dart';
import 'package:prepmate_mobile/features/auth/screens/signup_screen.dart';
import 'theme/theme.dart';
import 'features/auth/screens/login_screen.dart';

// GoRouter configuration
final _router = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const LoginScreen(),

    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),

    ),

    GoRoute(path: '/signup',
    builder: (context,state) => const ResetPasswordScreen())
  ],
);

void main() {
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'PrepMate',
      theme: appTheme(),
      routerConfig: _router,
    );
  }
}
