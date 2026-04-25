import 'package:go_router/go_router.dart';
import 'package:prepmate_mobile/features/home/screens/home_screen.dart';
import 'package:prepmate_mobile/features/auth/screens/login_screen.dart';
import 'package:prepmate_mobile/features/auth/screens/signup_screen.dart';
import 'package:prepmate_mobile/features/auth/screens/forgetPassword_screen.dart';
import 'package:prepmate_mobile/features/auth/screens/otpVerification_screen.dart';
import 'package:prepmate_mobile/features/auth/screens/passwordChanged_screen.dart';
import 'package:prepmate_mobile/features/resume/presentation/screens/editor_screen.dart';
import 'package:prepmate_mobile/features/resume/presentation/screens/resume_list_screen.dart';
import 'package:prepmate_mobile/features/resume/presentation/screens/template_screen.dart';
import 'package:prepmate_mobile/features/splash/screens/splash_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/splash',
  routes: [
    GoRoute(path: '/splash', builder: (context, state) => const SplashScreen()),
    GoRoute(path: '/', builder: (context, state) => const PrepMateHome()),
    GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
    GoRoute(path: '/signup', builder: (context, state) => const SignupScreen()),
    GoRoute(path: '/home', builder: (context, state) => const PrepMateHome()),
    GoRoute(
      path: '/verify-otp',
      builder: (context, state) {
        final email = state.extra as String;
        return OtpVerificationScreen(email: email);
      },
    ),
    GoRoute(
      path: '/password-changed',
      builder: (context, state) => const PasswordChangedScreen(),
    ),
    GoRoute(
      path: '/forgot-password',
      builder: (context, state) => const ForgotPasswordScreen(),
    ),
    GoRoute(
      path: '/resumes',
      builder: (context, state) => const ResumeListScreen(),
    ),
    GoRoute(
      path: '/template',
      builder: (context, state) => const TemplateSelectionScreen(),
    ),
    GoRoute(
      path: '/editor/:id',
      builder: (context, state) {
        final id = int.parse(state.pathParameters['id']!);
        return EditorScreen(resumeId: id);
      },
    ),
  ],
);
