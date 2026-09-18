enum RequirementMatch { matched, partial, missing }

enum SuggestionStatus { pending, accepted, rejected, edited }

class JobRequirement {
  const JobRequirement({
    required this.name,
    required this.importance,
    required this.match,
    required this.explanation,
    this.evidence,
  });

  final String name;
  final String importance;
  final RequirementMatch match;
  final String explanation;
  final String? evidence;
}

class OptimizationSuggestion {
  const OptimizationSuggestion({
    required this.id,
    required this.section,
    required this.current,
    required this.proposed,
    required this.reason,
    required this.keywords,
    required this.evidence,
    this.highImpact = false,
    this.status = SuggestionStatus.pending,
  });

  final String id;
  final String section;
  final String current;
  final String proposed;
  final String reason;
  final List<String> keywords;
  final String evidence;
  final bool highImpact;
  final SuggestionStatus status;

  OptimizationSuggestion copyWith({
    String? proposed,
    SuggestionStatus? status,
  }) {
    return OptimizationSuggestion(
      id: id,
      section: section,
      current: current,
      proposed: proposed ?? this.proposed,
      reason: reason,
      keywords: keywords,
      evidence: evidence,
      highImpact: highImpact,
      status: status ?? this.status,
    );
  }
}

class OptimizationAnalysis {
  const OptimizationAnalysis({
    required this.beforeScore,
    required this.afterScore,
    required this.requirements,
    required this.suggestions,
  });

  final int beforeScore;
  final int afterScore;
  final List<JobRequirement> requirements;
  final List<OptimizationSuggestion> suggestions;
}
