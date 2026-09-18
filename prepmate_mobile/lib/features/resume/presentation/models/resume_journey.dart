import '../../data/models/template_detail_model.dart';

enum ResumeJourneyStepKey {
  about,
  experienceProjects,
  educationSkills,
  summary,
  review,
}

class ResumeJourneyStep {
  const ResumeJourneyStep({
    required this.key,
    required this.title,
    required this.description,
    required this.sections,
    this.canSkip = true,
  });

  final ResumeJourneyStepKey key;
  final String title;
  final String description;
  final List<FormSectionModel> sections;
  final bool canSkip;
}

class ResumeJourney {
  const ResumeJourney({required this.steps, required this.optionalSections});

  static const optionalKeys = {
    'certificates',
    'languages',
    'awards',
    'volunteer',
    'publications',
    'interests',
    'references',
  };

  final List<ResumeJourneyStep> steps;
  final List<FormSectionModel> optionalSections;

  factory ResumeJourney.fromTemplate(TemplateDetailModel template) {
    final byKey = {
      for (final section in template.sections) section.key: section,
    };
    final steps = <ResumeJourneyStep>[];
    final basics = byKey['basics'];
    if (basics != null) {
      final fields = basics.fields
          .where((field) => field.key != 'summary')
          .toList();
      if (fields.isNotEmpty) {
        steps.add(
          ResumeJourneyStep(
            key: ResumeJourneyStepKey.about,
            title: 'About you',
            description:
                'Start with the essentials employers use to contact you.',
            sections: [
              basics.copyWith(title: 'Personal details', fields: fields),
            ],
            canSkip: false,
          ),
        );
      }
    }

    final experience = <FormSectionModel>[
      if (byKey['work'] != null) byKey['work']!,
      if (byKey['projects'] != null) byKey['projects']!,
    ];
    if (experience.isNotEmpty) {
      steps.add(
        ResumeJourneyStep(
          key: ResumeJourneyStepKey.experienceProjects,
          title: 'Experience & projects',
          description:
              'Add work, projects, or both. Students can lead with projects.',
          sections: experience,
        ),
      );
    }

    final learning = <FormSectionModel>[
      if (byKey['education'] != null) byKey['education']!,
      if (byKey['skills'] != null) byKey['skills']!,
    ];
    if (learning.isNotEmpty) {
      steps.add(
        ResumeJourneyStep(
          key: ResumeJourneyStepKey.educationSkills,
          title: 'Education & skills',
          description: 'Show what you know and where you learned it.',
          sections: learning,
        ),
      );
    }

    final summary = basics?.fields
        .where((field) => field.key == 'summary')
        .toList();
    if (basics != null && summary != null && summary.isNotEmpty) {
      steps.add(
        ResumeJourneyStep(
          key: ResumeJourneyStepKey.summary,
          title: 'Professional summary',
          description: 'Bring your details together in a focused introduction.',
          sections: [basics.copyWith(title: 'Your summary', fields: summary)],
        ),
      );
    }

    steps.add(
      const ResumeJourneyStep(
        key: ResumeJourneyStepKey.review,
        title: 'Review & finish',
        description:
            'Check completeness, save the latest version, and create your PDF.',
        sections: [],
        canSkip: false,
      ),
    );

    final optional =
        template.sections
            .where(
              (section) =>
                  optionalKeys.contains(section.key) ||
                  section.group == 'optional',
            )
            .toList()
          ..sort((a, b) => a.order.compareTo(b.order));
    return ResumeJourney(steps: steps, optionalSections: optional);
  }

  int stepIndexForSection(String sectionKey) {
    for (var index = 0; index < steps.length; index++) {
      if (steps[index].sections.any((section) => section.key == sectionKey)) {
        return index;
      }
    }
    return steps.indexWhere((step) => step.key == ResumeJourneyStepKey.review);
  }
}

class ResumeCompletion {
  const ResumeCompletion({
    required this.percent,
    required this.completedSteps,
    required this.blockingIssues,
    required this.recommendations,
  });

  final int percent;
  final Set<ResumeJourneyStepKey> completedSteps;
  final List<String> blockingIssues;
  final List<String> recommendations;

  factory ResumeCompletion.calculate(Map<String, dynamic> data) {
    final basics = Map<String, dynamic>.from(
      data['basics'] as Map? ?? const {},
    );
    final work = _items(data['work']);
    final projects = _items(data['projects']);
    final education = _items(data['education']);
    final skills = _items(data['skills']);
    final summary = basics['summary']?.toString().trim() ?? '';

    var score = 0.0;
    final completed = <ResumeJourneyStepKey>{};
    final blocking = <String>[];
    final recommendations = <String>[];

    final name = basics['name']?.toString().trim() ?? '';
    final email = basics['email']?.toString().trim() ?? '';
    final phone = basics['phone']?.toString().trim() ?? '';
    final label = basics['label']?.toString().trim() ?? '';
    final location = basics['location'];
    score += name.isNotEmpty ? 8 : 0;
    score += email.isNotEmpty ? 5 : 0;
    score += phone.isNotEmpty ? 3 : 0;
    score += label.isNotEmpty ? 2 : 0;
    score += _hasValue(location) ? 2 : 0;
    if (name.isEmpty) blocking.add('Add your full name.');
    if (email.isEmpty) {
      recommendations.add('Add an email address so employers can contact you.');
    }
    if (name.isNotEmpty && email.isNotEmpty) {
      completed.add(ResumeJourneyStepKey.about);
    }

    final hasExperience = work.any(_hasMeaningfulItem);
    final hasProjects = projects.any(_hasMeaningfulItem);
    if (hasExperience || hasProjects) {
      score += 25;
      completed.add(ResumeJourneyStepKey.experienceProjects);
    } else {
      recommendations.add(
        'Add work experience or a project that demonstrates your abilities.',
      );
    }

    if (education.any(_hasMeaningfulItem)) {
      score += 15;
    } else {
      recommendations.add('Add education if it supports your target role.');
    }
    final keywordCount = skills.fold<int>(
      0,
      (count, item) => count + ((item['keywords'] as List?)?.length ?? 0),
    );
    if (skills.any(_hasMeaningfulItem)) {
      score += keywordCount >= 3 ? 15 : 9;
    } else {
      recommendations.add('Include 3–6 relevant skills.');
    }
    if (education.any(_hasMeaningfulItem) && skills.any(_hasMeaningfulItem)) {
      completed.add(ResumeJourneyStepKey.educationSkills);
    }

    if (summary.isNotEmpty) {
      score += summary.length >= 80 ? 15 : 9;
      completed.add(ResumeJourneyStepKey.summary);
      if (summary.length < 80) {
        recommendations.add('Your summary could be more specific.');
      }
    } else {
      recommendations.add('Add a focused professional summary.');
    }

    if (blocking.isEmpty) {
      score += 10;
      completed.add(ResumeJourneyStepKey.review);
    }
    return ResumeCompletion(
      percent: score.round().clamp(0, 100).toInt(),
      completedSteps: completed,
      blockingIssues: blocking,
      recommendations: recommendations,
    );
  }

  static List<Map<String, dynamic>> _items(dynamic value) => value is List
      ? value
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList()
      : const [];

  static bool _hasMeaningfulItem(Map<String, dynamic> item) =>
      item.values.any(_hasValue);

  static bool _hasValue(dynamic value) {
    if (value == null) return false;
    if (value is String) return value.trim().isNotEmpty;
    if (value is List) return value.any(_hasValue);
    if (value is Map) return value.values.any(_hasValue);
    return true;
  }
}
