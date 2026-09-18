import 'dart:async';

import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prepmate_mobile/features/home/presentation/screens/home_screen.dart';
import 'package:prepmate_mobile/features/home/presentation/screens/pdf_view_screen.dart';
import 'package:prepmate_mobile/features/auth/presentation/screens/login_screen.dart';
import 'package:prepmate_mobile/features/auth/presentation/screens/signup_screen.dart';
import 'package:prepmate_mobile/features/auth/presentation/screens/forgot_password_screen.dart';
import 'package:prepmate_mobile/features/auth/presentation/screens/otp_verification_screen.dart';
import 'package:prepmate_mobile/features/auth/presentation/screens/password_changed_screen.dart';
import 'package:prepmate_mobile/features/auth/presentation/screens/reset_password_screen.dart';
import 'package:prepmate_mobile/features/auth/presentation/state/auth_state.dart';
import 'package:prepmate_mobile/features/auth/presentation/viewmodel/auth_viewmodel.dart';
import 'package:prepmate_mobile/features/profile/presentation/screens/profile_screen.dart';
import 'package:prepmate_mobile/features/profile/presentation/screens/personal_info_screen.dart';
import 'package:prepmate_mobile/features/profile/presentation/screens/help_support_screen.dart';
import 'package:prepmate_mobile/features/home/presentation/screens/template_gallery_screen.dart';
import 'package:prepmate_mobile/features/resume/presentation/screens/resume_form_screen.dart';

import 'package:prepmate_mobile/features/resume/presentation/screens/ai_assistant_screen.dart';
import 'package:prepmate_mobile/features/resume/presentation/screens/ai_input_screens.dart';
import 'package:prepmate_mobile/features/resume/presentation/screens/ai_result_screen.dart';
import 'package:prepmate_mobile/features/resume_analyzer/data/models/resume_analysis_model.dart';
import 'package:prepmate_mobile/features/resume_analyzer/presentation/screens/history_screen.dart';
import 'package:prepmate_mobile/features/resume_analyzer/presentation/screens/analyze_screen.dart';
import 'package:prepmate_mobile/features/resume_analyzer/presentation/screens/analysis_result_screen.dart';
import 'package:prepmate_mobile/features/splash/screens/splash_screen.dart';
import 'package:prepmate_mobile/core/services/auth_token_manager.dart';
import 'package:prepmate_mobile/features/courses/presentation/screens/courses_screen.dart';
import 'package:prepmate_mobile/features/courses/presentation/screens/all_playlists_screen.dart';
import 'package:prepmate_mobile/features/resume_optimizer/presentation/screens/optimize_resume_screen.dart';
import 'package:prepmate_mobile/features/resume_optimizer/presentation/screens/job_analysis_screen.dart';
import 'package:prepmate_mobile/features/resume_optimizer/presentation/screens/ai_suggestions_screen.dart';
import 'package:prepmate_mobile/features/resume_optimizer/presentation/screens/suggestion_editor_screen.dart';
import 'package:prepmate_mobile/features/resume_optimizer/presentation/screens/optimization_summary_screen.dart';
import 'package:prepmate_mobile/features/resume_optimizer/presentation/screens/ats_analysis_screen.dart';
import 'package:prepmate_mobile/features/resume_optimizer/presentation/screens/optimized_resume_preview_screen.dart';
import 'package:prepmate_mobile/features/ai_credits/presentation/screens/ai_credits_screen.dart';
import 'package:prepmate_mobile/features/ai_credits/presentation/screens/ai_plans_screen.dart';
import 'package:prepmate_mobile/features/ai_credits/presentation/screens/ai_transactions_screen.dart';

String? authRedirect(AuthState authState, Uri uri) {
  final path = uri.path;
  final isAuthenticated = authState.status == AuthStatus.authenticated;
  const publicPaths = {
    '/splash',
    '/login',
    '/signup',
    '/forgot-password',
    '/verify-otp',
    '/reset-password',
    '/password-changed',
  };
  final isPublic = publicPaths.contains(path);

  if (!authState.hasCheckedSession && path != '/splash') return '/splash';
  if (path == '/splash' && authState.hasCheckedSession) {
    return isAuthenticated ? '/home' : '/login';
  }
  if (!isAuthenticated && !isPublic) {
    final destination = Uri.encodeComponent(uri.toString());
    return '/login?from=$destination';
  }
  if (isAuthenticated && publicPaths.contains(path) && path != '/splash') {
    final destination = uri.queryParameters['from'];
    return destination != null &&
            destination.startsWith('/') &&
            !destination.startsWith('//')
        ? destination
        : '/home';
  }
  return null;
}

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
      return authRedirect(ref.read(authProvider), state.uri);
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
        path: '/profile/edit',
        builder: (_, __) => const PersonalInfoScreen(),
      ),
      GoRoute(path: '/help', builder: (_, __) => const HelpSupportScreen()),
      GoRoute(path: '/ai-credits', builder: (_, __) => const AiCreditsScreen()),
      GoRoute(path: '/ai-plans', builder: (_, __) => const AiPlansScreen()),
      GoRoute(
        path: '/ai-transactions',
        builder: (_, __) => const AiTransactionsScreen(),
      ),
      GoRoute(
        path: '/template',
        builder: (context, state) => const TemplateGalleryScreen(),
      ),
      GoRoute(
        path: '/ats-result',
        builder: (context, state) {
          final analysis = state.extra;
          if (analysis is! ResumeAnalysisModel) {
            return const Scaffold(
              body: Center(
                child: Text(
                  'Analysis result is unavailable. Please run an analysis again.',
                ),
              ),
            );
          }
          return AnalysisResultScreen(analysis: analysis);
        },
      ),
      GoRoute(path: '/ats-analyze', builder: (_, __) => const AnalyzeScreen()),
      GoRoute(
        path: '/ats-history',
        builder: (context, state) => const HistoryScreen(),
      ),
      GoRoute(
        path: '/verify-otp',
        builder: (context, state) {
          final email =
              state.extra?.toString() ??
              state.uri.queryParameters['email'] ??
              '';
          final flow = state.uri.queryParameters['flow'] ?? 'register';
          return OtpVerificationScreen(email: email, flow: flow);
        },
      ),
      GoRoute(
        path: '/reset-password',
        builder: (context, state) {
          final values = state.extra is Map ? state.extra as Map : const {};
          return ResetPasswordScreen(
            email: values['email']?.toString() ?? '',
            otp: values['otp']?.toString() ?? '',
          );
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
        path: '/resume/optimize',
        builder: (_, __) => const OptimizeResumeScreen(),
      ),
      GoRoute(
        path: '/resume/optimize/analysis',
        builder: (_, __) => const JobAnalysisScreen(),
      ),
      GoRoute(
        path: '/resume/optimize/suggestions',
        builder: (_, __) => const AiSuggestionsScreen(),
      ),
      GoRoute(
        path: '/resume/optimize/suggestions/:suggestionId/edit',
        builder: (_, state) => SuggestionEditorScreen(
          suggestionId: state.pathParameters['suggestionId'] ?? '',
        ),
      ),
      GoRoute(
        path: '/resume/optimize/summary',
        builder: (_, __) => const OptimizationSummaryScreen(),
      ),
      GoRoute(
        path: '/resume/optimize/ats',
        builder: (_, __) => const AtsAnalysisScreen(),
      ),
      GoRoute(
        path: '/resume/optimize/preview',
        builder: (_, __) => const OptimizedResumePreviewScreen(),
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
      GoRoute(path: '/courses', builder: (_, __) => const CoursesScreen()),
      GoRoute(
        path: '/courses/playlists',
        builder: (_, __) => const AllPlaylistsScreen(),
      ),
    ],
  );
});
