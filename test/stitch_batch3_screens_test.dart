import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prepmate_mobile/config/theme.dart';
import 'package:prepmate_mobile/features/resume/presentation/providers/ai_provider.dart';
import 'package:prepmate_mobile/features/resume/presentation/screens/ai_input_screens.dart';
import 'package:prepmate_mobile/features/resume/presentation/screens/ai_result_screen.dart';
import 'package:prepmate_mobile/features/resume/presentation/widgets/ai_inline_edit_apply_modal.dart';
import 'package:prepmate_mobile/features/resume/presentation/widgets/ai_selection_sheets.dart';
import 'package:prepmate_mobile/features/resume_optimizer/data/mock_optimization_repository.dart';
import 'package:prepmate_mobile/features/resume_optimizer/domain/optimization_models.dart';
import 'package:prepmate_mobile/features/resume_optimizer/presentation/providers/optimization_provider.dart';
import 'package:prepmate_mobile/features/resume_optimizer/presentation/providers/optimization_sessions_provider.dart';
import 'package:prepmate_mobile/features/resume_optimizer/presentation/screens/optimization_detail_screen.dart';
import 'package:prepmate_mobile/features/resume_optimizer/presentation/screens/optimization_history_screen.dart';
import 'package:prepmate_mobile/features/resume_optimizer/presentation/widgets/optimization_detail_sheets.dart';
import 'package:prepmate_mobile/features/resume_optimizer/presentation/widgets/optimization_empty_states.dart';
import 'package:prepmate_mobile/features/resume_optimizer/presentation/widgets/optimization_filter_sort_sheet.dart';
import 'package:prepmate_mobile/features/resume_optimizer/presentation/widgets/optimization_session_card.dart';

Widget _wrap(Widget child, {List<Override> overrides = const []}) {
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp(
      theme: AppTheme.lightTheme,
      home: Scaffold(body: child),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Screen 29: AI Tool Input — Professional Summary', () {
    testWidgets(
      'renders input fields, tone chips, style options, and credit cost',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(_wrap(const GenerateSummaryInputScreen()));
        await tester.pumpAndSettle();

        expect(find.text('Professional Summary'), findsWidgets);
        expect(find.text('Target Role *'), findsOneWidget);
        expect(find.text('Output Style'), findsOneWidget);
        expect(find.text('Concise'), findsOneWidget);
        expect(find.text('Balanced'), findsOneWidget);
        expect(find.text('Detailed'), findsOneWidget);
        expect(find.text('Generate draft · 1 credit'), findsOneWidget);
        expect(find.textContaining('1 Credit'), findsWidgets);
      },
    );
  });

  group('Screen 30: AI Tool Input — Tool Adaptations', () {
    testWidgets('renders tool switcher tabs and bullet writer configuration', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        _wrap(const AIToolAdaptationsScreen(initialTool: 'bullet')),
      );
      await tester.pumpAndSettle();

      expect(find.text('Ai Tool Input'), findsOneWidget);
      expect(find.text('Bullet Writer'), findsOneWidget);
      expect(find.text('Cover Letter'), findsOneWidget);
      expect(find.text('Interview Qs'), findsOneWidget);
      expect(find.text('Skills Finder'), findsOneWidget);
      expect(find.text('ACTIVE WORKSPACE'), findsOneWidget);
      expect(find.text('Raw Notes or Task Dump'), findsOneWidget);
      expect(find.text('Generate draft · 1 credit'), findsOneWidget);
    });
  });

  group('Screen 35: AI Tool Input — Selection and Info Sheets', () {
    testWidgets('renders Choose Resume and About This Tool tabs', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        _wrap(ResumeSelectionSheet(selectedResumeId: null, onSelect: (_) {})),
      );
      await tester.pumpAndSettle();

      expect(find.text('Choose Resume'), findsWidgets);
      expect(find.text('About This Tool'), findsWidgets);
      expect(find.byIcon(Icons.folder_shared), findsWidgets);
    });
  });

  group('Screen 32: AI Result — Professional Summary Options', () {
    testWidgets('renders summary variation cards with copy and apply buttons', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final container = ProviderContainer();
      container
          .read(aiProvider.notifier)
          .setResultForTesting(
            toolType: 'summary',
            result: 'Results generated',
            variants: [
              'Impact-Driven: Increased throughput by 35% through reactive streams.',
              'Skill-Focused: Architected Flutter micro-frontends with BLoC.',
              'Leadership: Led a team of 8 cross-platform mobile engineers.',
            ],
          );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const AIResultScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Select Variation'), findsOneWidget);
      expect(find.textContaining('Impact-Driven'), findsOneWidget);
      expect(find.textContaining('Skill-Focused'), findsOneWidget);
      expect(find.textContaining('Leadership'), findsOneWidget);
      expect(find.text('Apply to resume'), findsOneWidget);
    });
  });

  group('Screen 33: AI Result — Inline Edit and Apply Modal', () {
    testWidgets('renders diff preview, editor, and replace option', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        _wrap(
          ApplySummaryModalSheet(
            existingContent: 'Experienced developer with 5 years.',
            newContent:
                'Senior Mobile Engineer with proven track record in fintech.',
            targetResumeTitle: 'Master Resume',
            onApplied: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Apply this summary to resume?'), findsOneWidget);
      expect(find.text('Existing draft'), findsOneWidget);
      expect(find.text('REPLACING WITH AI POLISH'), findsOneWidget);
      expect(
        find.text('Replace current summary with this version'),
        findsOneWidget,
      );
      expect(find.text('Confirm and apply'), findsOneWidget);
    });
  });

  group('Screen 34: AI Result — Experience Bullet Verification', () {
    testWidgets(
      'renders bullet point verification with factual claim checkboxes',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        final container = ProviderContainer();
        container
            .read(aiProvider.notifier)
            .setResultForTesting(
              toolType: 'bullets',
              result: 'Results',
              variants: [
                'Accelerated deployment frequency by 40% using Fastlane CI/CD.',
                'Mentored 6 junior engineers and improved code coverage to 92%.',
              ],
            );

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              theme: AppTheme.lightTheme,
              home: const AIResultScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Fact Check Required'), findsOneWidget);
        expect(find.text('Target Achievements'), findsOneWidget);
        expect(
          find.textContaining('Accelerated deployment frequency'),
          findsOneWidget,
        );
        expect(find.textContaining('Verified metric claim'), findsWidgets);
      },
    );
  });

  group('Screen 31: AI Result — Skills Multi-Tool Adaptations', () {
    testWidgets('renders categorized competency pills with confirm toggle', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final container = ProviderContainer();
      container
          .read(aiProvider.notifier)
          .setResultForTesting(
            toolType: 'skills',
            result: 'Results',
            variants: [
              'Riverpod',
              'Dart 3',
              'Fastlane CI/CD',
              'Clean Architecture',
            ],
          );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const AIResultScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Candidate integrity first'), findsOneWidget);
      expect(find.text('Technical & Architecture'), findsOneWidget);
      expect(find.text('Riverpod'), findsOneWidget);
      expect(find.text('Dart 3'), findsOneWidget);
    });
  });

  group('Screen 36: Optimization History — Status Variants Card', () {
    testWidgets('renders Completed and Analyzing status card variants', (
      tester,
    ) async {
      final completedSession = OptimizationSessionModel(
        id: 'session-1',
        sourceResumeId: 'res-1',
        sourceResumeTitle: 'Mobile Resume',
        status: 'COMPLETED',
        jobDescription: const JobDescriptionModel(
          id: 'jd-1',
          title: 'Senior Flutter Developer',
          company: 'TechSprint',
          description: 'Desc',
        ),
        decisionCounts: const {'accepted': 6, 'edited': 2, 'rejected': 1},
      );

      await tester.pumpWidget(
        _wrap(OptimizationSessionCard(session: completedSession, onTap: () {})),
      );
      await tester.pumpAndSettle();

      expect(find.text('Completed'), findsOneWidget);
      expect(find.text('Senior Flutter Developer'), findsOneWidget);
      expect(find.text('TechSprint'), findsOneWidget);
      expect(find.text('View Details'), findsOneWidget);
    });
  });

  group('Screen 37: Optimization History — Filter and Sort Sheet', () {
    testWidgets('renders quick sort options and status filter pills', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        _wrap(
          OptimizationFilterSortSheet(
            initialFilter: const OptimizationHistoryFilter(),
            onApply: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Filter & Sort Optimizations'), findsOneWidget);
      expect(find.text('QUICK SORT'), findsOneWidget);
      expect(find.text('Recently updated'), findsOneWidget);
      expect(find.text('Newest created'), findsOneWidget);
      expect(find.text('SESSION STATUS'), findsOneWidget);
      expect(find.text('All Statuses'), findsOneWidget);
      expect(find.text('In Progress'), findsOneWidget);
      expect(find.text('Show Results'), findsOneWidget);
      expect(find.text('Reset All'), findsOneWidget);
    });
  });

  group('Screen 38: Optimization History — Search and Empty States', () {
    testWidgets('renders zero state with transparent credit guarantee', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(OptimizationZeroState(onStartOptimization: () {})),
      );
      await tester.pumpAndSettle();

      expect(
        find.text('Optimize your resume for any target job'),
        findsOneWidget,
      );
      expect(find.text('Transparent Credits'), findsOneWidget);
      expect(find.text('Start your first optimization'), findsOneWidget);
    });

    testWidgets('renders no search results state with clear button', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          OptimizationNoSearchResultsState(
            query: 'Quantum Engineer',
            onClearSearch: () {},
            onViewAll: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('No matching sessions found'), findsOneWidget);
      expect(find.textContaining('Quantum Engineer'), findsOneWidget);
      expect(find.text('Clear search'), findsOneWidget);
      expect(find.text('View all sessions'), findsOneWidget);
    });
  });

  group('Screen 39: Optimization History Populated Screen', () {
    testWidgets(
      'renders history screen with session cards and New Optimization FAB',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          _wrap(
            const OptimizationHistoryScreen(),
            overrides: [
              optimizationRepositoryProvider.overrideWithValue(
                MockOptimizationRepository(),
              ),
            ],
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));
        await tester.pump();

        expect(find.text('Optimization History'), findsOneWidget);
        expect(find.text('New Optimization'), findsOneWidget);
        expect(find.text('All'), findsOneWidget);
        expect(find.text('In Progress'), findsOneWidget);
        expect(find.text('Completed'), findsWidgets);
      },
    );
  });

  group('Screen 40: Optimization Detail — Source Inspection Sheets', () {
    testWidgets('renders JobDescriptionInspectionSheet with copy action', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          const JobDescriptionInspectionSheet(
            jobDescription: JobDescriptionModel(
              id: 'jd-1',
              title: 'Staff Architect',
              company: 'Stripe',
              description:
                  'We are seeking a Staff Mobile Architect to scale our payment SDKs.',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Job Description Details'), findsOneWidget);
      expect(find.textContaining('Stripe'), findsOneWidget);
      expect(find.textContaining('Staff Mobile Architect'), findsOneWidget);
      expect(find.text('Copy job description'), findsOneWidget);
    });

    testWidgets('renders SourceResumeVersionSheet with snapshot notice', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          const SourceResumeVersionSheet(
            session: OptimizationSessionModel(
              id: 's-1',
              sourceResumeId: 'r-1',
              sourceResumeTitle: 'Staff Mobile Resume',
              status: 'COMPLETED',
              sourceResumeVersion: 2,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Source Resume Version'), findsOneWidget);
      expect(find.text('Staff Mobile Resume'), findsOneWidget);
      expect(find.textContaining('Snapshot version v2'), findsOneWidget);
    });
  });

  group('Screen 42: Optimization Detail — Completed State', () {
    testWidgets(
      'renders 5-stage timeline, alignment metric, and credit activity',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          _wrap(
            const OptimizationDetailScreen(sessionId: 'mock-session-3'),
            overrides: [
              optimizationRepositoryProvider.overrideWithValue(
                MockOptimizationRepository(),
              ),
            ],
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Optimization Overview'), findsOneWidget);
        expect(find.text('Optimization complete'), findsOneWidget);
        expect(find.text('Workflow Timeline'), findsOneWidget);
        expect(find.text('5 / 5 Complete'), findsOneWidget);
        expect(find.text('Job Analysis Snapshot'), findsOneWidget);
        expect(find.text('92%'), findsOneWidget);
        expect(find.text('Suggestion Decisions'), findsOneWidget);
        expect(find.text('Credit Activity'), findsOneWidget);
        expect(find.text('Preview PDF'), findsOneWidget);
        expect(find.text('Open Summary'), findsOneWidget);
      },
    );
  });
}
