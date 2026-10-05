import 'package:dio/dio.dart';

import '../../../../core/services/storage.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../models/user_model.dart';

class AuthRemoteDataSource {
  AuthRemoteDataSource(this.dio);
  final Dio dio;

  Future<OtpChallengeData> requestOtp(String phoneNumber) async {
    final response = await dio.post(
      'auth/otp/request/',
      data: {'phone_number': phoneNumber},
    );
    return _challenge(response.data as Map<String, dynamic>);
  }

  Future<OtpChallengeData> resendOtp(
    String phoneNumber,
    String challengeId,
  ) async {
    final response = await dio.post(
      'auth/otp/resend/',
      data: {'phone_number': phoneNumber, 'challenge_id': challengeId},
    );
    return _challenge(response.data as Map<String, dynamic>);
  }

  OtpChallengeData _challenge(Map<String, dynamic> data) => OtpChallengeData(
    challengeId: data['challenge_id'].toString(),
    resendAfterSeconds:
        (data['resend_available_in_seconds'] as num?)?.toInt() ?? 60,
  );

  Future<User> verifyOtp(
    String phoneNumber,
    String challengeId,
    String otp,
  ) async {
    final response = await dio.post(
      'auth/otp/verify/',
      data: {
        'phone_number': phoneNumber,
        'challenge_id': challengeId,
        'otp': otp,
      },
    );
    final data = response.data as Map<String, dynamic>;
    final access = data['access']?.toString();
    final refresh = data['refresh']?.toString();
    final rawUser = data['user'];
    if (access == null ||
        access.isEmpty ||
        refresh == null ||
        refresh.isEmpty ||
        rawUser is! Map<String, dynamic>) {
      throw const FormatException('Invalid authentication response.');
    }
    await TokenService.saveTokens(accessToken: access, refreshToken: refresh);
    return UserModel.fromJson(rawUser);
  }

  Future<void> logout() async {
    final refresh = await TokenService.getRefreshToken();
    try {
      if (refresh != null && refresh.isNotEmpty) {
        await dio.post('auth/logout/', data: {'refresh': refresh});
      }
    } on DioException catch (error) {
      if (error.response?.statusCode != 400 &&
          error.response?.statusCode != 401) {
        rethrow;
      }
    } finally {
      await TokenService.deleteToken();
    }
  }

  Future<User?> getProfile() async {
    final summaryResponse = await dio.get('auth/me/');
    final summaryPayload = summaryResponse.data as Map<String, dynamic>;
    final summary = summaryPayload['data'] is Map<String, dynamic>
        ? summaryPayload['data'] as Map<String, dynamic>
        : summaryPayload;
    final profileResponse = await dio.get('profile/');
    return UserModel.fromJson({
      ...profileResponse.data as Map<String, dynamic>,
      ...summary,
    });
  }

  Future<User?> updateProfile(User user) async {
    final response = await dio.patch(
      'profile/',
      data: {
        'full_name': user.fullName ?? '',
        'location': user.location ?? '',
        'job_title': user.title ?? '',
        'bio': user.bio ?? '',
        'linkedin': user.linkedin ?? '',
        'github': user.github ?? '',
      },
    );
    final summaryResponse = await dio.get('auth/me/');
    final payload = summaryResponse.data as Map<String, dynamic>;
    final summary = payload['data'] is Map<String, dynamic>
        ? payload['data'] as Map<String, dynamic>
        : payload;
    return UserModel.fromJson({
      ...response.data as Map<String, dynamic>,
      ...summary,
    });
  }

  Future<User?> uploadProfileImage(String filePath) async {
    final formData = FormData.fromMap({
      'profile_image': await MultipartFile.fromFile(
        filePath,
        filename: 'profile_image.jpg',
      ),
    });
    await dio.patch('profile/', data: formData);
    return getProfile();
  }
}
