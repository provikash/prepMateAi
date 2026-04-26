import 'package:go_router/go_router.dart';
import 'package:prepmate_mobile/features/home/screens/home_screen.dart';
import 'package:prepmate_mobile/features/auth/screens/login_screen.dart';
import 'package:prepmate_mobile/features/auth/screens/signup_screen.dart';
import 'package:prepmate_mobile/features/auth/screens/forgetPassword_screen.dart';
import 'package:prepmate_mobile/features/auth/screens/otpVerification_screen.dart';
import 'package:prepmate_mobile/features/auth/screens/passwordChanged_screen.dart';
import 'package:prepmate_mobile/features/profile/presentation/screens/profile_screen.dart';
import 'package:prepmate_mobile/features/home/presentation/screens/pdf_view_screen.dart';
import 'package:prepmate_mobile/features/home/presentation/screens/template_editor_screen.dart';
import 'package:prepmate_mobile/features/home/presentation/screens/template_gallery_screen.dart';
import 'package:prepmate_mobile/features/resume_analyzer/data/models/resume_analysis_model.dart';
import 'package:prepmate_mobile/features/resume_analyzer/presentation/screens/history_screen.dart';
import 'package:prepmate_mobile/features/resume_analyzer/presentation/screens/result_screen.dart';

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
      path: '/profile',
      builder: (context, state) => const ProfileScreen(),
    ),
    GoRoute(
      path: '/resume-view',
      builder: (context, state) {
        final resumeId = (state.extra ?? '').toString();
        return PdfViewScreen(resumeId: resumeId);
      },
    ),
    GoRoute(
      path: '/template',
      builder: (context, state) => const TemplateGalleryScreen(),
    ),
    GoRoute(
      path: '/template-detail',
      builder: (context, state) {
        final templateId = (state.extra ?? '').toString();
        return TemplateEditorScreen(templateId: templateId);
      },
    ),
    GoRoute(
      path: '/ats-result',
      builder: (context, state) {
        final analysis = state.extra as ResumeAnalysisModel;
        return ResultScreen(analysis: analysis);
      },
    ),
    GoRoute(
      path: '/ats-history',
      builder: (context, state) => const HistoryScreen(),
    ),
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
  ],
);
