import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prepmate_mobile/config/theme.dart';
import 'package:prepmate_mobile/features/ai_credits/domain/entities/ai_credit_models.dart';
import 'package:prepmate_mobile/features/ai_credits/presentation/viewmodels/ai_credit_state.dart';
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

OptimizationAnalysis _mockAnalysis() {
  final suggestions = <OptimizationSuggestion>[
    const OptimizationSuggestion(
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
    const OptimizationSuggestion(
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
    const OptimizationSuggestion(
      id: 'sug-3',
      section: 'Work Experience',
      current: 'Handled team meetings',
      proposed: 'Mentored 6 engineers across 2 cross-functional product squads',
      reason: 'Demonstrate leadership',
      keywords: ['leadership'],
      evidence: 'Team mentoring experience',
      status: SuggestionStatus.accepted,
      highImpact: false,
    ),
    const OptimizationSuggestion(
      id: 'sug-4',
      section: 'Core Skills',
      current: 'Dart, Java',
      proposed: 'Dart, Riverpod, SQLite, CI/CD, REST APIs',
      reason: 'Highlight job-critical technical skills',
      keywords: ['Riverpod', 'CI/CD'],
      evidence: 'Dart and state management',
      status: SuggestionStatus.accepted,
      highImpact: true,
    ),
    const OptimizationSuggestion(
      id: 'sug-5',
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

  return OptimizationAnalysis(
    beforeScore: 68,
    afterScore: 92,
    beforeAtsScore: 64,
    afterAtsScore: 90,
    requirements: const [
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
        name: 'Cloud Orchestration',
        category: 'DevOps',
        match: RequirementMatch.partial,
        evidence: 'Basic CI/CD pipeline experience',
        importance: 'Medium',
        explanation: 'Partial CI/CD background',
      ),
      JobRequirement(
        id: 'req-4',
        name: 'Kubernetes Cluster Setup',
        category: 'Infrastructure',
        match: RequirementMatch.missing,
        evidence: 'Not clearly found in resume',
        importance: 'Low',
        explanation: 'Skill not clearly found in baseline',
      ),
    ],
    suggestions: suggestions,
    totalRequirements: 4,
    matchedCount: 2,
    partialCount: 1,
    missingCount: 1,
    unclearCount: 0,
    sourceResumeVersion: 1,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  // ===========================================================================
  // SCREEN 56: Optimization Summary — Ready to Create
  // ===========================================================================
  group('Screen 56: Optimization Summary — Ready to Create', () {
    testWidgets(
      'renders role context, readiness card, bento stats, and create action',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        final analysis = _mockAnalysis();
        final resume = ResumeModel(
          id: 'res-1',
          title: 'Software Engineer Resume (v2.4)',
          thumbnailUrl: '',
          pdfUrl: '',
        );

        final notifier = OptimizationNotifier(MockOptimizationRepository());
        notifier.selectResume(resume);
        notifier.state = notifier.state.copyWith(
          analysis: analysis,
          jobTitle: 'Senior Flutter Developer',
          company: 'Acme Technologies',
          jobDescription: 'Building mobile apps',
        );

        await tester.pumpWidget(
          _wrap(
            const OptimizationSummaryScreen(),
            overrides: [optimizationProvider.overrideWith((ref) => notifier)],
          ),
        );
        await tester.pumpAndSettle();

        // Verify Header & Context
        expect(find.text('Optimization Summary'), findsWidgets);
        expect(
          find.textContaining('Senior Flutter Developer at Acme Technologies'),
          findsOneWidget,
        );

        // Verify Screen 56 Calm Readiness Card
        expect(
          find.text('Ready to create your optimized resume'),
          findsOneWidget,
        );
        expect(
          find.textContaining('All 5 suggestions have been reviewed'),
          findsOneWidget,
        );

        // Verify Review Breakdown Bento Grid
        expect(find.text('Accepted'), findsOneWidget);
        expect(find.text('Edited'), findsOneWidget);
        expect(find.text('Skipped'), findsOneWidget);
        expect(find.text('Unresolved'), findsWidgets);

        // Verify Primary Action Button
        expect(find.text('Create resume'), findsOneWidget);
        expect(find.text('Preview'), findsOneWidget);
      },
    );
  });

  // ===========================================================================
  // SCREEN 60: Optimization Summary — Lifecycle & Edge States
  // ===========================================================================
  group('Screen 60: Optimization Summary — Lifecycle & Edge States', () {
    testWidgets(
      'renders edge states selector, in-flight pipeline, conflict and offline banner',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        final analysis = _mockAnalysis();
        final resume = ResumeModel(
          id: 'res-1',
          title: 'Master Resume',
          thumbnailUrl: '',
          pdfUrl: '',
        );

        final notifier = OptimizationNotifier(MockOptimizationRepository());
        notifier.selectResume(resume);
        notifier.state = notifier.state.copyWith(
          analysis: analysis,
          summaryEdgeState: 'in-flight',
        );

        await tester.pumpWidget(
          _wrap(
            const OptimizationSummaryScreen(),
            overrides: [optimizationProvider.overrideWith((ref) => notifier)],
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // In-flight creating stepper
        expect(find.text('Creating Optimized Resume'), findsOneWidget);
        expect(find.text('1. Validating decisions'), findsOneWidget);
        expect(find.text('2. Creating résumé version'), findsOneWidget);
        expect(find.text('3. Applying confirmed changes'), findsOneWidget);
        expect(find.text('4. Preparing document preview'), findsOneWidget);

        // Switch to Source Changed (conflict)
        await tester.tap(find.text('Source Changed'));
        await tester.pumpAndSettle();
        expect(find.text('Source Resume Modified in Parallel'), findsOneWidget);
        expect(find.text('Create copy from snapshot'), findsOneWidget);
        expect(find.text('Review conflicts'), findsOneWidget);

        // Switch to Offline
        await tester.ensureVisible(find.text('Offline'));
        await tester.tap(find.text('Offline'));
        await tester.pumpAndSettle();
        expect(
          find.textContaining('Offline mode · Viewing cached summary'),
          findsOneWidget,
        );
      },
    );
  });

  // ===========================================================================
  // SCREEN 62: Optimization Summary — Sections & Confirmations
  // ===========================================================================
  group('Screen 62: Optimization Summary — Sections & Confirmations', () {
    testWidgets(
      'renders section cards, accuracy confirmation, and skipped suggestions',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        final analysis = _mockAnalysis();
        final resume = ResumeModel(
          id: 'res-1',
          title: 'Master Resume',
          thumbnailUrl: '',
          pdfUrl: '',
        );

        final notifier = OptimizationNotifier(MockOptimizationRepository());
        notifier.selectResume(resume);
        notifier.state = notifier.state.copyWith(analysis: analysis);

        await tester.pumpWidget(
          _wrap(
            const OptimizationSummaryScreen(),
            overrides: [optimizationProvider.overrideWith((ref) => notifier)],
          ),
        );
        await tester.pumpAndSettle();

        // Changes by Section Cards
        expect(find.text('Changes by Section'), findsOneWidget);
        expect(find.text('Professional Summary'), findsWidgets);
        expect(find.text('Work Experience'), findsWidgets);
        expect(find.text('Core Skills'), findsWidgets);

        // Accuracy Confirmation Checkbox
        expect(
          find.textContaining(
            'I have reviewed the accepted changes and confirm that they accurately reflect my genuine skills',
          ),
          findsOneWidget,
        );

        // Skipped Suggestions Collapsed Section
        await tester.scrollUntilVisible(
          find.text('1 Skipped suggestions'),
          300,
          scrollable: find.byType(Scrollable).first,
        );
        expect(find.text('1 Skipped suggestions'), findsOneWidget);
        await tester.tap(find.text('1 Skipped suggestions'));
        await tester.pumpAndSettle();
        expect(find.text('Review Again'), findsOneWidget);

        // Tap Create Resume without confirmation -> Shows validation snackbar
        await tester.tap(find.text('Create resume'));
        await tester.pumpAndSettle();
        expect(
          find.text('Please check the accuracy confirmation to proceed.'),
          findsOneWidget,
        );

        // Check confirmation box -> becomes confirmed
        await tester.tap(find.byType(Checkbox).first);
        await tester.pumpAndSettle();
        expect(notifier.state.isAccuracyConfirmed, isTrue);
      },
    );
  });

  // ===========================================================================
  // SCREEN 57: ATS Analysis — Overview
  // ===========================================================================
  group('Screen 57: ATS Analysis — Overview', () {
    testWidgets(
      'renders readiness match score, diagnostic categories, and methodology modal',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        final analysis = _mockAnalysis();
        final notifier = OptimizationNotifier(MockOptimizationRepository());
        notifier.state = notifier.state.copyWith(
          analysis: analysis,
          jobTitle: 'Senior Flutter Developer',
          company: 'Acme Technologies',
          jobDescription: 'Building mobile apps',
        );

        await tester.pumpWidget(
          _wrap(
            const AtsAnalysisScreen(),
            overrides: [optimizationProvider.overrideWith((ref) => notifier)],
          ),
        );
        await tester.pumpAndSettle();

        // Context Strip & Match Badge
        expect(find.text('ATS Analysis'), findsWidgets);
        expect(find.text('90% Match'), findsOneWidget);

        // PrepMate Readiness Score Card with Disclaimer
        expect(find.text('PrepMate Readiness Score'), findsOneWidget);
        expect(
          find.textContaining(
            'Calculated from deterministic parsing & evidence alignment',
          ),
          findsOneWidget,
        );

        // Diagnostic Category Checks
        expect(find.text('File compatibility'), findsOneWidget);
        expect(find.text('Text extraction'), findsOneWidget);
        expect(find.text('Reading order flow'), findsOneWidget);
        expect(find.text('Typography & glyphs'), findsOneWidget);

        // Methodology Dialog
        await tester.tap(find.byIcon(Icons.info_outline).first);
        await tester.pumpAndSettle();
        expect(find.text('ATS Analysis Methodology'), findsOneWidget);
        expect(find.text('How This Is Calculated'), findsOneWidget);
        expect(
          find.textContaining('deterministic parsing integrity'),
          findsOneWidget,
        );

        await tester.tap(find.text('Understand & Close'));
        await tester.pumpAndSettle();
      },
    );
  });

  // ===========================================================================
  // SCREEN 64: ATS Analysis — Job Alignment & Parsing Tabs
  // ===========================================================================
  group('Screen 64: ATS Analysis — Job Alignment & Parsing Tabs', () {
    testWidgets(
      'switches across Overview, Parsing, Alignment, Content tabs with raw preview',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        final analysis = _mockAnalysis();
        final notifier = OptimizationNotifier(MockOptimizationRepository());
        notifier.state = notifier.state.copyWith(analysis: analysis);

        await tester.pumpWidget(
          _wrap(
            const AtsAnalysisScreen(),
            overrides: [optimizationProvider.overrideWith((ref) => notifier)],
          ),
        );
        await tester.pumpAndSettle();

        // Verify 4 Standard Tabs (Zero fake vendor tabs)
        expect(find.text('Overview'), findsOneWidget);
        expect(find.text('Parsing'), findsOneWidget);
        expect(find.text('Alignment'), findsOneWidget);
        expect(find.text('Content'), findsOneWidget);

        // Switch to Parsing Tab
        await tester.tap(find.text('Parsing'));
        await tester.pumpAndSettle();
        expect(find.text('Raw Extracted Text Preview'), findsOneWidget);
        expect(find.text('Contact details detected'), findsOneWidget);
        expect(find.text('Section headings recognized'), findsOneWidget);

        // Switch to Alignment Tab
        await tester.tap(find.text('Alignment'));
        await tester.pumpAndSettle();
        expect(find.text('Matched Requirements'), findsOneWidget);
        expect(find.text('Flutter Architecture'), findsOneWidget);
        expect(find.text('Cloud Orchestration'), findsOneWidget);
        expect(find.text('Kubernetes Cluster Setup'), findsOneWidget);

        // Switch to Content Tab
        await tester.tap(find.text('Content'));
        await tester.pumpAndSettle();
        expect(find.text('Professional summary clarity'), findsOneWidget);
        expect(find.text('Action verbs & active voice'), findsOneWidget);
      },
    );
  });

  // ===========================================================================
  // SCREEN 63: Optimized Resume — Document Viewer
  // ===========================================================================
  group('Screen 63: Optimized Resume — Document Viewer', () {
    testWidgets(
      'renders document viewer, zoom controls, template switcher, and export bar',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        final analysis = _mockAnalysis();
        final resume = ResumeModel(
          id: 'res-1',
          title: 'Master Resume',
          thumbnailUrl: '',
          pdfUrl: '',
        );

        final notifier = OptimizationNotifier(MockOptimizationRepository());
        notifier.selectResume(resume);
        notifier.state = notifier.state.copyWith(
          analysis: analysis,
          viewerMode: 'optimized',
          finalizedVersionId: 'ver-123',
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

        // Title & Version Banner
        expect(find.text('Optimized Resume'), findsWidgets);
        expect(find.text('CURRENT VERSION'), findsOneWidget);

        // Three Mode Toggles: Optimized, Source, Changes
        expect(find.text('Optimized'), findsOneWidget);
        expect(find.text('Source'), findsOneWidget);
        expect(find.textContaining('Changes'), findsOneWidget);

        // Zoom Controls
        expect(find.byIcon(Icons.add), findsOneWidget);
        expect(find.byIcon(Icons.remove), findsOneWidget);
        expect(find.byIcon(Icons.fit_screen), findsOneWidget);

        // Bottom Action Bar
        expect(find.text('Edit in Builder'), findsOneWidget);
        expect(find.text('Share PDF'), findsOneWidget);
      },
    );
  });

  // ===========================================================================
  // SCREEN 58: Optimized Resume — Lifecycle & Recovery States
  // ===========================================================================
  group('Screen 58: Optimized Resume — Lifecycle & Recovery States', () {
    testWidgets(
      'renders outdated PDF warning banner, error recovery and simulated canvas',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        final analysis = _mockAnalysis();
        final resume = ResumeModel(
          id: 'res-1',
          title: 'Master Resume',
          thumbnailUrl: '',
          pdfUrl: '',
        );

        final notifier = OptimizationNotifier(MockOptimizationRepository());
        notifier.selectResume(resume);
        notifier.state = notifier.state.copyWith(
          analysis: analysis,
          pdfStatus: 'outdated',
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

        // Outdated PDF Banner
        expect(find.text('Document Outdated'), findsOneWidget);
        expect(find.text('Update Preview'), findsOneWidget);
        expect(
          find.textContaining('Changes were made since this PDF was generated'),
          findsOneWidget,
        );
      },
    );
  });

  // ===========================================================================
  // SCREEN 59: Optimized Resume — Source Comparison & Information
  // ===========================================================================
  group('Screen 59: Optimized Resume — Source Comparison & Information', () {
    testWidgets(
      'renders source vs optimized comparison, sub-modes, and document info sheet',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        final analysis = _mockAnalysis();
        final resume = ResumeModel(
          id: 'res-1',
          title: 'Master Resume',
          thumbnailUrl: '',
          pdfUrl: '',
        );

        final notifier = OptimizationNotifier(MockOptimizationRepository());
        notifier.selectResume(resume);
        notifier.state = notifier.state.copyWith(
          analysis: analysis,
          viewerMode: 'source',
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

        // Comparison Sub-modes: Source, Optimized, Difference
        expect(find.text('Difference'), findsOneWidget);
        expect(find.text('ORIGINAL SOURCE'), findsWidgets);
        expect(find.text('FINAL OPTIMIZED'), findsWidgets);

        // Open Document Information Sheet (Screen 59)
        await tester.tap(find.byIcon(Icons.info_outline).first);
        await tester.pumpAndSettle();
        expect(find.text('Document Information'), findsOneWidget);
        expect(find.text('Private Storage'), findsOneWidget);
        expect(
          find.text('Saved securely to your PrepMate account'),
          findsOneWidget,
        );

        await tester.tap(find.text('Close'));
        await tester.pumpAndSettle();
      },
    );
  });

  // ===========================================================================
  // SCREEN 61: Optimized Resume — Changes Mode & Details
  // ===========================================================================
  group('Screen 61: Optimized Resume — Changes Mode & Details', () {
    testWidgets(
      'renders change navigator strip, baseline diff, and revert change action',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        final analysis = _mockAnalysis();
        final resume = ResumeModel(
          id: 'res-1',
          title: 'Master Resume',
          thumbnailUrl: '',
          pdfUrl: '',
        );

        final notifier = OptimizationNotifier(MockOptimizationRepository());
        notifier.selectResume(resume);
        notifier.state = notifier.state.copyWith(
          analysis: analysis,
          viewerMode: 'changes',
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

        // Change Navigator Strip
        expect(find.textContaining('Change 1 of'), findsOneWidget);
        expect(find.text('PROPOSED IMPROVEMENT'), findsOneWidget);
        expect(find.text('ORIGINAL BASELINE'), findsOneWidget);

        // Revert This Change Action
        expect(find.text('Revert This Change'), findsOneWidget);
        expect(
          find.textContaining(
            'Reverting affects only this draft version. Master resume stays 100% safe.',
          ),
          findsOneWidget,
        );

        // Tap Revert -> Shows confirmation dialog
        await tester.tap(find.text('Revert This Change'));
        await tester.pumpAndSettle();
        expect(find.text('Revert this change?'), findsOneWidget);
        expect(find.text('Keep Change'), findsOneWidget);
        expect(find.text('Revert'), findsOneWidget);

        await tester.tap(find.text('Keep Change'));
        await tester.pumpAndSettle();
      },
    );
  });

  // ===========================================================================
  // SCREEN 68: AI Credits — Dashboard
  // ===========================================================================
  group('Screen 68: AI Credits — Dashboard', () {
    testWidgets(
      'renders balance hero, reserved credits pill, upcoming schedule and ledger',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        final account = AiCreditAccount(
          balance: 24,
          reservedCredits: 3,
          monthlyAllocation: 100,
          usedThisCycle: 76,
          resetDate: DateTime(2026, 11, 1),
        );

        final state = AiCreditState(
          status: AiCreditStatus.loaded,
          account: account,
          operations: const [
            AiOperation(
              operation: 'resume_optimization',
              displayName: 'Full Resume Optimization',
              description: 'Align resume to job requirements',
              creditCost: 10,
            ),
            AiOperation(
              operation: 'summary',
              displayName: 'Professional Summary',
              description: 'Tailor summary section',
              creditCost: 2,
            ),
          ],
        );

        await tester.pumpWidget(_wrap(AiCreditsDashboardView(state: state)));
        await tester.pumpAndSettle();

        // Screen 68 Balance Hero Card
        expect(find.text('Available credits'), findsOneWidget);
        expect(find.text('21'), findsWidgets); // 24 - 3 reserved
        expect(find.text('3 credits reserved'), findsOneWidget);
        expect(
          find.text('24 total balance including active reservations'),
          findsOneWidget,
        );
        expect(find.text('View credit options & packs'), findsOneWidget);

        // Upcoming Schedule Card
        expect(find.text('Upcoming schedule'), findsOneWidget);
        expect(find.text('+100 plan credits'), findsOneWidget);

        // Reconciled Ledger
        expect(find.text('Credit balance breakdown'), findsOneWidget);
        expect(find.text('Healthy Ledger'), findsOneWidget);
        expect(find.text('AVAILABLE'), findsOneWidget);
        expect(find.text('RESERVED'), findsOneWidget);
      },
    );
  });

  // ===========================================================================
  // SCREEN 66: AI Credits — Account Variants & Zero State
  // ===========================================================================
  group('Screen 66: AI Credits — Account Variants & Zero State', () {
    testWidgets(
      'switches between Zero State (State A), Enterprise (State B), and Restricted (State C)',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        final account = AiCreditAccount(
          balance: 0,
          reservedCredits: 0,
          monthlyAllocation: 10,
          usedThisCycle: 10,
          resetDate: DateTime(2026, 11, 1),
        );

        await tester.pumpWidget(
          _wrap(AiCreditsAccountVariantsView(account: account)),
        );
        await tester.pumpAndSettle();

        // State A: Zero State
        expect(find.text('Current Balance'), findsOneWidget);
        expect(find.text('0'), findsWidgets);
        expect(find.text('View credit options'), findsOneWidget);
        expect(find.text('Browse free tools'), findsOneWidget);
        expect(find.text('Included Without Credits'), findsOneWidget);
        expect(find.text('ATS Keyword Checker'), findsOneWidget);
        expect(find.text('Grammar & Formatting'), findsOneWidget);

        // Switch to State B: Enterprise
        await tester.tap(find.text('Enterprise'));
        await tester.pumpAndSettle();
        expect(find.text('UNLIMITED AI ACCESS'), findsOneWidget);
        expect(find.text('Enterprise Pro Subscription'), findsOneWidget);

        // Switch to State C: Restricted
        await tester.tap(find.text('Restricted'));
        await tester.pumpAndSettle();
        expect(find.text('ACCOUNT RESTRICTED'), findsOneWidget);
        expect(find.text('Contact Support'), findsOneWidget);
      },
    );
  });

  // ===========================================================================
  // SCREEN 67: AI Credits — Policy & Inspection Sheets
  // ===========================================================================
  group('Screen 67: AI Credits — Policy & Inspection Sheets', () {
    testWidgets(
      'opens policy sheet, switches between Usage Policy and Live Lock inspection',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        final operations = const [
          AiOperation(
            operation: 'resume_optimization',
            displayName: 'Resume Optimization',
            description: 'Tailor resume',
            creditCost: 10,
          ),
          AiOperation(
            operation: 'summary',
            displayName: 'Summary',
            description: 'Rewrite summary',
            creditCost: 2,
          ),
        ];

        await tester.pumpWidget(
          _wrap(
            Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () => showAiCreditsPolicySheet(
                  ctx,
                  operations: operations,
                  reservedCredits: 3,
                ),
                child: const Text('Open Policy'),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('Open Policy'));
        await tester.pumpAndSettle();

        // Sheet Header & Tabs
        expect(find.text('How AI credits work'), findsOneWidget);
        expect(find.text('Usage Policy'), findsOneWidget);
        expect(find.textContaining('Live Lock'), findsOneWidget);

        // Policy Cards
        expect(find.text('Available credits'), findsOneWidget);
        expect(find.text('Reserved credits'), findsOneWidget);
        expect(find.text('Refund guarantee'), findsOneWidget);
        expect(
          find.text('Tool Costs (Authoritative Backend Rates)'),
          findsOneWidget,
        );

        // Switch to Live Lock Inspection Tab
        await tester.tap(find.textContaining('Live Lock'));
        await tester.pumpAndSettle();
        expect(find.text('Active Live Lock (In Flight)'), findsOneWidget);
        expect(find.textContaining('Task ID: OPT-9812'), findsOneWidget);
        expect(find.text('Get Help'), findsOneWidget);
      },
    );
  });

  // ===========================================================================
  // SCREEN 65: AI Credits — Edge States & Billing Support Modal
  // ===========================================================================
  group('Screen 65: AI Credits — Edge States & Billing Support Modal', () {
    testWidgets(
      'opens billing support modal, validates categories, inputs and privacy note',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          _wrap(
            Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () => showBillingSupportModal(
                  ctx,
                  defaultReference: 'OPT-9812',
                  defaultCategory: 'Reservation stuck',
                ),
                child: const Text('Open Support'),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('Open Support'));
        await tester.pumpAndSettle();

        // Verify Modal Elements
        expect(find.text('Credit & Billing Support'), findsOneWidget);
        expect(find.text('Issue Category'), findsOneWidget);
        expect(find.text('Transaction or Task Reference'), findsOneWidget);
        expect(find.text('OPT-9812'), findsOneWidget);
        expect(
          find.textContaining(
            'Privacy protected: We never ask for or log full card numbers',
          ),
          findsOneWidget,
        );
        expect(find.text('Submit Support Ticket'), findsOneWidget);
      },
    );
  });
}
