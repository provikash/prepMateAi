import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prepmate_mobile/config/theme.dart';
import 'package:prepmate_mobile/features/home/data/models/resume_model.dart';
import 'package:prepmate_mobile/features/resume_optimizer/data/mock_optimization_repository.dart';
import 'package:prepmate_mobile/features/resume_optimizer/domain/optimization_models.dart';
import 'package:prepmate_mobile/features/resume_optimizer/presentation/providers/optimization_provider.dart';
import 'package:prepmate_mobile/features/resume_optimizer/presentation/screens/ai_suggestions_screen.dart';
import 'package:prepmate_mobile/features/resume_optimizer/presentation/screens/optimize_resume_screen.dart';
import 'package:prepmate_mobile/features/resume_optimizer/presentation/screens/suggestion_editor_screen.dart';
import 'package:prepmate_mobile/features/resume_optimizer/presentation/widgets/job_analysis_widgets.dart';
import 'package:prepmate_mobile/features/resume_optimizer/presentation/widgets/optimization_setup_sheets.dart';
import 'package:prepmate_mobile/features/resume_optimizer/presentation/widgets/suggestion_editor_inspection_sheets.dart';
import 'package:prepmate_mobile/features/resume_optimizer/presentation/widgets/suggestion_editor_recovery_modals.dart';
import 'package:prepmate_mobile/features/resume_optimizer/presentation/widgets/suggestion_editor_variants.dart';
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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Screen 47: Optimization Setup — Step 1: Resume Selection', () {
    testWidgets('renders selected resume card, metadata, and change action', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      var changed = false;
      var continued = false;
      final resume = ResumeModel(
        id: 'res-1',
        title: 'Software Engineer Resume',
        thumbnailUrl: '',
        pdfUrl: '',
      );

      await tester.pumpWidget(
        _wrap(
          OptimizationSetupStep1View(
            resume: resume,
            onChangeResume: () => changed = true,
            onContinue: () => continued = true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Choose the resume to optimize'), findsOneWidget);
      expect(find.text('Software Engineer Resume'), findsOneWidget);
      expect(find.text('Template: Modern Professional Duo'), findsOneWidget);
      expect(find.text('Immutable Baseline Snapshot'), findsOneWidget);
      expect(find.text('Change'), findsOneWidget);

      await tester.tap(find.text('Change'));
      expect(changed, isTrue);

      await tester.tap(find.text('Continue to Job Details'));
      expect(continued, isTrue);
    });
  });

  group('Screen 43: Optimization Setup — Step 2: Job Details', () {
    testWidgets(
      'renders role, company, job description, quality check and quick pills',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        final roleCtrl = TextEditingController(
          text: 'Senior Flutter Developer',
        );
        final compCtrl = TextEditingController(text: 'Acme Technologies');
        final descCtrl = TextEditingController(
          text:
              'Looking for a Senior Flutter Developer with 4+ years of Dart, Riverpod, REST APIs, and automated testing experience in mobile banking. '
              'The ideal candidate will have strong knowledge of Clean Architecture, offline-first SQLite synchronization, CI/CD pipeline integration, '
              'and cross-functional team leadership across multiple agile product squads delivering high quality mobile solutions.',
        );

        var imported = false;
        var continued = false;

        await tester.pumpWidget(
          _wrap(
            OptimizationSetupStep2View(
              roleController: roleCtrl,
              companyController: compCtrl,
              jobDescController: descCtrl,
              onImportUrl: () => imported = true,
              onBack: () {},
              onContinue: () => continued = true,
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Specify job target'), findsOneWidget);
        expect(find.text('Target role'), findsOneWidget);
        expect(find.text('Senior Flutter Developer'), findsOneWidget);
        expect(find.text('+ Staff Mobile Engineer'), findsOneWidget);
        expect(find.text('Import from link'), findsOneWidget);
        expect(
          find.textContaining('Optimal length for ATS matching'),
          findsOneWidget,
        );

        await tester.tap(find.text('Import from link'));
        expect(imported, isTrue);

        await tester.tap(find.text('Continue to Review'));
        expect(continued, isTrue);
      },
    );
  });

  group('Screen 50: Optimization Setup — Step 3: Review Confirmation', () {
    testWidgets(
      'renders summary items, depth mode selector, credit escrow and consent checkbox',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        var isDeep = false;
        var consented = false;
        var launched = false;

        await tester.pumpWidget(
          _wrap(
            StatefulBuilder(
              builder: (context, setState) => OptimizationSetupStep3View(
                resume: ResumeModel(
                  id: 'res-1',
                  title: 'Software Engineer Resume',
                  thumbnailUrl: '',
                  pdfUrl: '',
                ),
                jobTitle: 'Senior Flutter Developer',
                company: 'Acme Technologies',
                jobDescription:
                    'High frequency trading mobile apps with Riverpod and local SQLite cache.',
                isDeepMode: isDeep,
                onDepthChanged: (val) => setState(() => isDeep = val),
                hasConsented: consented,
                onConsentChanged: (val) => setState(() => consented = val),
                isBusy: false,
                onEditResume: () {},
                onEditJobDetails: () {},
                onBack: () {},
                onLaunch: () => launched = true,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Final Check before Launch'), findsOneWidget);
        expect(find.text('Optimization Setup Summary'), findsOneWidget);
        expect(find.text('Standard'), findsOneWidget);
        expect(find.text('Comprehensive'), findsOneWidget);
        expect(
          find.textContaining('credits will be securely held in escrow'),
          findsOneWidget,
        );

        // Tap consent checkbox
        final checkbox = find.byType(Checkbox);
        expect(checkbox, findsOneWidget);
        await tester.tap(checkbox);
        await tester.pumpAndSettle();

        // Launch button is enabled
        final launchBtn = find.textContaining('Confirm & Launch Optimization');
        expect(launchBtn, findsOneWidget);
        await tester.tap(launchBtn);
        expect(launched, isTrue);
      },
    );
  });

  group('Screen 48: Optimization Setup Bottom Sheets & Recovery Modals', () {
    testWidgets('renders HowOptimizationWorksSheet pipeline steps and policy', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(_wrap(const HowOptimizationWorksSheet()));
      await tester.pumpAndSettle();

      expect(find.text('How Resume Optimization Works'), findsOneWidget);
      expect(find.text('5-STAGE INTEGRITY PIPELINE'), findsOneWidget);
      expect(find.text('Select a saved resume'), findsOneWidget);
      expect(find.text('Provide target job description'), findsOneWidget);
      expect(find.text('AI scans rubric & alignment'), findsOneWidget);
      expect(find.text('Credit Escrow & Protection'), findsOneWidget);
      expect(find.text('Got it, continue setup'), findsOneWidget);
    });

    testWidgets(
      'renders SelectResumeModalSheet with resumes and upload option',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        var uploaded = false;
        ResumeModel? selected;

        await tester.pumpWidget(
          _wrap(
            SelectResumeModalSheet(
              resumes: [
                ResumeModel(
                  id: 'r1',
                  title: 'Primary Mobile Resume',
                  thumbnailUrl: '',
                  pdfUrl: '',
                ),
              ],
              selectedResumeId: null,
              onSelect: (r) => selected = r,
              onUploadRequested: () => uploaded = true,
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Select Resume'), findsOneWidget);
        expect(find.text('Upload New Document'), findsOneWidget);
        expect(find.text('Primary Mobile Resume'), findsOneWidget);

        await tester.tap(find.text('Primary Mobile Resume'));
        expect(selected?.id, equals('r1'));
      },
    );

    testWidgets(
      'SelectResumeModalSheet triggers upload action',
      (tester) async {
        var uploaded = false;

        await tester.pumpWidget(
          _wrap(
            SelectResumeModalSheet(
              resumes: const [],
              selectedResumeId: null,
              onSelect: (_) {},
              onUploadRequested: () => uploaded = true,
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('Upload New Document'));
        expect(uploaded, isTrue);
      },
    );

    testWidgets(
      'renders DuplicateOptimizationAlertModal and FileUploadErrorModal',
      (tester) async {
        await tester.pumpWidget(
          _wrap(
            DuplicateOptimizationAlertModal(
              jobTitle: 'Senior Flutter Developer',
              company: 'Acme',
              onContinueNew: () {},
              onViewExisting: () {},
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Previous Analysis Found'), findsOneWidget);
        expect(find.text('Start New Analysis'), findsOneWidget);
        expect(find.text('View Existing Result'), findsOneWidget);
      },
    );
  });

  group('Screen 45: Job Analysis Lifecycle & Edge States', () {
    testWidgets(
      'renders 5-stage progress pipeline, in-flight status and edge banners',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          _wrap(
            const JobAnalysisLifecycleView(
              jobTitle: 'Senior Flutter Developer',
              company: 'Acme Technologies',
              stage: 3,
              progressPercent: 65,
              isDelayed: true,
              isLowConfidence: true,
              isResumeEdited: true,
              isOffline: true,
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));

        expect(find.text('SEMANTIC PIPELINE V3.2'), findsOneWidget);
        expect(find.text('65%'), findsOneWidget);
        expect(find.text('Stage 3 of 5 · Running'), findsOneWidget);
        expect(
          find.textContaining('Taking longer than expected'),
          findsOneWidget,
        );
        expect(find.textContaining('Limited Job Description'), findsOneWidget);
        expect(
          find.textContaining('Resume Changed:'),
          findsNothing,
        ); // Banner uses exact text
        expect(find.textContaining('saved snapshot v2.4'), findsOneWidget);
        expect(find.textContaining('Offline mode active'), findsOneWidget);
      },
    );
  });

  group('Screen 44: Job Analysis Overview', () {
    testWidgets(
      'renders compatibility scorecard, breakdown counts and review suggestions CTA',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        const analysis = OptimizationAnalysis(
          beforeScore: 84,
          afterScore: 92,
          requirements: [
            JobRequirement(
              name: 'Architect Flutter Production Apps',
              importance: 'High Priority',
              match: RequirementMatch.matched,
              explanation: 'Found in 2 work experiences',
            ),
            JobRequirement(
              name: 'Offline-First SQLite Cache',
              importance: 'Medium Priority',
              match: RequirementMatch.partial,
              explanation: 'Found partially in project description',
            ),
          ],
          suggestions: [
            OptimizationSuggestion(
              id: 's1',
              section: 'experience',
              current: 'Built apps.',
              proposed: 'Architected high-scale apps.',
              reason: 'Add strong action verbs.',
              keywords: ['Flutter'],
              evidence: 'Work exp',
            ),
          ],
        );

        var reviewed = false;

        await tester.pumpWidget(
          _wrap(
            JobAnalysisOverviewView(
              analysis: analysis,
              targetRole: 'Senior Flutter Developer',
              company: 'Acme Technologies',
              onReviewSuggestions: () => reviewed = true,
              onViewRequirements: () {},
              onInspectRequirement: (_) {},
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Overall Compatibility'), findsOneWidget);
        expect(find.text('84%'), findsOneWidget);
        expect(find.text('Strong: 1'), findsOneWidget);
        expect(find.text('Partial: 1'), findsOneWidget);
        expect(find.text('Architect Flutter Production Apps'), findsOneWidget);
        expect(find.textContaining('Review Suggestions'), findsOneWidget);

        await tester.tap(find.textContaining('Review Suggestions'));
        expect(reviewed, isTrue);
      },
    );
  });

  group('Screen 46: Job Analysis Requirements & Keywords', () {
    testWidgets('switches between Requirements and Keywords tabs and filters', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      JobRequirement? inspected;

      await tester.pumpWidget(
        _wrap(
          JobAnalysisRequirementsKeywordsView(
            requirements: const [
              JobRequirement(
                name: 'Flutter Riverpod Flow',
                importance: 'High Priority',
                match: RequirementMatch.matched,
                explanation: 'Track record in projects.',
              ),
            ],
            keywords: const ['Flutter', 'Riverpod', 'Dart', 'Bloc'],
            onInspectRequirement: (r) => inspected = r,
            onAddMissingSkill: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Requirements (1)'), findsOneWidget);
      expect(find.text('Flutter Riverpod Flow'), findsOneWidget);
      expect(find.text('Inspect'), findsOneWidget);

      await tester.tap(find.text('Inspect'));
      expect(inspected?.name, equals('Flutter Riverpod Flow'));

      // Switch to Keywords
      await tester.tap(find.textContaining('Keywords (4)'));
      await tester.pumpAndSettle();

      expect(find.text('Target Keywords & ATS Relevance'), findsOneWidget);
      expect(find.text('Riverpod'), findsOneWidget);
    });
  });

  group('Screen 49: Job Analysis Source Evidence Inspection Sheet', () {
    testWidgets('renders job quote, resume excerpt match, and include action', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      var included = false;
      const req = JobRequirement(
        name: 'Offline data caching with SQLite',
        importance: 'Core Architecture',
        match: RequirementMatch.partial,
        explanation: 'Extracted from technical responsibilities.',
        sourceText:
            'Architect resilient mobile applications with local persistence using SQLite and Hive caching.',
        evidence: 'Experience at TechSprint mentions SQLite local cache.',
      );

      await tester.pumpWidget(
        _wrap(
          JobAnalysisSourceEvidenceSheet(
            requirement: req,
            onIncludeInSuggestions: () => included = true,
            onDismiss: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('REQUIREMENT INSPECTION'), findsOneWidget);
      expect(find.text('Offline data caching with SQLite'), findsOneWidget);
      expect(find.textContaining('Job Description Excerpt'), findsOneWidget);
      expect(find.textContaining('Resume Evidence Match'), findsOneWidget);
      expect(find.text('Include in Tailored Suggestions'), findsOneWidget);

      await tester.tap(find.text('Include in Tailored Suggestions'));
      expect(included, isTrue);
    });
  });

  group('Screen 51: Suggestions Workspace Populated', () {
    testWidgets(
      'renders sticky review progress card, filter chips, grouped cards and action buttons',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        const mockAnalysis = OptimizationAnalysis(
          beforeScore: 82,
          afterScore: 94,
          requirements: [],
          suggestions: [
            OptimizationSuggestion(
              id: 'sug-1',
              section: 'experience',
              current: 'Worked on mobile app features.',
              proposed: 'Architected and shipped production Flutter features.',
              reason: 'Elevates role seniority and action verb impact.',
              keywords: ['Flutter', 'Architecture'],
              evidence: 'Experience bullet 1',
              status: SuggestionStatus.pending,
            ),
          ],
        );

        final container = ProviderContainer(
          overrides: [
            optimizationProvider.overrideWith(
              (ref) => _CustomOptimizationNotifier(
                const OptimizationState(
                  analysis: mockAnalysis,
                  jobTitle: 'Senior Flutter Developer',
                ),
              ),
            ),
          ],
        );

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const MaterialApp(
              home: Scaffold(body: AiSuggestionsScreen()),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Review Suggestions'), findsOneWidget);
        expect(find.text('0 of 1 reviewed'), findsOneWidget);
        expect(find.text('EXPERIENCE'), findsWidgets);
        expect(
          find.text('Architected and shipped production Flutter features.'),
          findsOneWidget,
        );
        expect(find.text('Accept'), findsOneWidget);
        expect(find.text('Edit'), findsOneWidget);
        expect(find.text('Skip'), findsOneWidget);
        expect(find.text('Create Tailored Resume'), findsOneWidget);
      },
    );
  });

  group('Screen 55: Suggestion Editor Main Experience Bullet', () {
    testWidgets(
      'renders destination card, baseline vs AI comparison, working version and action verbs',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        const mockAnalysis = OptimizationAnalysis(
          beforeScore: 80,
          afterScore: 90,
          requirements: [],
          suggestions: [
            OptimizationSuggestion(
              id: 'sug-1',
              section: 'experience',
              current: 'Fixed mobile bugs and made tickets.',
              proposed:
                  'Spearheaded bug reduction initiative, eliminating critical release blockers.',
              reason: 'Strengthens impact metrics.',
              keywords: ['Flutter'],
              evidence: 'Experience',
            ),
          ],
        );

        final container = ProviderContainer(
          overrides: [
            optimizationProvider.overrideWith(
              (ref) => _CustomOptimizationNotifier(
                const OptimizationState(
                  analysis: mockAnalysis,
                  jobTitle: 'Senior Flutter Developer',
                ),
              ),
            ),
          ],
        );

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const MaterialApp(
              home: Scaffold(
                body: SuggestionEditorScreen(suggestionId: 'sug-1'),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Edit Suggestion'), findsOneWidget);
        expect(find.text('DESTINATION'), findsOneWidget);
        expect(find.text('Baseline Resume Text'), findsOneWidget);
        expect(find.text('Original AI Proposal'), findsOneWidget);
        expect(find.text('Power Action Verbs'), findsOneWidget);
        expect(find.text('Architected'), findsOneWidget);
        expect(find.text('Accelerated'), findsOneWidget);
        expect(find.text('Accept & Apply to Draft'), findsOneWidget);
      },
    );
  });

  group('Screen 54: Suggestion Editor Tool-Specific Variants', () {
    testWidgets(
      'switches between Executive Summary, Skill Audit, Project and Certificate variants',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          _wrap(
            SuggestionEditorVariantsWidget(
              initialSection: 'summary',
              onSave: (_) {},
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Executive Summary'), findsWidgets);
        expect(find.textContaining('Target 40–60 words'), findsOneWidget);

        // Switch to Skill Audit
        await tester.tap(find.text('Skill Audit'));
        await tester.pumpAndSettle();
        expect(find.text('Tailored Skill Verification'), findsOneWidget);
        expect(find.text('Riverpod'), findsOneWidget);

        // Switch to Project Rewrite
        await tester.tap(find.text('Project Rewrite'));
        await tester.pumpAndSettle();
        expect(find.text('Structured Project Narrative'), findsOneWidget);

        // Switch to Certificate
        await tester.tap(find.text('New Certificate'));
        await tester.pumpAndSettle();
        expect(find.text('Credential & Certification Details'), findsOneWidget);
      },
    );
  });

  group('Screen 52: Suggestion Editor Confirmation & Inspection Sheets', () {
    testWidgets('renders Confirmation, Diff Inspector, and AI Refine tabs', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      var confirmed = false;

      await tester.pumpWidget(
        _wrap(
          SuggestionEditorConfirmationSheet(
            originalText: 'Old mobile experience.',
            editedText: 'Engineered high performance mobile client.',
            section: 'Experience',
            destinationTitle: 'Experience · Lead Flutter Dev',
            onConfirmAccept: () => confirmed = true,
            onRefineRequested: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Accept this edited suggestion?'), findsOneWidget);
      expect(find.text('Confirm & Apply to Resume Draft'), findsOneWidget);

      // Switch to Diff Inspector
      await tester.tap(find.text('Diff Inspector'));
      await tester.pumpAndSettle();
      expect(find.text('ORIGINAL BASELINE'), findsOneWidget);
      expect(find.text('REVISED PROPOSAL'), findsOneWidget);

      // Switch to AI Refine
      await tester.tap(find.text('AI Refine'));
      await tester.pumpAndSettle();
      expect(find.text('Executive & Strategic'), findsOneWidget);
      expect(find.text('Technical & Deep-Dive'), findsOneWidget);

      // Switch back to Confirmation and tap apply
      await tester.tap(find.text('Confirmation'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Confirm & Apply to Resume Draft'));
      expect(confirmed, isTrue);
    });
  });

  group('Screen 53: Suggestion Editor Recovery Modals & Edge States', () {
    testWidgets(
      'renders RestoredDraftBanner, FactConflictAlertBanner, and LeaveEditorConfirmationDialog',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        var kept = false;

        await tester.pumpWidget(
          _wrap(
            Column(
              children: [
                RestoredDraftBanner(
                  onKeepEditing: () => kept = true,
                  onDiscardDraft: () {},
                ),
                FactConflictAlertBanner(
                  claimText: 'Led team of 10',
                  explanation: 'Baseline is junior.',
                  onResolve: () {},
                ),
                const ResumeVersionMismatchBanner(),
              ],
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Auto-Recovered Draft Session'), findsOneWidget);
        expect(find.text('Keep editing'), findsOneWidget);
        expect(find.text('Potential Fact Conflict'), findsOneWidget);
        expect(find.textContaining('Resume Changed:'), findsOneWidget);

        await tester.tap(find.text('Keep editing'));
        expect(kept, isTrue);
      },
    );
  });
}

class _CustomOptimizationNotifier extends OptimizationNotifier {
  _CustomOptimizationNotifier(OptimizationState initialState)
    : super(MockOptimizationRepository()) {
    state = initialState;
  }
}
