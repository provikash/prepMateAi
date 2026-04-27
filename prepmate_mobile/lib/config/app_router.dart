import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prepmate_mobile/features/home/screens/home_screen.dart';
import 'package:prepmate_mobile/features/auth/screens/login_screen.dart';
import 'package:prepmate_mobile/features/auth/screens/signup_screen.dart';
import 'package:prepmate_mobile/features/auth/screens/forgetPassword_screen.dart';
import 'package:prepmate_mobile/features/auth/screens/otpVerification_screen.dart';
import 'package:prepmate_mobile/features/auth/screens/passwordChanged_screen.dart';
import 'package:prepmate_mobile/features/auth/presentation/state/auth_state.dart';
import 'package:prepmate_mobile/features/auth/presentation/viewmodel/auth_viewmodel.dart';
import 'package:prepmate_mobile/features/profile/presentation/screens/profile_screen.dart';
import 'package:prepmate_mobile/features/home/presentation/screens/template_gallery_screen.dart';
import 'package:prepmate_mobile/features/resume/presentation/screens/resume_pdf_preview_screen.dart';
import 'package:prepmate_mobile/features/resume/presentation/screens/template_form_screen.dart';
import 'package:prepmate_mobile/features/resume_analyzer/data/models/resume_analysis_model.dart';
import 'package:prepmate_mobile/features/resume_analyzer/presentation/screens/history_screen.dart';
import 'package:prepmate_mobile/features/resume_analyzer/presentation/screens/result_screen.dart';

import 'package:prepmate_mobile/features/splash/screens/splash_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: '/splash',
    redirect: (context, state) {
      final location = state.matchedLocation;
      final isAuthenticated = authState.status == AuthStatus.authenticated;
      final sessionChecked = authState.hasCheckedSession;

      const authRoutes = <String>{
        '/login',
        '/signup',
        '/forgot-password',
        '/verify-otp',
        '/password-changed',
      };

      const protectedRoutes = <String>{
        '/',
        '/home',
        '/profile',
        '/template',
        '/template-detail',
        '/resume-view',
        '/ats-result',
        '/ats-history',
      };

      if (!sessionChecked && location != '/splash') {
        return '/splash';
      }

      if (location == '/splash' && sessionChecked) {
        return isAuthenticated ? '/home' : '/login';
      }

      if (!isAuthenticated && protectedRoutes.contains(location)) {
        return '/login';
      }

      if (isAuthenticated && authRoutes.contains(location)) {
        return '/home';
      }

      return null;
    },
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
          return ResumePdfPreviewScreen(resumeId: resumeId);
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
          return TemplateFormScreen(templateId: templateId);
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
});
