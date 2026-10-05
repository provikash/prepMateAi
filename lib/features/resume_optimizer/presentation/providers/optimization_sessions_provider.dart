import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/optimization_models.dart';
import '../../domain/optimization_repository.dart';
import 'optimization_provider.dart';

class OptimizationHistoryFilter {
  const OptimizationHistoryFilter({
    this.searchQuery = '',
    this.statusFilter = 'all',
    this.selectedResumeId,
    this.ordering = 'recently_updated',
  });

  final String searchQuery;
  final String statusFilter;
  final String? selectedResumeId;
  final String ordering;

  int get activeFilterCount {
    var count = 0;
    if (statusFilter != 'all') count++;
    if (selectedResumeId != null && selectedResumeId!.isNotEmpty) count++;
    if (ordering != 'recently_updated') count++;
    if (searchQuery.isNotEmpty) count++;
    return count;
  }

  OptimizationHistoryFilter copyWith({
    String? searchQuery,
    String? statusFilter,
    String? selectedResumeId,
    bool clearResume = false,
    String? ordering,
  }) {
    return OptimizationHistoryFilter(
      searchQuery: searchQuery ?? this.searchQuery,
      statusFilter: statusFilter ?? this.statusFilter,
      selectedResumeId: clearResume
          ? null
          : (selectedResumeId ?? this.selectedResumeId),
      ordering: ordering ?? this.ordering,
    );
  }
}

class OptimizationHistoryState {
  const OptimizationHistoryState({
    this.isLoading = false,
    this.isRefreshing = false,
    this.sessions = const [],
    this.error,
    this.isOffline = false,
    this.filter = const OptimizationHistoryFilter(),
  });

  final bool isLoading;
  final bool isRefreshing;
  final List<OptimizationSessionModel> sessions;
  final String? error;
  final bool isOffline;
  final OptimizationHistoryFilter filter;

  OptimizationHistoryState copyWith({
    bool? isLoading,
    bool? isRefreshing,
    List<OptimizationSessionModel>? sessions,
    String? error,
    bool clearError = false,
    bool? isOffline,
    OptimizationHistoryFilter? filter,
  }) {
    return OptimizationHistoryState(
      isLoading: isLoading ?? this.isLoading,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      sessions: sessions ?? this.sessions,
      error: clearError ? null : (error ?? this.error),
      isOffline: isOffline ?? this.isOffline,
      filter: filter ?? this.filter,
    );
  }
}

class OptimizationHistoryNotifier
    extends StateNotifier<OptimizationHistoryState> {
  OptimizationHistoryNotifier(this._repository)
    : super(const OptimizationHistoryState()) {
    loadSessions();
  }

  final OptimizationRepository _repository;
  Timer? _debounceTimer;

  Future<void> loadSessions({bool refresh = false}) async {
    if (refresh) {
      state = state.copyWith(isRefreshing: true, clearError: true);
    } else {
      state = state.copyWith(isLoading: true, clearError: true);
    }

    try {
      final statusParam = state.filter.statusFilter == 'all'
          ? null
          : state.filter.statusFilter;

      final sessions = await _repository.getOptimizationSessions(
        status: statusParam,
        search: state.filter.searchQuery.isEmpty
            ? null
            : state.filter.searchQuery,
        resumeId: state.filter.selectedResumeId,
        ordering: state.filter.ordering,
      );

      state = state.copyWith(
        isLoading: false,
        isRefreshing: false,
        sessions: sessions,
        isOffline: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        isRefreshing: false,
        error: e.toString(),
        isOffline:
            e.toString().toLowerCase().contains('offline') ||
            e.toString().toLowerCase().contains('socket'),
      );
    }
  }

  void setSearchQuery(String query) {
    if (state.filter.searchQuery == query) return;
    state = state.copyWith(filter: state.filter.copyWith(searchQuery: query));

    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 350), () {
      loadSessions();
    });
  }

  void setStatusFilter(String status) {
    if (state.filter.statusFilter == status) return;
    state = state.copyWith(filter: state.filter.copyWith(statusFilter: status));
    loadSessions();
  }

  void setFilters({String? status, String? resumeId, String? ordering}) {
    state = state.copyWith(
      filter: state.filter.copyWith(
        statusFilter: status,
        selectedResumeId: resumeId,
        clearResume: resumeId == null || resumeId.isEmpty,
        ordering: ordering,
      ),
    );
    loadSessions();
  }

  void resetFilters() {
    state = state.copyWith(filter: const OptimizationHistoryFilter());
    loadSessions();
  }

  Future<void> deleteSession(String sessionId) async {
    try {
      await _repository.deleteOptimizationSession(sessionId);
      state = state.copyWith(
        sessions: state.sessions.where((s) => s.id != sessionId).toList(),
      );
    } catch (e) {
      state = state.copyWith(error: 'Failed to delete session: $e');
    }
  }

  Future<void> archiveSession(String sessionId) async {
    try {
      await _repository.updateOptimizationSession(sessionId, {
        'status': 'CANCELLED',
      });
      loadSessions();
    } catch (e) {
      state = state.copyWith(error: 'Failed to archive session: $e');
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }
}

final optimizationHistoryProvider =
    StateNotifierProvider<
      OptimizationHistoryNotifier,
      OptimizationHistoryState
    >((ref) {
      final repository = ref.watch(optimizationRepositoryProvider);
      return OptimizationHistoryNotifier(repository);
    });

final optimizationDetailProvider =
    FutureProvider.family<OptimizationSessionModel, String>((ref, sessionId) {
      final repository = ref.watch(optimizationRepositoryProvider);
      return repository.getOptimizationSession(sessionId);
    });
