import 'package:dio/dio.dart';
import '../../domain/entities/user.dart';
import '../models/user_model.dart';
import '../../../../core/services/storage.dart';

class AuthRemoteDataSource {
  final Dio dio;

  AuthRemoteDataSource(this.dio);

  Future<User?> login(String email, String password) async {
    final response = await dio.post(
      'auth/login/',
      data: {'email': email, 'password': password},
    );

    final token = response.data["tokens"]?["access"];
    final userData = response.data["user"];

    if (token != null) {
      await TokenService.saveToken(token);
      return UserModel.fromJson(userData);
    }

    return null;
  }

  Future<bool> signup(String name, String email, String password) async {
    final response = await dio.post(
      'auth/register/',
      data: {'full_name': name, 'email': email, 'password': password},
    );

    return response.statusCode == 200 || response.statusCode == 201;
  }

  Future<bool> verifyOtp(String email, String otp, String flow) async {
    final endpoint = flow == 'login'
        ? 'auth/verify-login-otp/'
        : 'users/verify-otp/';

    final response = await dio.post(
      endpoint,
      data: {"email": email, "otp": otp},
    );

    return response.statusCode == 200;
  }

  Future<void> logout() async {
    await TokenService.deleteToken();
  }

  Future<bool> forgotPassword(String email) async {
    final response = await dio.post(
      'auth/forgot-password/',
      data: {'email': email},
    );

    return response.statusCode == 200;
  }
}
