import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../../auth/data/models/user_model.dart';

const supportedProfilePatchFields = <String>{
  'full_name',
  'phone',
  'location',
  'job_title',
  'headline',
  'bio',
  'linkedin',
  'linkedin_url',
  'github',
  'github_url',
  'portfolio_url',
};

Map<String, dynamic> normalizeProfilePatch(Map<String, dynamic> data) => {
  for (final entry in data.entries)
    if (supportedProfilePatchFields.contains(entry.key) && entry.value != null)
      entry.key: entry.value is String
          ? (entry.value as String).trim()
          : entry.value,
};

class ProfileApiException implements Exception {
  const ProfileApiException(this.message, {this.fieldErrors = const {}});

  final String message;
  final Map<String, String> fieldErrors;

  @override
  String toString() => message;
}

class ProfileRemoteDataSource {
  final Dio dio;

  ProfileRemoteDataSource(this.dio);

  Map<String, dynamic> _dataMap(dynamic payload) {
    if (payload is! Map) return <String, dynamic>{};
    final mapped = Map<String, dynamic>.from(payload);
    final data = mapped['data'];
    return data is Map ? Map<String, dynamic>.from(data) : mapped;
  }

  Future<Map<String, dynamic>> _summary() async {
    final response = await dio.get('auth/me/');
    return _dataMap(response.data);
  }

  ProfileApiException _normalizeError(Object error) {
    if (error is DioException) {
      if (error.type == DioExceptionType.connectionError ||
          error.error is SocketException) {
        return const ProfileApiException(
          'The server could not be reached. Check your connection and retry.',
        );
      }
      if (error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.sendTimeout ||
          error.type == DioExceptionType.receiveTimeout) {
        return const ProfileApiException(
          'The request timed out. Check your connection and retry.',
        );
      }
      final data = error.response?.data;
      if (data is Map) {
        if (data['detail'] != null) {
          return ProfileApiException(data['detail'].toString());
        }
        if (data['message'] != null) {
          return ProfileApiException(data['message'].toString());
        }
        final fieldErrors = <String, String>{
          for (final entry in data.entries)
            entry.key.toString(): _errorText(entry.value),
        };
        if (fieldErrors.isNotEmpty) {
          return ProfileApiException(
            'Please check the highlighted fields. Your changes were not saved.',
            fieldErrors: fieldErrors,
          );
        }
      }
      return ProfileApiException(switch (error.response?.statusCode) {
        401 => 'Your session expired. Please sign in again.',
        403 => 'You do not have permission to update this profile.',
        429 => 'Too many requests. Please wait and try again.',
        500 => 'The server could not save your changes. Please retry.',
        _ => 'Your changes were not saved.',
      });
    }
    return const ProfileApiException('Your changes were not saved.');
  }

  static String _errorText(dynamic value) {
    if (value is List && value.isNotEmpty) return _errorText(value.first);
    if (value is Map && value.isNotEmpty) return _errorText(value.values.first);
    return value?.toString() ?? 'Invalid value.';
  }

  Future<UserModel> getProfile() async {
    try {
      final profileResponse = await dio.get('profile/');
      final summary = await _summary();

      final merged = <String, dynamic>{
        ...summary,
        ..._dataMap(profileResponse.data),
      };
      return UserModel.fromJson(merged);
    } catch (error) {
      throw _normalizeError(error);
    }
  }

  Future<UserModel> updateProfile(Map<String, dynamic> data) async {
    final payload = normalizeProfilePatch(data);
    try {
      final response = await dio.patch('profile/', data: payload);
      _logResult(response, payload.keys);
      final summary = await _summary();

      final merged = <String, dynamic>{...summary, ..._dataMap(response.data)};
      return UserModel.fromJson(merged);
    } catch (error) {
      _logFailure(error, payload.keys);
      throw _normalizeError(error);
    }
  }

  Future<UserModel> uploadProfileImage(String filePath) async {
    try {
      final formData = FormData.fromMap({
        'profile_image': await MultipartFile.fromFile(filePath),
      });

      final response = await dio.patch('profile/', data: formData);
      final summary = await _summary();

      final merged = <String, dynamic>{...summary, ..._dataMap(response.data)};
      return UserModel.fromJson(merged);
    } catch (error) {
      throw _normalizeError(error);
    }
  }

  void _logResult(Response<dynamic> response, Iterable<String> fields) {
    if (!kDebugMode) return;
    final sorted = fields.toList()..sort();
    debugPrint(
      '[Profile API] method=PATCH endpoint=/profile/ status=${response.statusCode} '
      'request_id=${response.requestOptions.extra['_request_id'] ?? '-'} fields=$sorted',
    );
  }

  void _logFailure(Object error, Iterable<String> fields) {
    if (!kDebugMode || error is! DioException) return;
    final sorted = fields.toList()..sort();
    final body = error.response?.data;
    final errorKeys = body is Map
        ? (body.keys.map((key) => key.toString()).toList()..sort())
        : const <String>[];
    debugPrint(
      '[Profile API] method=PATCH endpoint=/profile/ status=${error.response?.statusCode ?? '-'} '
      'request_id=${error.requestOptions.extra['_request_id'] ?? '-'} fields=$sorted error_keys=$errorKeys',
    );
  }
}
