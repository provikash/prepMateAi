import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prepmate_mobile/features/home/data/models/resume_model.dart';
import 'package:prepmate_mobile/features/resume_optimizer/data/mock_optimization_repository.dart';
import 'package:prepmate_mobile/features/resume_optimizer/domain/optimization_models.dart';
import 'package:prepmate_mobile/features/resume_optimizer/presentation/providers/optimization_provider.dart';

void main() {
  late ProviderContainer container;

  setUp(() {
    container = ProviderContainer(
      overrides: [
        useMockOptimizationProvider.overrideWith((ref) => true),
        optimizationRepositoryProvider.overrideWithValue(MockOptimizationRepository()),
      ],
    );
  });

  tearDown(() => container.dispose());

  test('analysis validates resume and job description', () async {
    final notifier = container.read(optimizationProvider.notifier);

    // 1. No resume selected
    expect(await notifier.analyze(), isFalse);
    expect(container.read(optimizationProvider).error, contains('Choose'));

    // 2. Select resume, but empty JD
    notifier.selectResume(
      ResumeModel(id: 'alex-master', title: 'Master Resume', thumbnailUrl: '', pdfUrl: ''),
    );
    notifier.setJobDescription('   ');
    expect(await notifier.analyze(), isFalse);
    expect(container.read(optimizationProvider).error, contains('enter a job description'));

    // 3. Short JD (< 80 chars)
    notifier.setJobDescription('Short description');
    expect(await notifier.analyze(), isFalse);
    expect(container.read(optimizationProvider).error, contains('80'));
  });

  test('mock repository produces all 4 match states with grounded evidence paths', () async {
    final notifier = container.read(optimizationProvider.notifier);
    notifier.selectResume(
      ResumeModel(id: 'alex-master', title: 'Master Resume', thumbnailUrl: '', pdfUrl: ''),
    );
    notifier.setJobTitle('Junior Flutter Developer');
    notifier.setCompany('TechNova');
    notifier.setJobDescription(
      'We are looking for a Junior Flutter Developer with strong knowledge of Dart, '
      'REST APIs, Riverpod, and Git. Experience with Bloc is required. Cloud experience with AWS is a plus.',
    );

    final success = await notifier.analyze();
    expect(success, isTrue);

    final analysis = container.read(optimizationProvider).analysis;
    expect(analysis, isNotNull);

    // Verify all 4 states exist
    final matched = analysis!.requirements.where((r) => r.match == RequirementMatch.matched);
    final partial = analysis.requirements.where((r) => r.match == RequirementMatch.partial);
    final missing = analysis.requirements.where((r) => r.match == RequirementMatch.missing);
    final unclear = analysis.requirements.where((r) => r.match == RequirementMatch.unclear);

    expect(matched.isNotEmpty, isTrue, reason: 'Must have matched requirements');
    expect(partial.isNotEmpty, isTrue, reason: 'Must have partial requirements');
    expect(missing.isNotEmpty, isTrue, reason: 'Must have missing requirements');
    expect(unclear.isNotEmpty, isTrue, reason: 'Must have unclear requirements');

    // Verify evidence path grounding
    final flutterReq = analysis.requirements.firstWhere((r) => r.name == 'Flutter');
    expect(flutterReq.match, RequirementMatch.matched);
    expect(flutterReq.evidencePath, contains('projects[0]'));

    // Verify Bloc is MISSING (Riverpod is present, but Bloc is distinct)
    final blocReq = analysis.requirements.firstWhere((r) => r.name == 'Bloc');
    expect(blocReq.match, RequirementMatch.missing);

    // Verify AWS is UNCLEAR (generic cloud is present, not AWS)
    final awsReq = analysis.requirements.firstWhere((r) => r.name == 'AWS');
    expect(awsReq.match, RequirementMatch.unclear);

    // Verify Master resume remains untouched
    expect(container.read(optimizationProvider).resume!.title, 'Master Resume');
  });

  test('job analysis overview correctly contains structured fields', () async {
    final notifier = container.read(optimizationProvider.notifier);
    notifier.selectResume(
      ResumeModel(id: 'alex-master', title: 'Master Resume', thumbnailUrl: '', pdfUrl: ''),
    );
    notifier.setJobDescription(
      'Looking for a Junior Flutter Developer with Dart, REST APIs, Git, and Riverpod experience. 1+ years experience.',
    );

    await notifier.analyze();
    final overview = container.read(optimizationProvider).analysis?.overview;

    expect(overview, isNotNull);
    expect(overview!.jobTitle, 'Junior Flutter Developer');
    expect(overview.company, 'TechNova');
    expect(overview.requiredSkills, contains('Flutter'));
    expect(overview.requiredSkills, contains('Dart'));
  });
}
