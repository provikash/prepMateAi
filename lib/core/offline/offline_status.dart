class OfflineStatus {
  const OfflineStatus({
    this.isOffline = false,
    this.isStale = false,
    this.isRefreshing = false,
    this.updatedAt,
  });

  final bool isOffline;
  final bool isStale;
  final bool isRefreshing;
  final DateTime? updatedAt;

  bool get shouldShow => isOffline || isStale || isRefreshing;

  OfflineStatus copyWith({
    bool? isOffline,
    bool? isStale,
    bool? isRefreshing,
    DateTime? updatedAt,
  }) => OfflineStatus(
    isOffline: isOffline ?? this.isOffline,
    isStale: isStale ?? this.isStale,
    isRefreshing: isRefreshing ?? this.isRefreshing,
    updatedAt: updatedAt ?? this.updatedAt,
  );
}
