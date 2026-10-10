import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:prepmate_mobile/features/resume/data/services/local_resume_pdf_generator.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('generates a valid multi-section offline resume PDF', () async {
    final bytes = await const LocalResumePdfGenerator().generate(
      templateId: 'offline-modern',
      data: {
        'basics': {
          'name': 'Alex Morgan',
          'label': 'Product Designer',
          'email': 'alex@example.com',
          'phone': '+94 77 123 4567',
          'location': {'city': 'Colombo', 'country': 'Sri Lanka'},
          'summary':
              'Product designer focused on accessible mobile experiences.',
        },
        'work': [
          {
            'position': 'Senior Product Designer',
            'name': 'Example Studio',
            'startDate': '2022',
            'endDate': 'Present',
            'summary': 'Led research and design for a mobile product team.',
            'highlights': ['Improved task completion by 24%'],
          },
        ],
        'education': [
          {
            'studyType': 'BSc',
            'area': 'Interaction Design',
            'institution': 'Example University',
            'endDate': '2021',
          },
        ],
        'skills': ['User research', 'Prototyping', 'Design systems'],
        'projects': [
          {
            'name': 'Accessible Checkout',
            'description': 'A WCAG-focused checkout redesign.',
          },
        ],
      },
    );

    expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
    expect(bytes.length, greaterThan(5000));

    final outputPath = Platform.environment['PREPMATE_PDF_QA_OUTPUT'];
    if (outputPath != null && outputPath.isNotEmpty) {
      final file = File(outputPath);
      await file.parent.create(recursive: true);
      await file.writeAsBytes(bytes, flush: true);
    }
  });
}
