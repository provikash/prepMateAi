import '../domain/optimization_models.dart';
import '../domain/optimization_repository.dart';

class MockOptimizationRepository implements OptimizationRepository {
  @override
  Future<OptimizationAnalysis> analyze(String jobDescription) async {
    await Future<void>.delayed(const Duration(milliseconds: 1100));
    if (jobDescription.toLowerCase().contains('network failure')) {
      throw Exception('Network failure. Check your connection and try again.');
    }
    return const OptimizationAnalysis(
      beforeScore: 72,
      afterScore: 86,
      requirements: [
        JobRequirement(
          name: 'Flutter & Dart',
          importance: 'Required',
          match: RequirementMatch.matched,
          evidence: 'Projects → PrepMateAI',
          explanation:
              'Strong evidence across your project and skills sections.',
        ),
        JobRequirement(
          name: 'REST APIs',
          importance: 'Required',
          match: RequirementMatch.matched,
          evidence: 'Projects → PrepMateAI',
          explanation:
              'You describe REST API integration and JWT authentication.',
        ),
        JobRequirement(
          name: 'Riverpod',
          importance: 'Required',
          match: RequirementMatch.partial,
          evidence: 'Skills → State management',
          explanation:
              'Riverpod is listed, but ownership and impact are not clearly explained.',
        ),
        JobRequirement(
          name: 'Firebase',
          importance: 'Preferred',
          match: RequirementMatch.partial,
          evidence: 'Skills → Tools',
          explanation: 'Firebase is present without a supporting achievement.',
        ),
        JobRequirement(
          name: 'Kubernetes',
          importance: 'Preferred',
          match: RequirementMatch.missing,
          explanation:
              'No supporting evidence was found. Do not add this unless you have real experience.',
        ),
        JobRequirement(
          name: 'AWS',
          importance: 'Preferred',
          match: RequirementMatch.missing,
          explanation: 'No supporting evidence was found in the resume.',
        ),
        JobRequirement(
          name: 'CI/CD',
          importance: 'Preferred',
          match: RequirementMatch.missing,
          explanation: 'No clear delivery-pipeline evidence was found.',
        ),
      ],
      suggestions: [
        OptimizationSuggestion(
          id: 'summary',
          section: 'Summary',
          current:
              'Mobile engineer with experience building Flutter applications.',
          proposed:
              'Mobile engineer with 5+ years building scalable Flutter products backed by secure REST APIs and clean architecture.',
          reason: 'Leads with experience, target technology, and scope.',
          keywords: ['Flutter', 'REST APIs', 'Clean Architecture'],
          evidence: 'Experience and PrepMateAI project',
          highImpact: true,
        ),
        OptimizationSuggestion(
          id: 'experience',
          section: 'Experience',
          current: 'Built mobile features and worked with the backend team.',
          proposed:
              'Delivered 12 production Flutter features and partnered with backend engineers to integrate authenticated REST APIs.',
          reason:
              'Adds concrete scope and makes cross-functional impact clear.',
          keywords: ['Flutter', 'REST APIs'],
          evidence: 'Mobile Developer role and project history',
          highImpact: true,
        ),
        OptimizationSuggestion(
          id: 'riverpod',
          section: 'Skills',
          current: 'State management: Riverpod',
          proposed:
              'Architected testable feature state with Riverpod, reducing UI coupling and simplifying async error handling.',
          reason:
              'Turns a keyword into credible, responsibility-based evidence.',
          keywords: ['Riverpod', 'State management'],
          evidence: 'PrepMateAI architecture',
          highImpact: true,
        ),
        OptimizationSuggestion(
          id: 'project',
          section: 'Projects',
          current: 'Created PrepMateAI using Flutter and Django.',
          proposed:
              'Built PrepMateAI with Flutter, Riverpod, Django REST Framework, PostgreSQL, and JWT-based authentication.',
          reason:
              'Improves keyword alignment using technologies already supported by your resume.',
          keywords: ['Django REST Framework', 'PostgreSQL', 'JWT'],
          evidence: 'PrepMateAI project stack',
          status: SuggestionStatus.edited,
        ),
        OptimizationSuggestion(
          id: 'git',
          section: 'Skills',
          current: 'Git',
          proposed: 'Tools: Git, GitHub, Postman, Firebase',
          reason: 'Groups tooling for faster ATS parsing.',
          keywords: ['Git', 'Firebase'],
          evidence: 'Skills and project sections',
          status: SuggestionStatus.accepted,
        ),
        OptimizationSuggestion(
          id: 'unsupported',
          section: 'Skills',
          current: 'Cloud: —',
          proposed: 'Cloud: AWS, Kubernetes',
          reason: 'These terms appear in the job description.',
          keywords: ['AWS', 'Kubernetes'],
          evidence: 'No supporting evidence found',
          status: SuggestionStatus.rejected,
        ),
      ],
    );
  }

  @override
  Future<String> regenerate(String text, String instruction) async {
    await Future<void>.delayed(const Duration(milliseconds: 700));
    if (instruction.toLowerCase().contains('fail')) {
      throw Exception('AI generation failed.');
    }
    return '$text ${instruction == 'Make it more concise' ? '' : 'Delivered measurable, role-relevant outcomes.'}'
        .trim();
  }

  @override
  Future<void> createVersion(String name) async {
    await Future<void>.delayed(const Duration(milliseconds: 700));
    if (name.trim().isEmpty) throw Exception('Enter a version name.');
  }
}
