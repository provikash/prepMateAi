import 'dart:async';

import 'package:go_router/go_router.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prepmate_mobile/features/home/presentation/screens/home_screen.dart';
import 'package:prepmate_mobile/features/home/presentation/screens/pdf_view_screen.dart';
import 'package:prepmate_mobile/features/auth/screens/login_screen.dart';
import 'package:prepmate_mobile/features/auth/presentation/screens/signup_screen.dart';
import 'package:prepmate_mobile/features/auth/screens/forgetPassword_screen.dart';
import 'package:prepmate_mobile/features/auth/screens/otpVerification_screen.dart';
import 'package:prepmate_mobile/features/auth/screens/passwordChanged_screen.dart';
import 'package:prepmate_mobile/features/auth/presentation/state/auth_state.dart';
import 'package:prepmate_mobile/features/auth/presentation/viewmodel/auth_viewmodel.dart';
import 'package:prepmate_mobile/features/profile/presentation/screens/profile_screen.dart';
import 'package:prepmate_mobile/features/home/presentation/screens/template_gallery_screen.dart';
import 'package:prepmate_mobile/features/resume/presentation/screens/resume_form_screen.dart';

import 'package:prepmate_mobile/features/resume/presentation/screens/ai_assistant_screen.dart';
import 'package:prepmate_mobile/features/resume/presentation/screens/ai_input_screens.dart';
import 'package:prepmate_mobile/features/resume/presentation/screens/ai_result_screen.dart';
import 'package:prepmate_mobile/features/resume_analyzer/data/models/resume_analysis_model.dart';
import 'package:prepmate_mobile/features/resume_analyzer/presentation/screens/history_screen.dart';
import 'package:prepmate_mobile/features/resume_analyzer/presentation/screens/analysis_result_screen.dart';
import 'package:prepmate_mobile/features/splash/screens/splash_screen.dart';
import 'package:prepmate_mobile/core/services/auth_token_manager.dart';

// ─── Router refresh notifier ──────────────────────────────────────────────────

/// A [ChangeNotifier] that [GoRouter] listens to so it can re-evaluate
/// its redirect function whenever auth state changes or a forced logout occurs.
class _RouterRefreshNotifier extends ChangeNotifier {
  _RouterRefreshNotifier() {
    // Subscribe to forced-logout events from the token manager.
    _logoutSub = AuthTokenManager.logoutStream.listen((_) => notifyListeners());
  }

  late final StreamSubscription<void> _logoutSub;

  /// Called by [ref.listen] whenever the Riverpod auth state changes.
  void onAuthStateChange() => notifyListeners();

  @override
  void dispose() {
    _logoutSub.cancel();
    super.dispose();
  }
}

final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  // Build a refresh notifier and wire up both sources of change.
  final notifier = _RouterRefreshNotifier();
  ref.onDispose(notifier.dispose);

  // Notify GoRouter whenever Riverpod auth state changes.
  ref.listen<AuthState>(authViewModelProvider, (_, __) {
    notifier.onAuthStateChange();
  });

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: notifier,
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
        '/ats-result',
        '/ats-history',
        '/resume/form',
        '/resume/pdf',
        '/resume/ai-assistant',
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
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/signup',
        builder: (context, state) => const SignupScreen(),
      ),
      GoRoute(path: '/home', builder: (context, state) => const HomeScreen()),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: '/template',
        builder: (context, state) => const TemplateGalleryScreen(),
      ),
      GoRoute(
        path: '/ats-result',
        builder: (context, state) {
          final analysis = state.extra as ResumeAnalysisModel;
          return AnalysisResultScreen(analysis: analysis);
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

      // Resume Builder Routes
      GoRoute(
        path: '/resume/form',
        builder: (context, state) {
          final templateId = state.extra?.toString();
          return ResumeFormScreen(templateId: templateId);
        },
      ),
      GoRoute(
        path: '/resume/pdf/:resumeId',
        builder: (context, state) {
          final resumeId = state.pathParameters['resumeId'] ?? '';
          return PdfViewScreen(resumeId: resumeId);
        },
      ),
      GoRoute(
        path: '/resume/ai-assistant',
        builder: (context, state) => const AIAssistantScreen(),
      ),
      GoRoute(
        path: '/resume/ai-input/summary',
        builder: (context, state) => const GenerateSummaryInputScreen(),
      ),
      GoRoute(
        path: '/resume/ai-input/improve',
        builder: (context, state) => const ImproveSectionInputScreen(),
      ),
      GoRoute(
        path: '/resume/ai-input/skills',
        builder: (context, state) => const SuggestSkillsInputScreen(),
      ),
      GoRoute(
        path: '/resume/ai-input/bullets',
        builder: (context, state) => const GenerateBulletsInputScreen(),
      ),
      GoRoute(
        path: '/resume/ai-result',
        builder: (context, state) => const AIResultScreen(),
      ),
    ],
  );
});
