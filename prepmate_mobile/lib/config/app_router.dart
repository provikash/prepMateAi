import 'package:prepmate_mobile/features/home/screens/home_screen.dart';
import 'package:go_router/go_router.dart';
import 'package:prepmate_mobile/features/resume/presentation/screens/editor_screen.dart';
import 'package:prepmate_mobile/features/resume/presentation/screens/resume_list_screen.dart';
import 'package:prepmate_mobile/features/resume/presentation/screens/template_screen.dart';
import 'package:prepmate_mobile/features/profile/presentation/screens/profile_screen.dart';
import 'package:prepmate_mobile/features/profile/presentation/screens/personal_info_screen.dart';
import 'package:prepmate_mobile/features/profile/presentation/screens/help_support_screen.dart';
import 'package:prepmate_mobile/features/interview/presentation/screens/interview_screen.dart';
import 'package:prepmate_mobile/features/ats/presentation/screens/ats_analysis_screen.dart';
import 'package:prepmate_mobile/features/resume_analyzer/presentation/screens/history_screen.dart';
import 'package:prepmate_mobile/features/resume_analyzer/presentation/screens/analyze_screen.dart';
import 'package:prepmate_mobile/features/resume_analyzer/presentation/screens/analysis_result_screen.dart';
import 'package:prepmate_mobile/features/resume_analyzer/data/models/resume_analysis_model.dart';
import 'package:prepmate_mobile/features/resume_analyzer/presentation/screens/result_screen.dart';

import '../features/auth/screens/forgetPassword_screen.dart';
import '../features/auth/screens/otpVerification_screen.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/auth/screens/passwordChanged_screen.dart';
import '../features/auth/screens/signup_screen.dart';

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

    GoRoute(
      path: '/profile',
      builder: (context, state) => const ProfileScreen(),
    ),
    GoRoute(
      path: '/personal-info',
      builder: (context, state) => const PersonalInfoScreen(),
    ),
    GoRoute(
      path: '/help-support',
      builder: (context, state) => const HelpSupportScreen(),
    ),
    GoRoute(
      path: '/ats-analysis',
      builder: (context, state) => const AnalyzeScreen(),
    ),
    GoRoute(
      path: '/ats-history',
      builder: (context, state) => const HistoryScreen(),
    ),
    GoRoute(
      path: '/ats-result',
      builder: (context, state) => AnalysisResultScreen(analysis: state.extra as ResumeAnalysisModel),
    ),
  ],
);
