import 'dart:io';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../models/created_resume_model.dart';
import '../models/resume_model.dart';
import '../models/template_detail_model.dart';

enum ResumeSaveFailureKind {
  validation,
  authentication,
  connection,
  timeout,
  server,
  unknown,
}

class ResumeSaveException implements Exception {
  const ResumeSaveException({
    required this.kind,
    required this.message,
    this.statusCode,
    this.fieldErrors = const {},
  });

  final ResumeSaveFailureKind kind;
  final String message;
  final int? statusCode;
  final Map<String, String> fieldErrors;

  @override
  String toString() => message;
}

class PdfFetchResult {
  const PdfFetchResult({required this.notModified, this.bytes, this.etag});

  final bool notModified;
  final Uint8List? bytes;
  final String? etag;
}

class ResumeRemoteDataSource {
  final Dio dio;

  ResumeRemoteDataSource({required this.dio});

  String _normalizeDioError(Object error) {
    if (error is DioException) {
      if (error.type == DioExceptionType.connectionError ||
          error.error is SocketException) {
        return 'No internet connection. Please check your network and try again.';
      }
      if (error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.receiveTimeout ||
          error.type == DioExceptionType.sendTimeout) {
        return 'Request timed out. Please try again.';
      }
      final data = error.response?.data;
      if (data is Map<String, dynamic>) {
        if (data['detail'] != null) {
          return data['detail'].toString();
        }
        if (data['message'] != null) {
          return data['message'].toString();
        }
        return data.entries
            .map((entry) => '${entry.key}: ${entry.value}')
            .join('\n');
      }
      return error.message ?? 'Network error';
    }
    return error.toString();
  }

  Future<TemplateDetailModel> getTemplateDetail(String id) async {
    try {
      final response = await dio.get('templates/$id/');
      final data = response.data;
      if (data is Map<String, dynamic>) {
        return TemplateDetailModel.fromJson(data);
      }
      if (data is List && data.isNotEmpty && data[0] is Map<String, dynamic>) {
        // sometimes backend returns a list — pick the first item
        return TemplateDetailModel.fromJson(data[0] as Map<String, dynamic>);
      }
      throw Exception('Unexpected template format: ${data.runtimeType}');
    } catch (error) {
      throw Exception(
        'Failed to load template detail: ${_normalizeDioError(error)}',
      );
    }
  }

  Future<CreatedResumeModel> createResume({
    required String templateId,
    required String title,
    required Map<String, dynamic> data,
  }) async {
    try {
      // Build a proper JSON Resume payload. The `data` map already contains
      // the section keys (basics, work, education, projects, skills).
      // We pass it verbatim as the `data` field; the backend normalises it.
      if (kDebugMode) {
        final sectionCounts = <String, Object?>{
          for (final entry in data.entries)
            entry.key: entry.value is List
                ? (entry.value as List).length
                : entry.value is Map
                ? (entry.value as Map).keys.toList()
                : entry.value.runtimeType.toString(),
        };
        debugPrint(
          '[Resume Save] redacted payload summary: ${jsonEncode(sectionCounts)}',
        );
      }
      final response = await dio.post(
        'resumes/',
        data: {'template_id': templateId, 'title': title, 'data': data},
      );
      return CreatedResumeModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (error) {
      debugPrint(
        '[Resume Save] failed: ${error.response?.statusCode} ${error.response?.data}',
      );
      throw Exception('Failed to create resume: ${_normalizeDioError(error)}');
    } catch (error) {
      debugPrint('[Resume Save] unexpected error: $error');
      throw Exception('Failed to create resume: ${_normalizeDioError(error)}');
    }
  }

  Future<CreatedResumeModel> saveResume({
    String? resumeId,
    required String templateId,
    required String title,
    required Map<String, dynamic> data,
    required bool draft,
  }) async {
    try {
      final payload = {
        'template_id': templateId,
        'title': title,
        'data': data,
        'metadata': {'status': draft ? 'draft' : 'complete'},
      };
      final response = resumeId == null
          ? await dio.post('resumes/', data: payload)
          : await dio.patch('resumes/$resumeId/', data: payload);
      return CreatedResumeModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (error) {
      throw _saveException(error);
    } on FormatException {
      throw const ResumeSaveException(
        kind: ResumeSaveFailureKind.server,
        message: 'The server returned an invalid save response. Please retry.',
      );
    }
  }

  ResumeSaveException _saveException(DioException error) {
    final statusCode = error.response?.statusCode;
    final data = error.response?.data;
    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.sendTimeout ||
        error.type == DioExceptionType.receiveTimeout) {
      return const ResumeSaveException(
        kind: ResumeSaveFailureKind.timeout,
        message: 'Saving timed out. Check your connection and try again.',
      );
    }
    if (error.type == DioExceptionType.connectionError ||
        error.error is SocketException) {
      return const ResumeSaveException(
        kind: ResumeSaveFailureKind.connection,
        message: 'Cannot reach the server. Check the API address and network.',
      );
    }
    if (statusCode == 400) {
      final fields = _flattenErrors(data);
      return ResumeSaveException(
        kind: ResumeSaveFailureKind.validation,
        statusCode: statusCode,
        fieldErrors: fields,
        message: fields.isEmpty
            ? 'The resume contains invalid fields. Review the form and retry.'
            : 'Please correct ${fields.entries.first.key}: ${fields.entries.first.value}',
      );
    }
    if (statusCode == 401) {
      return const ResumeSaveException(
        kind: ResumeSaveFailureKind.authentication,
        statusCode: 401,
        message:
            'Your session expired. Sign in again; your form data is still here.',
      );
    }
    if (statusCode != null && statusCode >= 500) {
      return ResumeSaveException(
        kind: ResumeSaveFailureKind.server,
        statusCode: statusCode,
        message:
            'The server could not save the resume. Please try again shortly.',
      );
    }
    return ResumeSaveException(
      kind: ResumeSaveFailureKind.unknown,
      statusCode: statusCode,
      message: 'Could not save the resume. Please try again.',
    );
  }

  Map<String, String> _flattenErrors(dynamic value, [String path = '']) {
    final result = <String, String>{};
    if (value is Map) {
      for (final entry in value.entries) {
        final entryKey = entry.key.toString();
        final key = path.isEmpty && entryKey == 'data'
            ? ''
            : path.isEmpty
            ? entryKey
            : '$path.$entryKey';
        result.addAll(_flattenErrors(entry.value, key));
      }
    } else if (value is List) {
      for (var index = 0; index < value.length; index++) {
        final key = path.isEmpty ? '[$index]' : '$path[$index]';
        result.addAll(_flattenErrors(value[index], key));
      }
    } else if (value != null) {
      result[path.isEmpty ? 'resume' : path] = value.toString();
    }
    return result;
  }

  Future<String> getResumePdfUrl(String id) async {
    final base = dio.options.baseUrl;
    return '$base/resumes/$id/pdf/'.replaceAll('//resumes', '/resumes');
  }

  Future<Uint8List> getResumePdfBytes(String id) async {
    final result = await fetchResumePdf(id);
    if (result.bytes == null) throw Exception('Empty PDF response');
    return result.bytes!;
  }

  Future<PdfFetchResult> fetchResumePdf(String id, {String? etag}) async {
    try {
      final response = await dio.get<List<int>>(
        'resumes/$id/pdf/',
        options: Options(
          responseType: ResponseType.bytes,
          headers: etag == null ? null : {'If-None-Match': etag},
          validateStatus: (status) => status == 200 || status == 304,
        ),
      );
      if (response.statusCode == 304) {
        return PdfFetchResult(notModified: true, etag: etag);
      }
      final bytes = response.data;
      if (bytes == null || bytes.isEmpty) {
        throw Exception('Empty PDF response');
      }
      return PdfFetchResult(
        notModified: false,
        bytes: Uint8List.fromList(bytes),
        etag: response.headers.value('etag'),
      );
    } on DioException catch (error) {
      final status = error.response?.statusCode;
      final message = switch (status) {
        400 =>
          'This resume contains data that the selected template cannot render.',
        401 => 'Your session expired. Sign in again, then retry.',
        404 => 'This resume or its template could not be found.',
        429 => 'Too many PDF requests. Wait a moment, then retry.',
        500 ||
        503 => 'The server could not generate the PDF. Please try again.',
        _ => _normalizeDioError(error),
      };
      throw Exception(message);
    } catch (error) {
      throw Exception('Failed to load PDF: ${_normalizeDioError(error)}');
    }
  }

  Future<Uint8List> downloadPdf(String id) {
    return getResumePdfBytes(id);
  }

  Future<void> deleteResume(String id) async {
    try {
      await dio.delete('resumes/$id/');
    } catch (error) {
      throw Exception('Failed to delete resume: ${_normalizeDioError(error)}');
    }
  }

  Future<List<ResumeModel>> getResumes() async {
    try {
      final response = await dio.get('resumes/');
      final payload = response.data;
      final list = payload is Map<String, dynamic>
          ? (payload['results'] as List?) ?? const []
          : payload as List? ?? const [];
      return list
          .whereType<Map<String, dynamic>>()
          .map(ResumeModel.fromJson)
          .toList();
    } catch (error) {
      throw Exception('Failed to load resumes: ${_normalizeDioError(error)}');
    }
  }

  Future<List<Map<String, dynamic>>> getTemplates() async {
    try {
      final response = await dio.get('templates/');
      final payload = response.data;
      final list = payload is Map<String, dynamic>
          ? (payload['results'] as List?) ?? const []
          : payload as List? ?? const [];
      return list.whereType<Map<String, dynamic>>().map((e) => e).toList();
    } catch (error) {
      throw Exception('Failed to load templates: ${_normalizeDioError(error)}');
    }
  }
}
