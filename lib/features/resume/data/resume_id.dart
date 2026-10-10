final RegExp _serverResumeIdPattern = RegExp(
  r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-5][0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}$',
);

/// Returns a server-safe UUID, or null for offline IDs such as `local-*`.
String? serverResumeIdOrNull(String? value) {
  final candidate = value?.trim();
  if (candidate == null || !_serverResumeIdPattern.hasMatch(candidate)) {
    return null;
  }
  return candidate;
}
