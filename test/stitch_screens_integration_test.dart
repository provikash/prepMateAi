import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prepmate_mobile/config/app_router.dart';
import 'package:prepmate_mobile/config/theme.dart';
import 'package:prepmate_mobile/core/widgets/app_logo.dart';
import 'package:prepmate_mobile/core/widgets/main_bottom_nav.dart';
import 'package:prepmate_mobile/core/widgets/selection_card.dart';
import 'package:prepmate_mobile/core/widgets/goal_card.dart';
import 'package:prepmate_mobile/features/auth/domain/entities/user.dart';
import 'package:prepmate_mobile/features/auth/presentation/state/auth_state.dart';
import 'package:prepmate_mobile/features/home/data/models/template_model.dart';
import 'package:prepmate_mobile/features/home/presentation/screens/template_preview_screen.dart';
import 'package:prepmate_mobile/features/onboarding/presentation/screens/onboarding_welcome_screen.dart';
import 'package:prepmate_mobile/features/onboarding/presentation/screens/career_progress_screen.dart';
import 'package:prepmate_mobile/features/onboarding/presentation/screens/onboarding_complete_screen.dart';

void main() {
  group('Splash and Session Check Routing (Screen 07)', () {
    test('Unauthenticated user is routed to /login', () {
      final route = authRedirect(
        AuthState(status: AuthStatus.unauthenticated, hasCheckedSession: true),
        Uri.parse('/splash'),
      );
      expect(route, '/login');
    });

    test('Authenticated user with complete onboarding is routed to /home', () {
      final user = User(
        id: 'user-1',
        email: 'alex@example.com',
        onboardingCompleted: true,
        profileCompleted: true,
      );
      final route = authRedirect(
        AuthState(
          status: AuthStatus.authenticated,
          hasCheckedSession: true,
          user: user,
        ),
        Uri.parse('/splash'),
      );
      expect(route, '/home');
    });

    test(
      'Authenticated user with incomplete onboarding routes to step 0 /welcome',
      () {
        final user = User(
          id: 'user-2',
          email: 'alex@example.com',
          onboardingStep: 0,
          onboardingCompleted: false,
          profileCompleted: false,
        );
        final route = authRedirect(
          AuthState(
            status: AuthStatus.authenticated,
            hasCheckedSession: true,
            user: user,
          ),
          Uri.parse('/splash'),
        );
        expect(route, '/onboarding/welcome');
      },
    );

    test(
      'Authenticated user with incomplete onboarding routes to step 1 /career-progress',
      () {
        final user = User(
          id: 'user-3',
          email: 'alex@example.com',
          onboardingStep: 1,
          onboardingCompleted: false,
          profileCompleted: false,
        );
        final route = authRedirect(
          AuthState(
            status: AuthStatus.authenticated,
            hasCheckedSession: true,
            user: user,
          ),
          Uri.parse('/splash'),
        );
        expect(route, '/onboarding/career-progress');
      },
    );

    test(
      'Authenticated user with incomplete onboarding routes to step 2 /profile',
      () {
        final user = User(
          id: 'user-4',
          email: 'alex@example.com',
          onboardingStep: 2,
          onboardingCompleted: false,
          profileCompleted: false,
        );
        final route = authRedirect(
          AuthState(
            status: AuthStatus.authenticated,
            hasCheckedSession: true,
            user: user,
          ),
          Uri.parse('/splash'),
        );
        expect(route, '/onboarding/profile');
      },
    );

    test(
      'Authenticated user with incomplete onboarding routes to step 3 /experience',
      () {
        final user = User(
          id: 'user-5',
          email: 'alex@example.com',
          onboardingStep: 3,
          onboardingCompleted: false,
          profileCompleted: false,
        );
        final route = authRedirect(
          AuthState(
            status: AuthStatus.authenticated,
            hasCheckedSession: true,
            user: user,
          ),
          Uri.parse('/splash'),
        );
        expect(route, '/onboarding/experience');
      },
    );

    test(
      'Authenticated user with incomplete onboarding routes to step 4 /goals',
      () {
        final user = User(
          id: 'user-6',
          email: 'alex@example.com',
          onboardingStep: 4,
          onboardingCompleted: false,
          profileCompleted: false,
        );
        final route = authRedirect(
          AuthState(
            status: AuthStatus.authenticated,
            hasCheckedSession: true,
            user: user,
          ),
          Uri.parse('/splash'),
        );
        expect(route, '/onboarding/goals');
      },
    );

    test('Authenticated user with step 5 routes to /onboarding/complete', () {
      final user = User(
        id: 'user-7',
        email: 'alex@example.com',
        onboardingStep: 5,
        onboardingCompleted: false,
        profileCompleted: false,
      );
      final route = authRedirect(
        AuthState(
          status: AuthStatus.authenticated,
          hasCheckedSession: true,
          user: user,
        ),
        Uri.parse('/splash'),
      );
      expect(route, '/onboarding/complete');
    });
  });

  group('Brand Logo & Design System Assets (Screen 13)', () {
    testWidgets('AppLogo renders with semantic label and custom size', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AppLogo(
              size: 48,
              semanticLabel: 'PrepMate AI official brand logo',
            ),
          ),
        ),
      );
      expect(find.byType(AppLogo), findsOneWidget);
    });
  });

  group('Main Bottom Navigation Bar', () {
    testWidgets(
      'MainBottomNavigation renders all 4 primary destinations with touch targets',
      (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              bottomNavigationBar: MainBottomNavigation(
                currentTab: MainNavTab.home,
              ),
            ),
          ),
        );

        expect(find.text('Home'), findsOneWidget);
        expect(find.text('Resumes'), findsOneWidget);
        expect(find.text('AI Tools'), findsOneWidget);
        expect(find.text('Profile'), findsOneWidget);
      },
    );
  });

  group('Selection & Goal Reusable Cards (Screens 06 & 02)', () {
    testWidgets('SelectionCard handles selection state and callback', (
      tester,
    ) async {
      bool tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: SelectionCard(
              title: 'Entry Level',
              subtitle: '0-2 years of working experience',
              icon: Icons.work_outline,
              isSelected: true,
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      expect(find.text('Entry Level'), findsOneWidget);
      expect(find.text('0-2 years of working experience'), findsOneWidget);
      expect(find.byIcon(Icons.check), findsOneWidget);

      await tester.tap(find.byType(SelectionCard));
      expect(tapped, isTrue);
    });

    testWidgets('GoalCard toggles and displays target description', (
      tester,
    ) async {
      bool selected = false;
      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) {
            return MaterialApp(
              theme: AppTheme.lightTheme,
              home: Scaffold(
                body: GoalCard(
                  title: 'Switch careers',
                  description: 'Transition into a high-demand tech role',
                  icon: Icons.trending_up,
                  isSelected: selected,
                  onTap: () => setState(() => selected = !selected),
                ),
              ),
            );
          },
        ),
      );

      expect(find.text('Switch careers'), findsOneWidget);
      await tester.tap(find.byType(GoalCard));
      await tester.pumpAndSettle();
      expect(selected, isTrue);
    });
  });

  group('Template Preview (Screen 09)', () {
    testWidgets('TemplatePreviewScreen renders template details and CTA', (
      tester,
    ) async {
      final template = TemplateModel(
        id: 'classic-ats',
        title: 'Classic ATS Clean Format',
        category: 'Professional',
        thumbnailUrl: '',
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: TemplatePreviewScreen(template: template),
          ),
        ),
      );

      expect(find.text('Template Preview'), findsOneWidget);
      expect(find.text('Classic ATS Clean Format'), findsOneWidget);
      expect(find.text('Use this template'), findsOneWidget);
      expect(find.byIcon(Icons.auto_awesome), findsWidgets);
    });
  });

  group('Onboarding Welcome & Progress Screens (Screens 14, 01, 08)', () {
    testWidgets(
      'OnboardingWelcomeScreen renders welcome heading and start button',
      (tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(home: OnboardingWelcomeScreen()),
          ),
        );

        expect(
          find.text('Let’s personalize your PrepMate experience'),
          findsOneWidget,
        );
        expect(find.text('Start setup'), findsOneWidget);
      },
    );

    testWidgets('CareerProgressScreen renders career illustration steps', (
      tester,
    ) async {
      await tester.pumpWidget(
        const ProviderScope(child: MaterialApp(home: CareerProgressScreen())),
      );

      expect(
        find.text('Map your journey from aspiration to offer'),
        findsOneWidget,
      );
      expect(find.text('Continue to profile setup'), findsOneWidget);
    });

    testWidgets('OnboardingCompleteScreen renders completion celebration', (
      tester,
    ) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(home: OnboardingCompleteScreen()),
        ),
      );

      expect(find.textContaining('ready'), findsOneWidget);
      expect(find.text('Go to Dashboard'), findsOneWidget);
    });
  });
}
