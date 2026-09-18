import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prepmate_mobile/core/providers/form_provider.dart';
import 'package:prepmate_mobile/features/resume/data/models/template_detail_model.dart';
import 'package:prepmate_mobile/features/resume/presentation/providers/field_enhance_provider.dart';
import 'package:prepmate_mobile/features/resume/presentation/widgets/schema_form_section.dart';

void main() {
  test('AI field mapping requires both a supported path and schema action', () {
    expect(
      FieldEnhanceMapping.resolve('basics.summary', ['improve-section']),
      FieldEnhanceOperation.improveText,
    );
    expect(
      FieldEnhanceMapping.resolve('work[].highlights', ['generate_bullets']),
      FieldEnhanceOperation.generateBullets,
    );
    expect(FieldEnhanceMapping.resolve('basics.summary', []), isNull);
    expect(
      FieldEnhanceMapping.resolve('basics.email', ['improve_section']),
      isNull,
    );
  });

  test('repeatable entries reorder without changing their values', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(resumeFormProvider.notifier);
    notifier.addSectionItem('projects', {'name': 'First'});
    notifier.addSectionItem('projects', {'name': 'Second'});
    notifier.reorderSectionItem('projects', 1, 0);
    expect(
      container
          .read(resumeFormProvider)
          .sectionItems('projects')
          .map((item) => item['name']),
      ['Second', 'First'],
    );
  });

  test(
    'schema fallback uses canonical object-array section keys and types',
    () {
      final template = TemplateDetailModel.fromJson({
        'id': 'fallback',
        'title': 'Fallback',
      });
      final work = template.sections.singleWhere(
        (section) => section.key == 'work',
      );
      final skills = template.sections.singleWhere(
        (section) => section.key == 'skills',
      );
      expect(
        template.sections.any((section) => section.key == 'experience'),
        isFalse,
      );
      expect(work.type, SectionType.repeatable);
      expect(
        work.fields.single.objectFields.map((field) => field.key),
        containsAll(['name', 'position']),
      );
      expect(skills.type, SectionType.repeatable);
      expect(
        skills.fields.single.objectFields.map((field) => field.key),
        containsAll(['name', 'level', 'keywords']),
      );
    },
  );

  testWidgets('structured location and profiles preserve every nested value', (
    tester,
  ) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final form = container.read(resumeFormProvider.notifier);
    form.updateSectionField('basics', 'location', {
      'address': 'Old address',
      'city': 'Old city',
      'region': 'Western',
      'postalCode': '00100',
      'countryCode': 'LK',
      'customLocationValue': 'preserve me',
    });
    form.updateSectionField('basics', 'profiles', [
      {
        'network': 'GitHub',
        'username': 'candidate',
        'url': 'https://github.com/candidate',
        'customProfileValue': 'preserve me too',
      },
    ]);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: Scaffold(
            body: Form(
              child: SingleChildScrollView(
                child: SchemaFormSection(
                  section: const FormSectionModel(
                    title: 'Personal Information',
                    key: 'basics',
                    type: SectionType.single,
                    aiActions: [],
                    fields: [
                      FormFieldModel(
                        key: 'location',
                        label: 'Location',
                        type: 'location',
                      ),
                      FormFieldModel(
                        key: 'profiles',
                        label: 'Professional Links',
                        type: 'profiles',
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Full location'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Address'),
      '42 Sentinel Road',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Username'),
      'complete-candidate',
    );
    await tester.pump();

    final basics = container.read(resumeFormProvider).basics;
    final location = basics['location'] as Map<String, dynamic>;
    final profiles = basics['profiles'] as List<dynamic>;
    expect(location['address'], '42 Sentinel Road');
    expect(location['city'], 'Old city');
    expect(location['region'], 'Western');
    expect(location['postalCode'], '00100');
    expect(location['countryCode'], 'LK');
    expect(location['customLocationValue'], 'preserve me');
    expect(profiles.single['network'], 'GitHub');
    expect(profiles.single['username'], 'complete-candidate');
    expect(profiles.single['url'], 'https://github.com/candidate');
    expect(profiles.single['customProfileValue'], 'preserve me too');
  });

  testWidgets('repeatable list fields remain typed lists across rebuilds', (
    tester,
  ) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: Scaffold(
            body: Form(
              child: SingleChildScrollView(
                child: SchemaFormSection(
                  section: const FormSectionModel(
                    title: 'Work Experience',
                    key: 'work',
                    type: SectionType.repeatable,
                    aiActions: [],
                    fields: [
                      FormFieldModel(
                        key: 'work',
                        label: 'Work Experience',
                        type: 'list_object',
                        objectFields: [
                          FormObjectFieldModel(key: 'name', label: 'Company'),
                          FormObjectFieldModel(
                            key: 'highlights',
                            label: 'Achievements / Responsibilities',
                            type: 'list',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.widgetWithText(TextButton, 'Add'));
    await tester.pump();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Company (optional)'),
      'Sentinel Company',
    );
    await tester.enterText(
      find.widgetWithText(
        TextFormField,
        'Achievements / Responsibilities (optional)',
      ),
      'Improved speed, quality\nMentored engineers',
    );
    await tester.pump();

    final work = container.read(resumeFormProvider).sectionItems('work');
    expect(work.single['name'], 'Sentinel Company');
    expect(work.single['highlights'], [
      'Improved speed, quality',
      'Mentored engineers',
    ]);
  });

  testWidgets(
    'AI enhancement never replaces field text before explicit apply',
    (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container
          .read(resumeFormProvider.notifier)
          .updateSectionField('basics', 'summary', 'Original summary');
      FieldEnhanceTarget? request;
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(
              body: SchemaFormSection(
                section: const FormSectionModel(
                  title: 'Personal Information',
                  key: 'basics',
                  type: SectionType.single,
                  aiActions: [],
                  fields: [
                    FormFieldModel(
                      key: 'summary',
                      label: 'Summary',
                      type: 'textarea',
                      aiActions: ['improve_section'],
                    ),
                  ],
                ),
                onEnhance: (target) => request = target,
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Enhance with AI'));
      await tester.pump();
      expect(request, isNotNull);
      expect(
        container.read(resumeFormProvider).basics['summary'],
        'Original summary',
      );
      request!.apply('Suggested summary');
      expect(
        container.read(resumeFormProvider).basics['summary'],
        'Suggested summary',
      );
    },
  );
}
