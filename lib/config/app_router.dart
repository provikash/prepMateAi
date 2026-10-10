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
import 'package:prepmate_mobile/core/widgets/adaptive_app_shell.dart';
import 'package:prepmate_mobile/core/widgets/app_error_page.dart';

String? authRedirect(AuthState authState, Uri uri) {
  final path = uri.path;
  final isAuthenticated = authState.status == AuthStatus.authenticated;
  const publicPaths = {'/splash', '/login', '/sign-in', '/verify-otp'};

  if (!authState.hasCheckedSession && path != '/splash') return '/splash';

  final user = authState.user;
  final isCompleted =
      user?.onboardingCompleted == true || user?.profileCompleted == true;

  if (path == '/splash' && authState.hasCheckedSession) {
    if (!isAuthenticated) return '/dashboard';
    return isCompleted
        ? '/dashboard'
        : _incompleteStepRoute(user?.onboardingStep);
  }

  if (!isAuthenticated && _requiresAuthentication(path)) {
    final destination = Uri.encodeComponent(uri.toString());
    return '/login?from=$destination';
  }

  if (!isAuthenticated && path.startsWith('/onboarding/')) {
    return '/dashboard';
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
          : '/dashboard';
    }
    if (path.startsWith('/onboarding/')) {
      return '/dashboard';
    }
  }

  return null;
}

bool _requiresAuthentication(String path) {
  const exactPaths = {
    '/profile/edit',
    '/profile/personal-info',
    '/ai-credits',
    '/credits',
    '/ai-plans',
    '/plans',
    '/ai-transactions',
    '/credits/transactions',
  };
  if (exactPaths.contains(path)) return true;
  return path == '/optimize' ||
      path == '/ai-assistant' ||
      path == '/optimizations' ||
      path.startsWith('/resume/optimize') ||
      path.startsWith('/resume/ai-') ||
      path.startsWith('/optimizations/');
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
    errorBuilder: (context, state) => const AppErrorPage(),
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(path: '/', redirect: (_, __) => '/dashboard'),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/sign-in',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => _withShell(state, const HomeScreen()),
      ),
      GoRoute(
        path: '/dashboard',
        builder: (context, state) => _withShell(state, const HomeScreen()),
      ),
      GoRoute(
        path: '/resumes',
        builder: (context, state) => _withShell(state, const MyResumesScreen()),
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => _withShell(state, const ProfileScreen()),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => _withShell(state, const ProfileScreen()),
      ),
      GoRoute(
        path: '/profile/edit',
        builder: (_, __) => const PersonalInfoScreen(),
      ),
      GoRoute(
        path: '/profile/personal-info',
        builder: (_, __) => const PersonalInfoScreen(),
      ),
      GoRoute(path: '/help', builder: (_, __) => const HelpSupportScreen()),
      GoRoute(
        path: '/ai-credits',
        builder: (_, state) => _withShell(state, const AiCreditsScreen()),
      ),
      GoRoute(
        path: '/credits',
        builder: (_, state) => _withShell(state, const AiCreditsScreen()),
      ),
      GoRoute(
        path: '/ai-plans',
        builder: (_, state) => _withShell(state, const AiPlansScreen()),
      ),
      GoRoute(
        path: '/plans',
        builder: (_, state) => _withShell(state, const AiPlansScreen()),
      ),
      GoRoute(
        path: '/ai-transactions',
        builder: (_, state) => _withShell(state, const AiTransactionsScreen()),
      ),
      GoRoute(
        path: '/credits/transactions',
        builder: (_, state) => _withShell(state, const AiTransactionsScreen()),
      ),
      GoRoute(
        path: '/template',
        builder: (context, state) =>
            _withShell(state, const TemplateGalleryScreen()),
      ),
      GoRoute(
        path: '/templates',
        builder: (context, state) =>
            _withShell(state, const TemplateGalleryScreen()),
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
        path: '/resumes/new',
        builder: (context, state) =>
            ResumeFormScreen(templateId: state.uri.queryParameters['template']),
      ),
      GoRoute(
        path: '/resume/pdf/:resumeId',
        builder: (context, state) {
          final resumeId = state.pathParameters['resumeId'] ?? '';
          return _withShell(state, PdfViewScreen(resumeId: resumeId));
        },
      ),
      GoRoute(
        path: '/resumes/:resumeId/preview',
        builder: (context, state) => _withShell(
          state,
          PdfViewScreen(resumeId: state.pathParameters['resumeId'] ?? ''),
        ),
      ),
      GoRoute(
        path: '/resume/optimize',
        builder: (_, state) => _withShell(state, const OptimizeResumeScreen()),
      ),
      GoRoute(
        path: '/optimize',
        builder: (_, state) => _withShell(state, const OptimizeResumeScreen()),
      ),
      GoRoute(
        path: '/resume/optimize/analysis',
        builder: (_, state) => _withShell(state, const JobAnalysisScreen()),
      ),
      GoRoute(
        path: '/resume/optimize/suggestions',
        builder: (_, state) => _withShell(state, const AiSuggestionsScreen()),
      ),
      GoRoute(
        path: '/resume/optimize/suggestions/:suggestionId/edit',
        builder: (_, state) => _withShell(
          state,
          SuggestionEditorScreen(
            suggestionId: state.pathParameters['suggestionId'] ?? '',
          ),
        ),
      ),
      GoRoute(
        path: '/resume/optimize/summary',
        builder: (_, state) =>
            _withShell(state, const OptimizationSummaryScreen()),
      ),
      GoRoute(
        path: '/resume/optimize/ats',
        builder: (_, state) => _withShell(state, const AtsAnalysisScreen()),
      ),
      GoRoute(
        path: '/resume/optimize/preview',
        builder: (_, state) =>
            _withShell(state, const OptimizedResumePreviewScreen()),
      ),
      GoRoute(
        path: '/resume/ai-assistant',
        builder: (context, state) =>
            _withShell(state, const AIAssistantScreen()),
      ),
      GoRoute(
        path: '/ai-assistant',
        builder: (context, state) =>
            _withShell(state, const AIAssistantScreen()),
      ),
      GoRoute(
        path: '/resume/ai-input/summary',
        builder: (context, state) =>
            _withShell(state, const GenerateSummaryInputScreen()),
      ),
      GoRoute(
        path: '/resume/ai-input/improve',
        builder: (context, state) =>
            _withShell(state, const ImproveSectionInputScreen()),
      ),
      GoRoute(
        path: '/resume/ai-input/skills',
        builder: (context, state) =>
            _withShell(state, const SuggestSkillsInputScreen()),
      ),
      GoRoute(
        path: '/resume/ai-input/bullets',
        builder: (context, state) =>
            _withShell(state, const GenerateBulletsInputScreen()),
      ),
      GoRoute(
        path: '/resume/ai-result',
        builder: (context, state) => _withShell(state, const AIResultScreen()),
      ),
      GoRoute(
        path: '/resume/ai-tool-adaptations',
        builder: (context, state) {
          final initialTool = state.extra?.toString() ?? 'bullets';
          return _withShell(
            state,
            AIToolAdaptationsScreen(initialTool: initialTool),
          );
        },
      ),
      GoRoute(
        path: '/resume/optimize/history',
        builder: (_, state) =>
            _withShell(state, const OptimizationHistoryScreen()),
      ),
      GoRoute(
        path: '/optimizations',
        builder: (_, state) =>
            _withShell(state, const OptimizationHistoryScreen()),
      ),
      GoRoute(
        path: '/resume/optimize/detail/:id',
        builder: (_, state) => _withShell(
          state,
          OptimizationDetailScreen(sessionId: state.pathParameters['id'] ?? ''),
        ),
      ),
      GoRoute(
        path: '/optimizations/:id',
        builder: (_, state) => _withShell(
          state,
          OptimizationDetailScreen(sessionId: state.pathParameters['id'] ?? ''),
        ),
      ),
    ],
  );
});

Widget _withShell(GoRouterState state, Widget child) =>
    AdaptiveAppShell(location: state.uri.path, child: child);
