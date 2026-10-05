import 'dart:async';

import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prepmate_mobile/features/home/presentation/screens/home_screen.dart';
import 'package:prepmate_mobile/features/home/presentation/screens/pdf_view_screen.dart';
import 'package:prepmate_mobile/features/auth/presentation/screens/login_screen.dart';
import 'package:prepmate_mobile/features/auth/presentation/screens/otp_verification_screen.dart';
import 'package:prepmate_mobile/features/auth/presentation/state/auth_state.dart';
import 'package:prepmate_mobile/features/auth/presentation/viewmodel/auth_viewmodel.dart';
import 'package:prepmate_mobile/features/profile/presentation/screens/profile_screen.dart';
import 'package:prepmate_mobile/features/profile/presentation/screens/personal_info_screen.dart';
import 'package:prepmate_mobile/features/profile/presentation/screens/help_support_screen.dart';
import 'package:prepmate_mobile/features/home/presentation/screens/template_gallery_screen.dart';
import 'package:prepmate_mobile/features/home/presentation/screens/template_preview_screen.dart';
import 'package:prepmate_mobile/features/home/data/models/template_model.dart';
import 'package:prepmate_mobile/features/resume/presentation/screens/my_resumes_screen.dart';
import 'package:prepmate_mobile/features/resume/presentation/screens/resume_form_screen.dart';
import 'package:prepmate_mobile/features/onboarding/presentation/screens/onboarding_welcome_screen.dart';
import 'package:prepmate_mobile/features/onboarding/presentation/screens/career_progress_screen.dart';
import 'package:prepmate_mobile/features/onboarding/presentation/screens/profile_setup_screen.dart';
import 'package:prepmate_mobile/features/onboarding/presentation/screens/experience_level_screen.dart';
import 'package:prepmate_mobile/features/onboarding/presentation/screens/career_preferences_screen.dart';
import 'package:prepmate_mobile/features/onboarding/presentation/screens/onboarding_complete_screen.dart';

import 'package:prepmate_mobile/features/resume/presentation/screens/ai_assistant_screen.dart';
import 'package:prepmate_mobile/features/resume/presentation/screens/ai_input_screens.dart';
import 'package:prepmate_mobile/features/resume/presentation/screens/ai_result_screen.dart';

import 'package:prepmate_mobile/features/splash/screens/splash_screen.dart';
import 'package:prepmate_mobile/core/services/auth_token_manager.dart';
import 'package:prepmate_mobile/features/resume_optimizer/presentation/screens/optimize_resume_screen.dart';
import 'package:prepmate_mobile/features/resume_optimizer/presentation/screens/job_analysis_screen.dart';
import 'package:prepmate_mobile/features/resume_optimizer/presentation/screens/ai_suggestions_screen.dart';
import 'package:prepmate_mobile/features/resume_optimizer/presentation/screens/suggestion_editor_screen.dart';
import 'package:prepmate_mobile/features/resume_optimizer/presentation/screens/optimization_summary_screen.dart';
import 'package:prepmate_mobile/features/resume_optimizer/presentation/screens/ats_analysis_screen.dart';
import 'package:prepmate_mobile/features/resume_optimizer/presentation/screens/optimized_resume_preview_screen.dart';
import 'package:prepmate_mobile/features/resume_optimizer/presentation/screens/optimization_history_screen.dart';
import 'package:prepmate_mobile/features/resume_optimizer/presentation/screens/optimization_detail_screen.dart';
import 'package:prepmate_mobile/features/ai_credits/presentation/screens/ai_credits_screen.dart';
import 'package:prepmate_mobile/features/ai_credits/presentation/screens/ai_plans_screen.dart';
import 'package:prepmate_mobile/features/ai_credits/presentation/screens/ai_transactions_screen.dart';

String? authRedirect(AuthState authState, Uri uri) {
  final path = uri.path;
  final isAuthenticated = authState.status == AuthStatus.authenticated;
  const publicPaths = {'/splash', '/login', '/verify-otp'};
  final isPublic = publicPaths.contains(path);

  if (!authState.hasCheckedSession && path != '/splash') return '/splash';

  final user = authState.user;
  final isCompleted =
      user?.onboardingCompleted == true || user?.profileCompleted == true;

  if (path == '/splash' && authState.hasCheckedSession) {
    if (!isAuthenticated) return '/login';
    return isCompleted ? '/home' : _incompleteStepRoute(user?.onboardingStep);
  }

  if (!isAuthenticated && !isPublic) {
    final destination = Uri.encodeComponent(uri.toString());
    return '/login?from=$destination';
  }

  if (isAuthenticated && !isCompleted) {
    final isAlreadyOnboarding = path.startsWith('/onboarding/');
    if (!isAlreadyOnboarding && path != '/profile/edit') {
      return _incompleteStepRoute(user?.onboardingStep);
    }
  }

  if (isAuthenticated && isCompleted) {
    if (publicPaths.contains(path) && path != '/splash') {
      final destination = uri.queryParameters['from'];
      return destination != null &&
              destination.startsWith('/') &&
              !destination.startsWith('//')
          ? destination
          : '/home';
    }
    if (path.startsWith('/onboarding/')) {
      return '/home';
    }
  }

  return null;
}

String _incompleteStepRoute(int? step) {
  switch (step) {
    case 1:
      return '/onboarding/career-progress';
    case 2:
      return '/onboarding/profile';
    case 3:
      return '/onboarding/experience';
    case 4:
      return '/onboarding/goals';
    case 5:
      return '/onboarding/complete';
    default:
      return '/onboarding/welcome';
  }
}

// ─── Router refresh notifier ──────────────────────────────────────────────────

class _RouterRefreshNotifier extends ChangeNotifier {
  _RouterRefreshNotifier() {
    _logoutSub = AuthTokenManager.logoutStream.listen((_) => notifyListeners());
  }

  late final StreamSubscription<void> _logoutSub;

  void onAuthStateChange() => notifyListeners();

  @override
  void dispose() {
    _logoutSub.cancel();
    super.dispose();
  }
}

final appRouterProvider = Provider<GoRouter>((ref) {
  final notifier = _RouterRefreshNotifier();
  ref.onDispose(notifier.dispose);

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
      GoRoute(path: '/home', builder: (context, state) => const HomeScreen()),
      GoRoute(
        path: '/resumes',
        builder: (context, state) => const MyResumesScreen(),
      ),
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
        path: '/template/preview',
        builder: (context, state) {
          final template = state.extra is TemplateModel
              ? state.extra as TemplateModel
              : null;
          return TemplatePreviewScreen(template: template);
        },
      ),
      GoRoute(
        path: '/verify-otp',
        builder: (context, state) => const OtpVerificationScreen(),
      ),

      // Onboarding Routes
      GoRoute(
        path: '/onboarding/welcome',
        builder: (context, state) => const OnboardingWelcomeScreen(),
      ),
      GoRoute(
        path: '/onboarding/career-progress',
        builder: (context, state) => const CareerProgressScreen(),
      ),
      GoRoute(
        path: '/onboarding/profile',
        builder: (context, state) => const ProfileSetupScreen(),
      ),
      GoRoute(
        path: '/onboarding/experience',
        builder: (context, state) => const ExperienceLevelScreen(),
      ),
      GoRoute(
        path: '/onboarding/goals',
        builder: (context, state) => const CareerPreferencesScreen(),
      ),
      GoRoute(
        path: '/onboarding/complete',
        builder: (context, state) => const OnboardingCompleteScreen(),
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
      GoRoute(
        path: '/resume/ai-tool-adaptations',
        builder: (context, state) {
          final initialTool = state.extra?.toString() ?? 'bullets';
          return AIToolAdaptationsScreen(initialTool: initialTool);
        },
      ),
      GoRoute(
        path: '/resume/optimize/history',
        builder: (_, __) => const OptimizationHistoryScreen(),
      ),
      GoRoute(
        path: '/resume/optimize/detail/:id',
        builder: (_, state) => OptimizationDetailScreen(
          sessionId: state.pathParameters['id'] ?? '',
        ),
      ),
    ],
  );
});
