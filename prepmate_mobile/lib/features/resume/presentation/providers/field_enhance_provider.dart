import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../config/dio_client.dart';
import '../../../../core/services/ai_service.dart';

enum FieldEnhanceOperation { improveText, generateBullets }

class FieldEnhanceMapping {
  static const _textPaths = {
    'basics.summary',
    'work[].summary',
    'projects[].description',
    'volunteer[].summary',
    'awards[].summary',
    'certificates[].summary',
    'publications[].summary',
  };
  static const _listPaths = {
    'work[].highlights',
    'projects[].highlights',
    'volunteer[].highlights',
  };
  static const _textActions = {
    'improve_section',
    'improve_summary',
    'improve_description',
  };
  static const _listActions = {'generate_bullets', 'suggest_bullets'};

  static FieldEnhanceOperation? resolve(
    String fieldPath,
    Iterable<String> schemaActions,
  ) {
    final actions = schemaActions.map(_normalizeAction).toSet();
    if (_textPaths.contains(fieldPath) && actions.any(_textActions.contains)) {
      return FieldEnhanceOperation.improveText;
    }
    if (_listPaths.contains(fieldPath) && actions.any(_listActions.contains)) {
      return FieldEnhanceOperation.generateBullets;
    }
    return null;
  }

  static String _normalizeAction(String action) =>
      action.trim().toLowerCase().replaceAll('-', '_');
}

class FieldEnhanceException implements Exception {
  const FieldEnhanceException(this.message);
  final String message;

  @override
  String toString() => message;
}

class FieldEnhanceAdapter {
  FieldEnhanceAdapter(this._ai);
  final AIService _ai;

  Future<dynamic> enhance({
    required String fieldPath,
    required List<String> schemaActions,
    required dynamic value,
    Map<String, dynamic> context = const {},
    CancelToken? cancelToken,
  }) async {
    final operation = FieldEnhanceMapping.resolve(fieldPath, schemaActions);
    if (operation == null) {
      throw const FieldEnhanceException(
        'AI enhancement is not enabled for this field.',
      );
    }

    try {
      return switch (operation) {
        FieldEnhanceOperation.improveText => await _improveText(
          fieldPath,
          value,
          cancelToken,
        ),
        FieldEnhanceOperation.generateBullets => await _generateBullets(
          value,
          context,
          cancelToken,
        ),
      };
    } on DioException catch (error) {
      throw FieldEnhanceException(_friendlyDioError(error));
    } on FormatException catch (error) {
      throw FieldEnhanceException(error.message);
    }
  }

  Future<String> draftSummaryFromDetails(
    Map<String, dynamic> resumeData, {
    CancelToken? cancelToken,
  }) async {
    final basics = Map<String, dynamic>.from(
      resumeData['basics'] as Map? ?? const {},
    );
    final role = basics['label']?.toString().trim() ?? '';
    final skills = (resumeData['skills'] as List? ?? const [])
        .whereType<Map>()
        .expand((item) sync* {
          final name = item['name']?.toString().trim() ?? '';
          if (name.isNotEmpty) yield name;
          yield* (item['keywords'] as List? ?? const [])
              .whereType<String>()
              .map((value) => value.trim())
              .where((value) => value.isNotEmpty);
        })
        .toSet()
        .toList();
    if (role.isEmpty || skills.isEmpty) {
      throw const FieldEnhanceException(
        'Add a target role and at least one skill before drafting a summary.',
      );
    }
    final experience = (resumeData['work'] as List? ?? const [])
        .whereType<Map>()
        .expand(
          (item) => [
            item['position']?.toString().trim() ?? '',
            item['summary']?.toString().trim() ?? '',
            ...(item['highlights'] as List? ?? const []).whereType<String>(),
          ],
        )
        .where((value) => value.isNotEmpty)
        .take(25)
        .toList();
    try {
      final result = await _ai.submit('generate-summary', {
        'role': role,
        'skills': skills.take(25).toList(),
        'experience': experience,
        'target_job_description': '',
      }, cancelToken: cancelToken);
      final suggestion = result['summary'];
      if (suggestion is! String || suggestion.trim().isEmpty) {
        throw const FormatException(
          'AI returned an invalid summary suggestion.',
        );
      }
      return suggestion.trim();
    } on DioException catch (error) {
      throw FieldEnhanceException(_friendlyDioError(error));
    }
  }

  Future<String> _improveText(
    String fieldPath,
    dynamic value,
    CancelToken? cancelToken,
  ) async {
    if (value is! String || value.trim().isEmpty) {
      throw const FieldEnhanceException('Enter some text before enhancing it.');
    }
    final result = await _ai.submit('improve-section', {
      'section_name': fieldPath,
      'text': value,
    }, cancelToken: cancelToken);
    final suggestion = result['improved_text'];
    if (suggestion is! String || suggestion.trim().isEmpty) {
      throw const FormatException('AI returned an invalid text suggestion.');
    }
    return suggestion.trim();
  }

  Future<List<String>> _generateBullets(
    dynamic value,
    Map<String, dynamic> context,
    CancelToken? cancelToken,
  ) async {
    if (value is! List) {
      throw const FieldEnhanceException('Expected a list of resume bullets.');
    }
    final responsibilities = value
        .whereType<String>()
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();
    if (responsibilities.isEmpty) {
      throw const FieldEnhanceException(
        'Add at least one bullet before enhancing it.',
      );
    }

    final technologies = context['technologies'] is List
        ? (context['technologies'] as List)
              .whereType<String>()
              .map((item) => item.trim())
              .where((item) => item.isNotEmpty)
              .toList()
        : <String>[];
    final start = context['startDate']?.toString().trim() ?? '';
    final end = context['endDate']?.toString().trim() ?? '';
    final result = await _ai.submit('generate-bullets', {
      'experience': [
        {
          'job_title':
              _firstText(context, const ['position', 'name']) ?? 'Resume entry',
          'company':
              _firstText(context, const ['organization', 'name']) ??
              'Not specified',
          if (start.isNotEmpty || end.isNotEmpty)
            'duration': [
              start,
              end,
            ].where((part) => part.isNotEmpty).join(' - '),
          'responsibilities': responsibilities,
          if (technologies.isNotEmpty) 'technologies': technologies,
        },
      ],
    }, cancelToken: cancelToken);
    final bullets = result['bullets'];
    if (bullets is! List) {
      throw const FormatException('AI returned an invalid bullet suggestion.');
    }
    final parsed = bullets
        .whereType<String>()
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();
    if (parsed.isEmpty) {
      throw const FormatException('AI returned no usable bullets.');
    }
    return parsed;
  }

  static String? _firstText(Map<String, dynamic> context, List<String> keys) {
    for (final key in keys) {
      final value = context[key];
      if (value is String && value.trim().isNotEmpty) return value.trim();
    }
    return null;
  }

  static String _friendlyDioError(DioException error) {
    if (error.type == DioExceptionType.cancel) {
      return 'Enhancement was cancelled.';
    }
    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.sendTimeout ||
        error.type == DioExceptionType.receiveTimeout) {
      return 'The AI request timed out. Please try again.';
    }
    return switch (error.response?.statusCode) {
      401 => 'Your session expired. Please sign in again.',
      429 => 'AI request limit reached. Please wait and try again.',
      500 => 'The AI service is temporarily unavailable.',
      _ => 'Could not reach the AI service. Please try again.',
    };
  }
}

final fieldEnhanceAdapterProvider = Provider<FieldEnhanceAdapter>(
  (ref) => FieldEnhanceAdapter(AIService(ref.watch(dioProvider))),
);
