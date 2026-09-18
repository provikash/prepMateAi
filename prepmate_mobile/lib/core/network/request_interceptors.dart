import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NetworkMetrics {
  NetworkMetrics._();

  static final NetworkMetrics instance = NetworkMetrics._();

  int requests = 0;
  int deduplicated = 0;
  int cacheHits = 0;
  int cacheMisses = 0;
  int cacheStale = 0;

  void reset() {
    requests = 0;
    deduplicated = 0;
    cacheHits = 0;
    cacheMisses = 0;
    cacheStale = 0;
  }
}

/// Adds safe request correlation and duration/size/cache-result diagnostics.
/// Request bodies, query values, authorization, and response content are never
/// logged.
class RequestTelemetryInterceptor extends Interceptor {
  static int _sequence = 0;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final requestId =
        options.headers['X-Request-ID']?.toString() ?? _nextRequestId();
    options.headers['X-Request-ID'] = requestId;
    options.extra['_request_started_us'] =
        DateTime.now().microsecondsSinceEpoch;
    options.extra['_request_id'] = requestId;
    NetworkMetrics.instance.requests++;
    handler.next(options);
  }

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    _log(
      response.requestOptions,
      status: response.statusCode,
      size: _responseSize(response),
    );
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    _log(err.requestOptions, status: err.response?.statusCode);
    handler.next(err);
  }

  static String _nextRequestId() {
    _sequence = (_sequence + 1) & 0x7fffffff;
    return '${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}-${_sequence.toRadixString(36)}';
  }

  static int? _responseSize(Response<dynamic> response) {
    final header = response.headers.value(Headers.contentLengthHeader);
    final parsed = header == null ? null : int.tryParse(header);
    if (parsed != null) return parsed;
    final data = response.data;
    if (data is List<int>) return data.length;
    if (data is String) return utf8.encode(data).length;
    return null;
  }

  static void _log(RequestOptions options, {required int? status, int? size}) {
    if (!kDebugMode) return;
    final started = options.extra['_request_started_us'] as int?;
    final elapsed = started == null
        ? null
        : (DateTime.now().microsecondsSinceEpoch - started) ~/ 1000;
    final requestId = options.extra['_request_id'] ?? '-';
    final cache = options.extra['cache_result'] ?? 'network';
    final path = options.uri.path;
    debugPrint(
      '[HTTP] id=$requestId method=${options.method} path=$path '
      'status=${status ?? '-'} duration_ms=${elapsed ?? '-'} '
      'size_bytes=${size ?? '-'} cache=$cache',
    );
  }
}

class _Flight {
  _Flight(this.requestOptions);

  final RequestOptions requestOptions;
  final completer = Completer<Response<dynamic>>();
  int waiters = 0;
}

/// Coalesces identical concurrent GET/HEAD requests at the network boundary.
///
/// The key includes normalized query parameters and an in-memory fingerprint
/// of the authorization value. The token itself is never persisted or logged.
class SingleFlightInterceptor extends Interceptor {
  final Map<String, _Flight> _flights = {};

  int get inFlightCount => _flights.length;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (!_eligible(options)) return handler.next(options);
    final key = _key(options);
    final active = _flights[key];
    if (active == null) {
      options.extra['_single_flight_key'] = key;
      _flights[key] = _Flight(options);
      return handler.next(options);
    }

    active.waiters++;
    NetworkMetrics.instance.deduplicated++;
    active.completer.future.then(
      (response) {
        options.extra['cache_result'] = 'deduplicated';
        handler.resolve(
          Response<dynamic>(
            requestOptions: options,
            data: response.data,
            headers: response.headers,
            statusCode: response.statusCode,
            statusMessage: response.statusMessage,
            redirects: response.redirects,
            extra: response.extra,
          ),
        );
      },
      onError: (Object error, StackTrace stackTrace) {
        final original = error is DioException
            ? error
            : DioException(requestOptions: options, error: error);
        handler.reject(
          DioException(
            requestOptions: options,
            response: original.response,
            type: original.type,
            error: original.error,
            message: original.message,
            stackTrace: stackTrace,
          ),
        );
      },
    );
  }

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    final key = response.requestOptions.extra['_single_flight_key'] as String?;
    final flight = key == null ? null : _flights.remove(key);
    if (flight != null && flight.waiters > 0 && !flight.completer.isCompleted) {
      flight.completer.complete(response);
    }
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final key = err.requestOptions.extra['_single_flight_key'] as String?;
    final flight = key == null ? null : _flights.remove(key);
    if (flight != null && flight.waiters > 0 && !flight.completer.isCompleted) {
      flight.completer.completeError(err, err.stackTrace);
    }
    handler.next(err);
  }

  void clear() => _flights.clear();

  bool _eligible(RequestOptions options) {
    final method = options.method.toUpperCase();
    return (method == 'GET' || method == 'HEAD') &&
        options.extra['skipDeduplication'] != true;
  }

  String _key(RequestOptions options) {
    final query = options.queryParameters.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    final normalizedQuery = query
        .map((entry) => '${entry.key}=${_normalize(entry.value)}')
        .join('&');
    final authorization = options.headers['Authorization']?.toString() ?? '';
    final locale = options.headers['Accept-Language']?.toString() ?? '';
    return '${options.method.toUpperCase()}|${options.uri.path}|$normalizedQuery|'
        '${authorization.hashCode}|$locale';
  }

  String _normalize(dynamic value) {
    if (value is Iterable) {
      final values = value.map((item) => item.toString()).toList()..sort();
      return values.join(',');
    }
    return value?.toString() ?? '';
  }
}

/// Persists validators only for explicitly public template endpoints. Private
/// profile/resume/ATS/PDF responses never enter this HTTP cache.
class PublicConditionalCacheInterceptor extends Interceptor {
  static const _prefix = 'prepmate_http_validator_v1_';

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (!_eligible(options)) return handler.next(options);
    final key = _key(options);
    final encoded = (await SharedPreferences.getInstance()).getString(
      '$_prefix$key',
    );
    if (encoded != null) {
      try {
        final entry = jsonDecode(encoded) as Map<String, dynamic>;
        final etag = entry['etag'] as String?;
        if (etag != null && etag.isNotEmpty) {
          options.headers['If-None-Match'] = etag;
        }
        options.extra['_conditional_body'] = entry['body'];
      } catch (_) {
        await (await SharedPreferences.getInstance()).remove('$_prefix$key');
      }
    }
    options.extra['_conditional_key'] = key;
    options.validateStatus = (status) => status != null && status < 400;
    handler.next(options);
  }

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) async {
    final key = response.requestOptions.extra['_conditional_key'] as String?;
    if (key == null) return handler.next(response);
    if (response.statusCode == 304) {
      final body = response.requestOptions.extra['_conditional_body'];
      if (body != null) {
        response.data = body;
        response.statusCode = 200;
        response.requestOptions.extra['cache_result'] = 'validated-304';
        NetworkMetrics.instance.cacheHits++;
      }
      return handler.next(response);
    }

    final etag = response.headers.value('etag');
    if (response.statusCode == 200 && etag != null && response.data != null) {
      try {
        await (await SharedPreferences.getInstance()).setString(
          '$_prefix$key',
          jsonEncode({'etag': etag, 'body': response.data}),
        );
      } catch (_) {
        // Validation caching is an optimization; never fail a valid response.
      }
    }
    handler.next(response);
  }

  bool _eligible(RequestOptions options) {
    if (options.method.toUpperCase() != 'GET') return false;
    final path = options.uri.path;
    return path.contains('/templates/') || path.endsWith('/templates');
  }

  String _key(RequestOptions options) {
    final query = options.queryParameters.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    return '${options.uri.path}?${query.map((entry) => '${entry.key}=${entry.value}').join('&')}'
        .hashCode
        .toUnsigned(32)
        .toRadixString(16);
  }
}
