import 'dart:io';

import 'package:dio/dio.dart';

import '../../../auth/data/models/user_model.dart';

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

  String _normalizeError(Object error) {
    if (error is DioException) {
      if (error.type == DioExceptionType.connectionError ||
          error.error is SocketException) {
        return 'No internet connection.';
      }
      final data = error.response?.data;
      if (data is Map<String, dynamic>) {
        if (data['detail'] != null) {
          return data['detail'].toString();
        }
        if (data['message'] != null) {
          return data['message'].toString();
        }
      }
      return error.message ?? 'Network error';
    }
    return error.toString();
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
      throw Exception('Failed to load profile: ${_normalizeError(error)}');
    }
  }

  Future<UserModel> updateProfile(Map<String, dynamic> data) async {
    try {
      final response = await dio.patch('profile/', data: data);
      final summary = await _summary();

      final merged = <String, dynamic>{...summary, ..._dataMap(response.data)};
      return UserModel.fromJson(merged);
    } catch (error) {
      throw Exception('Failed to update profile: ${_normalizeError(error)}');
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
      throw Exception(
        'Failed to upload profile image: ${_normalizeError(error)}',
      );
    }
  }
}
