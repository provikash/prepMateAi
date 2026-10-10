import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:prepmate_mobile/features/ai_credits/data/repositories/mock_ai_credits_repository.dart';
import 'package:prepmate_mobile/features/ai_credits/domain/entities/ai_credit_models.dart';
import 'package:prepmate_mobile/features/ai_credits/presentation/providers/ai_credits_provider.dart';
import 'package:prepmate_mobile/features/ai_credits/presentation/viewmodels/ai_credit_state.dart';
import 'package:prepmate_mobile/features/ai_credits/presentation/viewmodels/ai_credits_viewmodel.dart';
import 'package:prepmate_mobile/features/home/data/models/resume_model.dart';
import 'package:prepmate_mobile/features/home/presentation/widgets/pages_and_document_info_sheet.dart';
import 'package:prepmate_mobile/features/home/presentation/widgets/save_and_download_sheet.dart';
import 'package:prepmate_mobile/features/home/providers/home_providers.dart'
    as home;
import 'package:prepmate_mobile/features/resume/presentation/screens/ai_assistant_screen.dart';
import 'package:prepmate_mobile/features/resume/presentation/widgets/add_more_sections_sheet.dart';
import 'package:prepmate_mobile/features/resume/presentation/widgets/ai_transparency_sheet.dart';
import 'package:prepmate_mobile/features/resume/presentation/widgets/insufficient_credits_sheet.dart';
import 'package:prepmate_mobile/features/resume/presentation/widgets/resume_error_banner.dart';
import 'package:prepmate_mobile/features/resume/presentation/widgets/skills_cloud_widget.dart';
import 'package:prepmate_mobile/features/resume/presentation/widgets/unsaved_changes_modal.dart';

void main() {
  group('Screen 24: Unsaved Changes Modal', () {
    testWidgets('renders section name and buttons', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UnsavedChangesModal(
              sectionName: 'Work experience',
              onSaveDraftAndLeave: () async {},
              onDiscardChanges: () {},
              onKeepEditing: () {},
            ),
          ),
        ),
      );

      expect(find.text('Unsaved changes'), findsOneWidget);
      expect(
        find.textContaining('You modified Work experience'),
        findsOneWidget,
      );
      expect(find.text('Save draft and leave'), findsOneWidget);
      expect(find.text('Keep editing form'), findsOneWidget);
      expect(find.text('Discard Work experience changes'), findsOneWidget);
    });
  });

  group('Screen 18: Add More Sections Sheet', () {
    testWidgets('renders supported optional sections and triggers add', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1000, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      String? selectedKey;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: AddMoreSectionsSheet(
                onSectionSelected: (key) {
                  selectedKey = key;
                },
              ),
            ),
          ),
        ),
      );

      expect(find.text('Add more sections'), findsOneWidget);
      expect(find.text('Languages'), findsOneWidget);
      expect(find.text('Certifications & Licenses'), findsOneWidget);
      expect(find.text('Awards & Honors'), findsOneWidget);
      expect(find.text('Volunteer & Leadership'), findsOneWidget);
      expect(find.text('Publications & Research'), findsOneWidget);
      expect(find.text('References'), findsOneWidget);

      // Tap the first Add button
      final addButton = find.text('Add').first;
      await tester.tap(addButton);
      await tester.pump();
      expect(selectedKey, equals('languages'));
    });
  });

  group('Screen 21: Skills and AI Suggestions', () {
    testWidgets(
      'renders skills cloud, allows adding custom skill and suggestions',
      (tester) async {
        tester.view.physicalSize = const Size(1000, 2000);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: Scaffold(
                body: SingleChildScrollView(
                  child: SkillsCloudWidget(targetRole: 'Flutter Engineer'),
                ),
              ),
            ),
          ),
        );

        expect(
          find.textContaining('Recommended for Flutter Engineer'),
          findsOneWidget,
        );
        expect(find.text('ATS Match'), findsWidgets);

        // Search input field is present
        final searchField = find.byType(TextField);
        expect(searchField, findsOneWidget);

        // Add a custom skill via text input and Add button
        await tester.enterText(searchField, 'Fastlane CI');
        await tester.pump();
        await tester.tap(find.text('Add').first);
        await tester.pump();

        // Confirmed skill chip is displayed
        expect(find.text('Fastlane CI'), findsOneWidget);

        // Tap on an AI suggested chip to add it
        final suggestion = find.text('Clean Architecture');
        if (suggestion.evaluate().isNotEmpty) {
          await tester.tap(suggestion.first);
          await tester.pump();
          // It now appears in confirmed skills
          expect(find.text('Clean Architecture'), findsWidgets);
        }
      },
    );
  });

  group('Screen 17: Resume Builder Errors & Offline States', () {
    testWidgets('OfflineRecoveryBanner renders offline notice', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: OfflineRecoveryBanner())),
      );

      expect(find.text('Offline Recovery Active'), findsOneWidget);
      expect(find.text('Local Safe Mode'), findsOneWidget);
      expect(
        find.textContaining('cached securely in local storage'),
        findsOneWidget,
      );
    });

    testWidgets('SyncFailureAlert renders message and triggers retry', (
      tester,
    ) async {
      var retried = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SyncFailureAlert(
              subtitle: 'Server timeout during validation',
              onRetry: () {
                retried = true;
              },
            ),
          ),
        ),
      );

      expect(find.text('Cloud sync paused'), findsOneWidget);
      expect(find.text('Server timeout during validation'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);

      await tester.tap(find.text('Retry'));
      await tester.pump();
      expect(retried, isTrue);
    });
  });

  group('Screen 25: Insufficient Credits Sheet', () {
    testWidgets('displays tool cost, available balance, and shortage amount', (
      tester,
    ) async {
      final mockState = AiCreditState(
        status: AiCreditStatus.loaded,
        account: const AiCreditAccount(
          balance: 2,
          monthlyAllocation: 50,
          usedThisCycle: 48,
          resetDate: null,
        ),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            aiCreditsProvider.overrideWith(
              (ref) => _StaticAiCreditsViewModel(
                const MockAiCreditsRepository(),
                mockState,
              ),
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: InsufficientCreditsSheet(
                toolName: 'Resume Optimizer',
                requiredCredits: 5,
              ),
            ),
          ),
        ),
      );

      expect(find.text('You need more AI credits'), findsOneWidget);
      expect(find.text('View credit options'), findsOneWidget);
      expect(find.text('Not now'), findsOneWidget);
      expect(find.text('See credit activity history'), findsOneWidget);
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is RichText &&
              widget.text.toPlainText().contains('need 3 more'),
        ),
        findsOneWidget,
      );
    });
  });

  group('Screen 28: AI Transparency Sheet', () {
    testWidgets('renders responsible AI pillars and disclosures', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1000, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: AiTransparencySheet())),
      );

      expect(find.text('About AI tools in PrepMate'), findsOneWidget);
      expect(find.text('How Your Data Is Handled'), findsOneWidget);
      expect(find.text('Review & User Control'), findsOneWidget);
      expect(find.text('How AI Credits Work'), findsOneWidget);
      expect(find.text('Privacy & Model Retention'), findsOneWidget);
      expect(find.text('Got it, thanks'), findsOneWidget);
      expect(find.text('Read full Privacy Policy'), findsOneWidget);
    });
  });

  group('Screen 20: PDF Save & Download Sheet', () {
    testWidgets('renders sanitized filename and download action', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SaveAndDownloadSheet(
              initialResumeTitle: 'Alex Vance Resume',
              pdfBytes: Uint8List.fromList([1, 2, 3]),
            ),
          ),
        ),
      );

      expect(find.text('Save PDF'), findsOneWidget);
      expect(find.text('.pdf'), findsOneWidget);
      expect(find.text('Save to device'), findsOneWidget);
      expect(find.text('Downloads / PrepMate Resumes'), findsOneWidget);

      // Verify the filename field has sanitized initial name
      expect(
        find.widgetWithText(TextField, 'Alex_Vance_Resume'),
        findsOneWidget,
      );
    });
  });

  group('Screen 23: PDF Thumbnail Navigator & Document Info', () {
    testWidgets('switches between pages and document details tabs', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PagesAndDocumentInfoSheet(
              pageCount: 3,
              currentPage: 1,
              templateName: 'Modern Executive',
              fileSizeBytes: 312000,
              onJumpToPage: (page) {},
            ),
          ),
        ),
      );

      expect(find.text('Pages & Document Info'), findsOneWidget);
      expect(find.text('Pages (3)'), findsOneWidget);
      expect(find.text('Document Details'), findsOneWidget);
      expect(find.text('Page 1'), findsOneWidget);
      expect(find.text('Viewing'), findsOneWidget);

      // Switch to Document Details tab
      await tester.tap(find.text('Document Details'));
      await tester.pumpAndSettle();

      expect(find.text('Modern Executive'), findsOneWidget);
      expect(find.text('ATS Compatibility 98%'), findsOneWidget);
    });
  });

  group('Screen 27 & 26: AI Assistant Hub & Outage Edge States', () {
    testWidgets(
      'renders AI Assistant Hub with balance, quick tools, and recent activity',
      (tester) async {
        tester.view.physicalSize = const Size(1000, 2000);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        final mockState = AiCreditState(
          status: AiCreditStatus.loaded,
          account: const AiCreditAccount(
            balance: 45,
            lifetimeUsed: 12,
            monthlyAllocation: 50,
            usedThisCycle: 5,
            resetDate: null,
            isUnlimited: false,
          ),
          operations: const [
            AiOperation(
              operation: 'bullet_points',
              displayName: 'Bullet Point Enhancer',
              description: 'Action verb improvement',
              creditCost: 2,
            ),
          ],
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              aiCreditsProvider.overrideWith(
                (ref) => _StaticAiCreditsViewModel(
                  const MockAiCreditsRepository(),
                  mockState,
                ),
              ),
              home.resumeListProvider.overrideWith(
                _StaticResumeListNotifier.new,
              ),
            ],
            child: const MaterialApp(home: AIAssistantScreen()),
          ),
        );

        await tester.pump();

        expect(find.text('AI Tools'), findsOneWidget);
        expect(find.text('45'), findsOneWidget); // Credit balance
        expect(find.text('AI credits'), findsOneWidget);
        expect(find.text('Explore AI tools'), findsOneWidget);
        expect(find.text('Resume Optimizer'), findsOneWidget);
        expect(find.text('Professional Summary'), findsOneWidget);
        expect(find.text('Bullet Writer'), findsOneWidget);
      },
    );

    testWidgets('renders outage banner on error status', (tester) async {
      final errorState = AiCreditState(
        status: AiCreditStatus.error,
        error: 'AI service gateway unreachable',
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            aiCreditsProvider.overrideWith(
              (ref) => _StaticAiCreditsViewModel(
                const MockAiCreditsRepository(),
                errorState,
              ),
            ),
            home.resumeListProvider.overrideWith(_StaticResumeListNotifier.new),
          ],
          child: const MaterialApp(home: AIAssistantScreen()),
        ),
      );

      await tester.pump();

      expect(
        find.textContaining("You're offline · AI tools paused"),
        findsOneWidget,
      );
    });
  });
}

class _StaticResumeListNotifier extends home.ResumeListNotifier {
  @override
  Future<List<ResumeModel>> build() async => [];
}

class _StaticAiCreditsViewModel extends AiCreditsViewModel {
  _StaticAiCreditsViewModel(super.repository, AiCreditState initialState) {
    state = initialState;
  }

  @override
  Future<void> load() async {}

  @override
  Future<void> loadTransactions({
    String? filter,
    String? query,
    String? ordering,
  }) async {}

  @override
  Future<void> refresh() async {}
}
