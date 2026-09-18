import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prepmate_mobile/core/providers/form_provider.dart';
import 'package:prepmate_mobile/features/resume/presentation/providers/resume_builder_provider.dart';
import 'package:prepmate_mobile/features/resume/presentation/widgets/resume_step_indicator.dart';
import 'package:prepmate_mobile/features/home/presentation/screens/pdf_view_screen.dart';
import 'package:prepmate_mobile/features/resume/presentation/providers/resume_providers.dart';

void main() {
  test('a save failure always enables retry', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(resumeBuilderProvider.notifier);

    notifier.setSaving(true);
    notifier.setError('Correct basics.email: Enter a valid email.');

    final state = container.read(resumeBuilderProvider);
    expect(state.isSaving, isFalse);
    expect(state.errorMessage, contains('basics.email'));
  });

  test('form revision changes only when resume data changes', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(resumeFormProvider.notifier);
    final initial = container.read(resumeFormProvider).revision;

    notifier.applySchema(
      visibleSections: const {'basics'},
      sectionActions: const {},
    );
    expect(container.read(resumeFormProvider).revision, initial);

    notifier.updateSectionField('basics', 'name', 'Test Candidate');
    expect(container.read(resumeFormProvider).revision, initial + 1);
  });

  testWidgets('progress header handles one section and reduced motion', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(disableAnimations: true),
          child: Scaffold(
            body: ResumeStepIndicator(
              currentStep: 0,
              totalSteps: 1,
              sectionTitles: ['Personal Information'],
              completedSteps: {},
              onStepTapped: _ignoreStep,
            ),
          ),
        ),
      ),
    );

    expect(find.text('Personal Information'), findsOneWidget);
    expect(find.text('Step 1 of 1'), findsOneWidget);
    expect(find.text('0% complete'), findsOneWidget);
  });

  testWidgets('progress header safely hides for zero sections', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ResumeStepIndicator(
            currentStep: 0,
            totalSteps: 0,
            sectionTitles: [],
            onStepTapped: _ignoreStep,
          ),
        ),
      ),
    );

    expect(find.byType(LinearProgressIndicator), findsNothing);
  });

  testWidgets('PDF generation failure is actionable and retryable', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          pdfViewerProvider('42').overrideWith(
            (ref) => Future<Uint8List>.error(
              Exception('The server could not generate the PDF.'),
            ),
          ),
        ],
        child: const MaterialApp(home: PdfViewScreen(resumeId: '42')),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.textContaining('could not generate'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Try again'), findsOneWidget);
    expect(find.textContaining('not available yet'), findsNothing);
  });
}

void _ignoreStep(int _) {}
