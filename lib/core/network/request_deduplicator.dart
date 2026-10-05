import 'dart:async';

/// Coalesces concurrent work for the same stable key into one Future.
///
/// Entries are always removed after completion, including failures. This is
/// intentionally not a response cache: it only prevents overlapping work.
class RequestDeduplicator {
  final Map<String, Future<Object?>> _inFlight = {};

  int get inFlightCount => _inFlight.length;

  Future<T> run<T>(String key, Future<T> Function() operation) {
    final existing = _inFlight[key];
    if (existing != null) return existing.then((value) => value as T);

    final future = Future<T>.sync(operation);
    _inFlight[key] = future;
    return future.whenComplete(() {
      if (identical(_inFlight[key], future)) _inFlight.remove(key);
    });
  }

  void clear() => _inFlight.clear();
}
