class PrepMateHomeState {
  final String userName;
  final String role;
  final double progress; // e.g., 0.8 for 80%
  final String aiSuggestion;
  final String progressStatus; // e.g., "Draft"

  PrepMateHomeState({
    required this.userName,
    required this.role,
    required this.progress,
    required this.aiSuggestion,
    required this.progressStatus,
  });

  // A copyWith method is essential for updating specific fields
  // without overriding the whole state.
  PrepMateHomeState copyWith({
    String? userName,
    String? role,
    double? progress,
    String? aiSuggestion,
    String? progressStatus,
  }) {
    return PrepMateHomeState(
      userName: userName ?? this.userName,
      role: role ?? this.role,
      progress: progress ?? this.progress,
      aiSuggestion: aiSuggestion ?? this.aiSuggestion,
      progressStatus: progressStatus ?? this.progressStatus,
    );
  }
}
