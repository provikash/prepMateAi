import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prepmate_mobile/features/home/data/models/resume_model.dart';
import 'package:prepmate_mobile/features/resume_optimizer/domain/optimization_models.dart';
import 'package:prepmate_mobile/features/resume_optimizer/presentation/providers/optimization_provider.dart';

void main() {
  late ProviderContainer container;

  setUp(() => container = ProviderContainer());
  tearDown(() => container.dispose());

  test('analysis validates resume and job description', () async {
    final notifier = container.read(optimizationProvider.notifier);
    expect(await notifier.analyze(), isFalse);
    expect(container.read(optimizationProvider).error, contains('Choose'));

    notifier.selectResume(
      ResumeModel(id: '1', title: 'Master', thumbnailUrl: '', pdfUrl: ''),
    );
    notifier.setJobDescription('Too short');
    expect(await notifier.analyze(), isFalse);
    expect(container.read(optimizationProvider).error, contains('80'));
  });

  test('analysis succeeds and suggestion decisions remain editable', () async {
    final notifier = container.read(optimizationProvider.notifier);
    notifier.selectResume(
      ResumeModel(id: '1', title: 'Master', thumbnailUrl: '', pdfUrl: ''),
    );
    notifier.setJobDescription(
      'We need a Flutter engineer with Dart, Riverpod, REST APIs, Firebase, '
      'Git, clean architecture, testing, communication, and delivery skills.',
    );

    expect(await notifier.analyze(), isTrue);
    notifier.setSuggestionStatus('summary', SuggestionStatus.rejected);
    expect(
      container
          .read(optimizationProvider)
          .analysis!
          .suggestions
          .firstWhere((item) => item.id == 'summary')
          .status,
      SuggestionStatus.rejected,
    );

    notifier.editSuggestion('summary', 'A user-approved replacement.');
    final edited = container
        .read(optimizationProvider)
        .analysis!
        .suggestions
        .firstWhere((item) => item.id == 'summary');
    expect(edited.status, SuggestionStatus.edited);
    expect(edited.proposed, 'A user-approved replacement.');
    expect(container.read(optimizationProvider).resume!.title, 'Master');
  });
}
