import 'package:flutter_test/flutter_test.dart';
import 'package:prepmate_mobile/features/resume/data/models/template_detail_model.dart';
import 'package:prepmate_mobile/features/resume/presentation/models/resume_journey.dart';

FormSectionModel _section(
  String key, {
  SectionType type = SectionType.repeatable,
  String group = 'core',
  List<FormFieldModel>? fields,
}) => FormSectionModel(
  title: key,
  key: key,
  type: type,
  aiActions: const [],
  fields:
      fields ??
      [FormFieldModel(key: key, label: key, type: 'list_object')],
  group: group,
);

void main() {
  final template = TemplateDetailModel(
    id: 'template-1',
    title: 'Professional',
    sections: [
      _section(
        'basics',
        type: SectionType.single,
        fields: const [
          FormFieldModel(key: 'name', label: 'Name', type: 'text'),
          FormFieldModel(key: 'email', label: 'Email', type: 'email'),
          FormFieldModel(key: 'summary', label: 'Summary', type: 'textarea'),
        ],
      ),
      _section('work'),
      _section('projects'),
      _section('education'),
      _section('skills'),
      _section('certificates', group: 'optional'),
      _section('languages', group: 'optional'),
    ],
  );

  test('groups canonical sections into five meaningful journey steps', () {
    final journey = ResumeJourney.fromTemplate(template);

    expect(journey.steps, hasLength(5));
    expect(
      journey.steps.map((step) => step.key),
      ResumeJourneyStepKey.values,
    );
    expect(
      journey.steps[1].sections.map((section) => section.key),
      ['work', 'projects'],
    );
    expect(journey.optionalSections.map((section) => section.key), [
      'certificates',
      'languages',
    ]);
  });

  test('optional sections do not create required stages or block export', () {
    final journey = ResumeJourney.fromTemplate(template);
    final completion = ResumeCompletion.calculate({
      'basics': {'name': 'Ada Lovelace'},
      'certificates': [
        {'name': 'Computing'},
      ],
    });

    expect(journey.steps, hasLength(5));
    expect(completion.blockingIssues, isEmpty);
    expect(completion.percent, lessThan(100));
  });

  test('completion uses actual content and full name is the only blocker', () {
    final empty = ResumeCompletion.calculate(const {});
    final strong = ResumeCompletion.calculate({
      'basics': {
        'name': 'Ada Lovelace',
        'email': 'ada@example.com',
        'phone': '123',
        'label': 'Engineer',
        'summary': 'A focused professional summary with specific experience and strengths for the target role.',
      },
      'work': [
        {'name': 'Analytical Engines', 'position': 'Engineer'},
      ],
      'education': [
        {'institution': 'University'},
      ],
      'skills': [
        {
          'name': 'Engineering',
          'keywords': ['Dart', 'Flutter', 'APIs'],
        },
      ],
    });

    expect(empty.blockingIssues, isNotEmpty);
    expect(strong.blockingIssues, isEmpty);
    expect(strong.percent, greaterThan(empty.percent));
    expect(strong.completedSteps, contains(ResumeJourneyStepKey.review));
  });
}
