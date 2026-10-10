import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prepmate_mobile/config/theme.dart';
import 'package:prepmate_mobile/features/ai_credits/data/repositories/mock_ai_credits_repository.dart';
import 'package:prepmate_mobile/features/ai_credits/presentation/providers/ai_credits_provider.dart';
import 'package:prepmate_mobile/features/ai_credits/presentation/widgets/ai_credits_stitch_widgets.dart';
import 'package:prepmate_mobile/features/home/data/models/resume_model.dart';
import 'package:prepmate_mobile/features/resume_optimizer/data/mock_optimization_repository.dart';
import 'package:prepmate_mobile/features/resume_optimizer/domain/optimization_models.dart';
import 'package:prepmate_mobile/features/resume_optimizer/presentation/providers/optimization_provider.dart';
import 'package:prepmate_mobile/features/resume_optimizer/presentation/screens/ats_analysis_screen.dart';
import 'package:prepmate_mobile/features/resume_optimizer/presentation/screens/optimization_summary_screen.dart';
import 'package:prepmate_mobile/features/resume_optimizer/presentation/screens/optimized_resume_preview_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget _wrap(Widget child, {List<Override> overrides = const []}) {
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp(
      theme: AppTheme.lightTheme,
      home: Scaffold(body: child),
    ),
  );
}

OptimizationAnalysis _sampleAnalysis() {
  const suggestions = [
    OptimizationSuggestion(
      id: 'sug-1',
      section: 'Professional Summary',
      current: 'Experienced developer',
      proposed:
          'Senior Flutter Developer with 5+ years of fintech architecture',
      reason: 'Align with target role requirements',
      keywords: ['Flutter', 'fintech'],
      evidence: '5+ years mobile development experience',
      status: SuggestionStatus.accepted,
      highImpact: true,
      requiresConfirmation: true,
    ),
    OptimizationSuggestion(
      id: 'sug-2',
      section: 'Work Experience',
      current: 'Worked on app performance',
      proposed:
          'Architected offline-first SQLite synchronization reducing latency by 35%',
      reason: 'Add quantifiable metrics',
      keywords: ['SQLite', 'offline-first'],
      evidence: 'Engineered offline cache mechanisms',
      status: SuggestionStatus.edited,
      highImpact: true,
      requiresConfirmation: true,
    ),
    OptimizationSuggestion(
      id: 'sug-3',
      section: 'Core Skills',
      current: 'Dart, Java',
      proposed: 'Dart, Riverpod, SQLite, CI/CD, REST APIs',
      reason: 'Highlight job-critical technical skills',
      keywords: ['Riverpod', 'CI/CD'],
      evidence: 'Dart and state management',
      status: SuggestionStatus.accepted,
      highImpact: true,
    ),
    OptimizationSuggestion(
      id: 'sug-4',
      section: 'Projects',
      current: 'Personal budgeting app',
      proposed:
          'Production-ready budgeting app with 10k+ downloads on Play Store',
      reason: 'Clarify project scope',
      keywords: ['production'],
      evidence: 'Developed mobile app for fintech',
      status: SuggestionStatus.rejected,
      highImpact: false,
    ),
  ];

  return const OptimizationAnalysis(
    beforeScore: 68,
    afterScore: 92,
    beforeAtsScore: 64,
    afterAtsScore: 90,
    requirements: [
      JobRequirement(
        id: 'req-1',
        name: 'Flutter Architecture',
        category: 'Hard Skill',
        match: RequirementMatch.matched,
        evidence: '5+ years fintech architecture',
        importance: 'High',
        explanation: 'Strong matched experience',
      ),
      JobRequirement(
        id: 'req-2',
        name: 'Offline SQLite Sync',
        category: 'Technology',
        match: RequirementMatch.matched,
        evidence: 'SQLite synchronization engine',
        importance: 'High',
        explanation: 'Documented offline caching',
      ),
      JobRequirement(
        id: 'req-3',
        name: 'Cloud Deployment',
        category: 'DevOps',
        match: RequirementMatch.partial,
        evidence: 'Basic CI/CD pipeline experience',
        importance: 'Medium',
        explanation: 'Partial CI/CD background',
      ),
    ],
    suggestions: suggestions,
    totalRequirements: 3,
    matchedCount: 2,
    partialCount: 1,
    missingCount: 0,
    unclearCount: 0,
    sourceResumeVersion: 1,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Optimization Summary Detailed Edge States', () {
    testWidgets(
      'unresolved suggestions state renders warning banner and deep link',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        final analysis = _sampleAnalysis();
        final withPending = analysis.copyWith(
          suggestions: [
            ...analysis.suggestions,
            const OptimizationSuggestion(
              id: 'sug-pending',
              section: 'Education',
              current: 'BS CS',
              proposed: 'B.S. in Computer Science (Honors)',
              reason: 'Formalize degree title',
              keywords: ['Honors'],
              evidence: 'University degree records',
              status: SuggestionStatus.pending,
            ),
          ],
        );

        final notifier = OptimizationNotifier(MockOptimizationRepository());
        notifier.selectResume(
          ResumeModel(
            id: 'res-1',
            title: 'Master Resume',
            thumbnailUrl: '',
            pdfUrl: '',
          ),
        );
        notifier.state = notifier.state.copyWith(
          analysis: withPending,
          summaryEdgeState: 'unresolved',
        );

        await tester.pumpWidget(
          _wrap(
            const OptimizationSummaryScreen(),
            overrides: [optimizationProvider.overrideWith((ref) => notifier)],
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Suggestions Still Require Review'), findsOneWidget);
        expect(find.text('Review Remaining Items'), findsOneWidget);
      },
    );

    testWidgets('source conflict state shows parallel modification alert', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final notifier = OptimizationNotifier(MockOptimizationRepository());
      notifier.selectResume(
        ResumeModel(
          id: 'res-1',
          title: 'Master Resume',
          thumbnailUrl: '',
          pdfUrl: '',
        ),
      );
      notifier.state = notifier.state.copyWith(
        analysis: _sampleAnalysis(),
        summaryEdgeState: 'conflict',
      );

      await tester.pumpWidget(
        _wrap(
          const OptimizationSummaryScreen(),
          overrides: [optimizationProvider.overrideWith((ref) => notifier)],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Source Resume Modified in Parallel'), findsOneWidget);
      expect(find.text('Review conflicts'), findsOneWidget);
      expect(find.text('Create copy from snapshot'), findsOneWidget);
    });

    testWidgets(
      'offline edge state disables creation and displays network warning',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        final notifier = OptimizationNotifier(MockOptimizationRepository());
        notifier.selectResume(
          ResumeModel(
            id: 'res-1',
            title: 'Master Resume',
            thumbnailUrl: '',
            pdfUrl: '',
          ),
        );
        notifier.state = notifier.state.copyWith(
          analysis: _sampleAnalysis(),
          summaryEdgeState: 'offline',
        );

        await tester.pumpWidget(
          _wrap(
            const OptimizationSummaryScreen(),
            overrides: [optimizationProvider.overrideWith((ref) => notifier)],
          ),
        );
        await tester.pumpAndSettle();

        expect(find.textContaining('Offline mode'), findsOneWidget);
        final createButton = tester.widget<FilledButton>(
          find.widgetWithText(FilledButton, 'Create resume'),
        );
        expect(createButton.onPressed, isNull);
      },
    );
  });

  group('Optimized Resume Preview & Management', () {
    testWidgets('revert confirmation modal invokes revert action safely', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final notifier = OptimizationNotifier(MockOptimizationRepository());
      final resume = ResumeModel(
        id: 'res-1',
        title: 'Master Resume',
        thumbnailUrl: '',
        pdfUrl: '',
      );
      notifier.selectResume(resume);
      notifier.state = notifier.state.copyWith(
        analysis: _sampleAnalysis(),
        finalizedVersionId: 'ver-101',
        viewerMode: 'changes',
      );

      await tester.pumpWidget(
        _wrap(
          const OptimizedResumePreviewScreen(),
          overrides: [
            optimizationProvider.overrideWith((ref) => notifier),
            optimizedVersionPdfProvider.overrideWith((ref, id) => Uint8List(0)),
          ],
        ),
      );
      await tester.pumpAndSettle();

      // Find and tap Revert This Change button
      final revertButton = find.widgetWithText(
        OutlinedButton,
        'Revert This Change',
      );
      expect(revertButton, findsOneWidget);
      await tester.tap(revertButton);
      await tester.pumpAndSettle();

      // Verify modal dialog appeared
      expect(find.text('Revert this change?'), findsOneWidget);
      expect(
        find.textContaining('This will restore the original baseline text'),
        findsOneWidget,
      );
      expect(find.text('Keep Change'), findsOneWidget);
      expect(find.text('Revert'), findsOneWidget);

      // Confirm revert
      await tester.tap(find.text('Revert'));
      await tester.pumpAndSettle();
      expect(find.text('Change reverted in draft version.'), findsOneWidget);
    });

    testWidgets(
      'template selector triggers update and marks preview outdated',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        final notifier = OptimizationNotifier(MockOptimizationRepository());
        notifier.selectResume(
          ResumeModel(
            id: 'res-1',
            title: 'Master Resume',
            thumbnailUrl: '',
            pdfUrl: '',
          ),
        );
        notifier.state = notifier.state.copyWith(
          analysis: _sampleAnalysis(),
          finalizedVersionId: 'ver-101',
          selectedTemplate: 'Modern Professional Duo',
        );

        await tester.pumpWidget(
          _wrap(
            const OptimizedResumePreviewScreen(),
            overrides: [
              optimizationProvider.overrideWith((ref) => notifier),
              optimizedVersionPdfProvider.overrideWith(
                (ref, id) => Uint8List(0),
              ),
            ],
          ),
        );
        await tester.pumpAndSettle();

        // Open popup menu
        await tester.tap(find.byTooltip('More actions'));
        await tester.pumpAndSettle();
        expect(find.text('Change Template'), findsOneWidget);

        // Tap Change Template to open bottom sheet
        await tester.tap(find.text('Change Template'));
        await tester.pumpAndSettle();
        expect(find.text('Change Resume Template'), findsOneWidget);
        expect(
          find.textContaining('Template changes do not consume AI credits'),
          findsOneWidget,
        );

        // Select Minimalist Tech
        await tester.tap(find.text('Minimalist Tech'));
        await tester.pumpAndSettle();
        expect(notifier.state.selectedTemplate, 'Minimalist Tech');
        expect(notifier.state.pdfStatus, 'outdated');
        expect(
          find.textContaining('Template changed to Minimalist Tech'),
          findsOneWidget,
        );
      },
    );
  });

  group('ATS Analysis Transparent Diagnostics', () {
    testWidgets(
      'transparent readiness label and deterministic parsing integrity',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        final notifier = OptimizationNotifier(MockOptimizationRepository());
        notifier.state = notifier.state.copyWith(
          analysis: _sampleAnalysis(),
          versionName: 'Tailored Resume (v1)',
          company: 'Stripe',
        );

        await tester.pumpWidget(
          _wrap(
            const AtsAnalysisScreen(),
            overrides: [optimizationProvider.overrideWith((ref) => notifier)],
          ),
        );
        await tester.pumpAndSettle();

        // Verify transparent PrepMate Readiness Score
        expect(find.text('PrepMate Readiness Score'), findsOneWidget);
        expect(
          find.textContaining(
            'Calculated from deterministic parsing & evidence alignment',
          ),
          findsOneWidget,
        );

        // Switch to Parsing Tab
        await tester.tap(find.text('Parsing'));
        await tester.pumpAndSettle();
        expect(find.text('Raw Extracted Text Preview'), findsOneWidget);
        expect(find.text('Text selectable in PDF'), findsOneWidget);
        expect(find.text('Section headings recognized'), findsOneWidget);
        expect(find.text('9 Deterministic Parser Checks'), findsOneWidget);

        // Toggle raw preview switch
        await tester.tap(find.byType(Switch));
        await tester.pumpAndSettle();
        expect(find.textContaining('JOHN DOE'), findsOneWidget);
      },
    );
  });

  group('AI Credits Authoritative Ledger & Support Dispute', () {
    testWidgets(
      'dispute support modal safely pre-fills and protects user privacy',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          _wrap(
            Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => showBillingSupportModal(context),
                child: const Text('Open Support'),
              ),
            ),
            overrides: [
              aiCreditsRepositoryProvider.overrideWithValue(
                const MockAiCreditsRepository(delay: Duration.zero),
              ),
            ],
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('Open Support'));
        await tester.pumpAndSettle();

        expect(find.text('Credit & Billing Support'), findsOneWidget);
        expect(find.text('Issue Category'), findsOneWidget);
        expect(
          find.textContaining(
            'Privacy protected: We never ask for or log full card numbers',
          ),
          findsOneWidget,
        );

        // Fill in description
        await tester.enterText(
          find.widgetWithText(
            TextField,
            'Describe what happened with your credit balance or payment...',
          ),
          'Credits were reserved for optimization run but generation failed gracefully.',
        );
        await tester.pumpAndSettle();

        // Submit dispute ticket
        await tester.tap(find.text('Submit Support Ticket'));
        await tester.pumpAndSettle();
        expect(find.textContaining('Support ticket submitted'), findsOneWidget);
      },
    );
  });
}
