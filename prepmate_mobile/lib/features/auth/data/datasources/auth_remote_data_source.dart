import 'package:dio/dio.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../domain/entities/user.dart';
import '../models/user_model.dart';
import '../../../../core/services/storage.dart';

class AuthRemoteDataSource {
  final Dio dio;
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;

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

  Future<User?> signInWithGoogle() async {
    await _googleSignIn.initialize();
    final GoogleSignInAccount account = await _googleSignIn.authenticate();
    final auth = account.authentication;
    final idToken = auth.idToken;

    if (idToken == null || idToken.isEmpty) {
      throw Exception('Google sign-in failed: missing id token');
    }

    final response = await dio.post(
      'auth/google/',
      data: {
        'token': idToken,
        'id_token': idToken,
      },
    );

    final data = response.data as Map<String, dynamic>;
    final token =
        data['tokens']?['access'] ?? data['access'] ?? data['access_token'];
    final userData = (data['user'] ?? data) as Map<String, dynamic>;

    if (token != null) {
      await TokenService.saveToken(token.toString());
    }

    return UserModel.fromJson(userData);
  }

  Future<bool> signup(String name, String email, String password) async {
    final response = await dio.post(
      'auth/register/',
      data: {
        'name': name,
        'email': email,
        'password': password,
        'password_confirm': password,
      },
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
    await _googleSignIn.signOut();
    await TokenService.deleteToken();
  }

  Future<bool> forgotPassword(String email) async {
    final response = await dio.post(
      'auth/forgot-password/',
      data: {'email': email},
    );

    return response.statusCode == 200;
  }

  Future<User?> getProfile() async {
    final summaryResponse = await dio.get('profile/');
    final profileResponse = await dio.get('profile/');

    final merged = <String, dynamic>{
      ...(summaryResponse.data as Map<String, dynamic>),
      ...(profileResponse.data as Map<String, dynamic>),
    };
    return UserModel.fromJson(merged);
  }

  Future<User?> updateProfile(User user) async {
    final response = await dio.patch(
      'profile/',
      data: {
        'full_name': user.fullName ?? '',
        'phone': user.phoneNumber ?? '',
        'location': user.location ?? '',
        'job_title': user.title ?? '',
        'bio': user.bio ?? '',
        'linkedin': user.linkedin ?? '',
        'github': user.github ?? '',
      },
    );

    final summaryResponse = await dio.get('profile');
    final merged = <String, dynamic>{
      ...(summaryResponse.data as Map<String, dynamic>),
      ...(response.data as Map<String, dynamic>),
    };

    return UserModel.fromJson(merged);
  }

  Future<User?> uploadProfileImage(String filePath) async {
    final formData = FormData.fromMap({
      'profile_image': await MultipartFile.fromFile(
        filePath,
        filename: 'profile_image.jpg',
      ),
    });

    final response = await dio.patch('profile/', data: formData);
    final summaryResponse = await dio.get('profile/');
    final merged = <String, dynamic>{
      ...(summaryResponse.data as Map<String, dynamic>),
      ...(response.data as Map<String, dynamic>),
    };

    return UserModel.fromJson(merged);
  }
}
