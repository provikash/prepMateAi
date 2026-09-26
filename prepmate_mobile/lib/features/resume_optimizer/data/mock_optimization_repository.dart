import 'package:prepmate_mobile/features/home/data/models/resume_model.dart';
import '../domain/optimization_models.dart';
import '../domain/optimization_repository.dart';

class MockOptimizationRepository implements OptimizationRepository {
  @override
  Future<List<ResumeModel>> getResumes() async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    return [
      ResumeModel(
        id: 'alex-master',
        title: 'Alex Developer — Master Resume',
        thumbnailUrl: '',
        pdfUrl: '',
      ),
      ResumeModel(
        id: 'alex-mobile',
        title: 'Flutter & Mobile Resume',
        thumbnailUrl: '',
        pdfUrl: '',
      ),
    ];
  }

  @override
  Future<JobDescriptionModel> createJobDescription({
    required String title,
    required String company,
    required String description,
    String? sourceUrl,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    return JobDescriptionModel(
      id: 'mock-jd-101',
      title: title.isEmpty ? 'Junior Flutter Developer' : title,
      company: company.isEmpty ? 'TechNova' : company,
      description: description,
      sourceUrl: sourceUrl ?? '',
    );
  }

  @override
  Future<OptimizationSessionModel> createOptimizationSession({
    required String resumeId,
    required String jobDescriptionId,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    return OptimizationSessionModel(
      id: 'mock-session-501',
      sourceResumeId: resumeId,
      sourceResumeTitle: 'Alex Developer — Master Resume',
      status: 'DRAFT',
    );
  }

  @override
  Future<OptimizationSessionModel> getOptimizationSession(
    String sessionId,
  ) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    return OptimizationSessionModel(
      id: sessionId,
      sourceResumeId: 'alex-master',
      sourceResumeTitle: 'Alex Developer — Master Resume',
      status: 'READY_FOR_REVIEW',
    );
  }

  @override
  Future<OptimizationAnalysis> restoreOptimization(String sessionId) => analyze(
    resumeId: 'mock',
    jobDescription:
        'A sufficiently detailed mock job description for session restoration.',
  );

  @override
  Future<OptimizationSessionModel> analyzeJobDescription(
    String sessionId,
  ) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    return OptimizationSessionModel(
      id: sessionId,
      sourceResumeId: 'alex-master',
      sourceResumeTitle: 'Alex Developer — Master Resume',
      status: 'ANALYZED',
    );
  }

  @override
  Future<OptimizationSessionModel> matchRequirements(String sessionId) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    return OptimizationSessionModel(
      id: sessionId,
      sourceResumeId: 'alex-master',
      sourceResumeTitle: 'Alex Developer — Master Resume',
      status: 'READY_FOR_REVIEW',
    );
  }

  @override
  Future<OptimizationAnalysis> analyze({
    required String resumeId,
    required String jobDescription,
    String? jobTitle,
    String? company,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 800));
    if (jobDescription.toLowerCase().contains('network failure')) {
      throw Exception('Network failure. Check your connection and try again.');
    }

    const overview = JobAnalysisOverview(
      jobTitle: 'Junior Flutter Developer',
      company: 'TechNova',
      seniority: 'Junior',
      requiredSkills: ['Flutter', 'Dart', 'REST APIs', 'Git'],
      preferredSkills: ['Firebase', 'Riverpod'],
      responsibilities: [
        'Build and maintain Flutter applications for Android and iOS',
        'Integrate authenticated REST APIs with backend services',
        'Collaborate with product and design in Agile sprints',
      ],
      qualifications: ['Bachelor’s degree in Computer Science or equivalent'],
      experienceRequirements: [
        '1+ years of experience in mobile app development',
      ],
      keywords: [
        'Flutter',
        'Dart',
        'Riverpod',
        'REST APIs',
        'Firebase',
        'Git',
        'Agile',
      ],
      softSkills: ['Communication', 'Teamwork', 'Problem Solving'],
      domainTerms: ['Mobile Development', 'FinTech'],
    );

    const requirements = [
      JobRequirement(
        id: 'req_001',
        name: 'Flutter',
        importance: 'Required',
        category: 'Technical Skill',
        match: RequirementMatch.matched,
        evidence: 'Flutter',
        evidencePath: 'projects[0].technologies[0]',
        evidenceContext: 'Projects → PrepMateAI',
        explanation:
            'Strong evidence across projects and skills: "Built mobile application using Flutter."',
      ),
      JobRequirement(
        id: 'req_002',
        name: 'Dart',
        importance: 'Required',
        category: 'Technical Skill',
        match: RequirementMatch.matched,
        evidence: 'Dart',
        evidencePath: 'skills[0].keywords[1]',
        evidenceContext: 'Skills → Mobile Development',
        explanation: 'Explicitly listed in Mobile Development skills.',
      ),
      JobRequirement(
        id: 'req_003',
        name: 'REST APIs',
        importance: 'Required',
        category: 'Technical Skill',
        match: RequirementMatch.matched,
        evidence:
            'Implemented authenticated REST APIs using Django REST Framework.',
        evidencePath: 'projects[0].highlights[1]',
        evidenceContext: 'Projects → PrepMateAI',
        explanation:
            'Direct evidence in PrepMateAI project highlights: "Implemented authenticated REST APIs."',
      ),
      JobRequirement(
        id: 'req_004',
        name: 'Git',
        importance: 'Required',
        category: 'Tool',
        match: RequirementMatch.matched,
        evidence: 'Git',
        evidencePath: 'skills[1].keywords[2]',
        evidenceContext: 'Skills → Tools',
        explanation: 'Documented in Tools skills section.',
      ),
      JobRequirement(
        id: 'req_005',
        name: 'Riverpod',
        importance: 'Preferred',
        category: 'Technical Skill',
        match: RequirementMatch.partial,
        evidence: 'Riverpod',
        evidencePath: 'skills[0].keywords[2]',
        evidenceContext: 'Skills → Mobile Development',
        explanation:
            'Riverpod is listed in skills, but scope and measurable ownership are not detailed.',
      ),
      JobRequirement(
        id: 'req_006',
        name: 'Mobile Architecture',
        importance: 'Preferred',
        category: 'Technical Skill',
        match: RequirementMatch.partial,
        evidence: 'Clean Architecture',
        evidencePath: 'basics.summary',
        evidenceContext: 'Basics → Summary',
        explanation:
            'Clean Architecture is documented, but additional mobile architecture patterns are not detailed.',
      ),
      JobRequirement(
        id: 'req_007',
        name: 'Bloc',
        importance: 'Required',
        category: 'Technical Skill',
        match: RequirementMatch.missing,
        explanation:
            'No supporting evidence found. Riverpod is present, but Bloc is distinct and not found.',
      ),
      JobRequirement(
        id: 'req_008',
        name: 'Kubernetes',
        importance: 'Preferred',
        category: 'Tool',
        match: RequirementMatch.missing,
        explanation: 'No supporting evidence was found in the supplied resume.',
      ),
      JobRequirement(
        id: 'req_009',
        name: 'AWS',
        importance: 'Preferred',
        category: 'Technology',
        match: RequirementMatch.unclear,
        evidence: 'Cloud deployment and containerization',
        evidencePath: 'basics.summary',
        evidenceContext: 'Basics → Professional Summary',
        explanation:
            'Cloud deployment is mentioned in summary, but AWS is not explicitly documented.',
      ),
    ];

    const suggestions = [
      OptimizationSuggestion(
        id: 'summary',
        section: 'Summary',
        current:
            'Mobile engineer with experience building Flutter applications.',
        proposed:
            'Mobile engineer experienced in building cross-platform Flutter applications with Dart, REST APIs, and clean architecture.',
        reason: 'The JD emphasizes Flutter, Dart, and REST API development.',
        keywords: ['Flutter', 'Dart', 'REST APIs'],
        evidence: 'Projects → PrepMateAI and Skills',
        highImpact: true,
      ),
      OptimizationSuggestion(
        id: 'project',
        section: 'Projects',
        current: 'Built mobile application using Flutter and Riverpod.',
        proposed:
            'Developed responsive Flutter mobile app with Riverpod state management and authenticated REST API integrations.',
        reason:
            'Highlights REST API integration and state management as required by the JD.',
        keywords: ['Flutter', 'REST APIs', 'Riverpod'],
        evidence: 'Projects[0] highlights',
        highImpact: true,
      ),
    ];

    return const OptimizationAnalysis(
      beforeScore: 74,
      afterScore: 88,
      overview: overview,
      requirements: requirements,
      suggestions: suggestions,
      totalRequirements: 9,
      matchedCount: 4,
      partialCount: 2,
      missingCount: 2,
      unclearCount: 1,
      sessionId: 'mock-session-501',
    );
  }

  @override
  Future<String> regenerate(String text, String instruction) async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    if (instruction.toLowerCase().contains('fail')) {
      throw Exception('AI generation failed.');
    }
    return '$text Focused on genuine evidence from your resume.';
  }

  @override
  Future<void> createVersion(String name) async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    if (name.trim().isEmpty) throw Exception('Enter a version name.');
  }

  @override
  Future<List<OptimizationSuggestion>> generateSuggestions(
    String sessionId,
  ) async =>
      (await analyze(resumeId: 'mock', jobDescription: 'mock')).suggestions;

  @override
  Future<OptimizationSuggestion> reviewSuggestion(
    String id,
    SuggestionStatus status, {
    String? value,
    int? decisionVersion,
  }) async => throw UnsupportedError('Mock review is not persisted.');

  @override
  Future<OptimizationSuggestion> regenerateSuggestion(
    String id,
    String instruction,
  ) async => throw UnsupportedError('Mock regeneration is not persisted.');

  @override
  Future<Map<String, dynamic>> finalizeOptimization(
    String sessionId,
    String name, {
    required String idempotencyKey,
    required int expectedSourceVersion,
  }) async => throw UnsupportedError('Mock finalization is not persisted.');

  @override
  Future<int> getAvailableCredits() async => 0;

  @override
  Future<Map<String, dynamic>> getCreditInfo() async => {
    'available_credits': 0,
    'operation_costs': {
      'resume_optimization': 10,
      'suggestion_regeneration': 1,
    },
  };

  @override
  Future<List<int>> getOptimizedPdf(String versionId) async => const [];
}
