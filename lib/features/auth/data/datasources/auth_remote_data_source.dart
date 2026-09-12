import 'package:dio/dio.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../domain/entities/user.dart';
import '../models/user_model.dart';
import '../../../../core/services/storage.dart';

/// Exception thrown when user cancels Google Sign-In
class _GoogleSignInCancelledException implements Exception {
  @override
  String toString() => 'User cancelled Google Sign-In';
}

class AuthRemoteDataSource {
  final Dio dio;

  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  bool _googleInitialized = false;

  AuthRemoteDataSource(this.dio);

  // ─── Email/Password Auth ──────────────────────────────────────────────────

  Future<User?> login(String email, String password) async {
    final response = await dio.post(
      'auth/login/',
      data: {'email': email, 'password': password},
    );

    final tokens = response.data['tokens'] as Map<String, dynamic>?;
    final accessToken = tokens?['access']?.toString();
    final refreshToken = tokens?['refresh']?.toString();
    final userData = response.data['user'];

    if (accessToken != null && accessToken.isNotEmpty) {
      await TokenService.saveTokens(
        accessToken: accessToken,
        refreshToken: refreshToken,
      );
      return UserModel.fromJson(userData as Map<String, dynamic>);
    }

    return null;
  }

  Future<bool> signup(
    String name,
    String email,
    String password,
    String passwordConfirm,
  ) async {
    final response = await dio.post(
      'auth/register/',
      data: {
        'name': name,
        'email': email,
        'password': password,
        'password_confirm': passwordConfirm,
      },
    );

    return response.statusCode == 200 || response.statusCode == 201;
  }

  // ─── Google Auth ──────────────────────────────────────────────────────────

  Future<User?> signInWithGoogle() async {
    if (!_googleInitialized) {
      await _googleSignIn.initialize(
        // Web OAuth 2.0 Client ID from Google Cloud Console.
        // Required on Android so the plugin can mint a backend-verifiable idToken.
        serverClientId:
            '704944814931-bm2kaeef6tbf0p8s6aleriqsmo0o0ci6.apps.googleusercontent.com',
      );
      _googleInitialized = true;
    }

    try {
      final GoogleSignInAccount? account = await _googleSignIn.authenticate();
      
      // User cancelled the sign-in dialog
      if (account == null) {
        throw _GoogleSignInCancelledException();
      }
      
      final GoogleSignInAuthentication auth = await account.authentication;
      final String? idToken = auth.idToken;

      if (idToken == null || idToken.isEmpty) {
        throw Exception('Google sign-in failed: idToken is missing.');
      }

      final response = await dio.post(
        'auth/google/',
        data: {'id_token': idToken},
      );

      final data = response.data as Map<String, dynamic>;
      final tokens = data['tokens'] as Map<String, dynamic>?;
      final accessToken = tokens?['access']?.toString();
      final refreshToken = tokens?['refresh']?.toString();
      final userData = data['user'] as Map<String, dynamic>?;

      if (accessToken == null || accessToken.isEmpty || userData == null) {
        throw Exception('Google sign-in failed: backend response was invalid.');
      }

      await TokenService.saveTokens(
        accessToken: accessToken,
        refreshToken: refreshToken,
      );

      return UserModel.fromJson(userData);
    } on _GoogleSignInCancelledException {
      rethrow;
    } catch (error) {
      final message = error.toString().toLowerCase();
      if (message.contains('cancel') || message.contains('dismiss')) {
        throw _GoogleSignInCancelledException();
      }
      throw Exception('Google sign-in failed: $error');
    }
  }
 

     

  // ─── OTP ─────────────────────────────────────────────────────────────────

  Future<bool> verifyOtp(String email, String otp, String flow) async {
    final endpoint = flow == 'login'
        ? 'auth/verify-login-otp/'
        : 'users/verify-otp/';

    final response = await dio.post(
      endpoint,
      data: {'email': email, 'otp': otp},
    );

    return response.statusCode == 200;
  }

  // ─── Password ─────────────────────────────────────────────────────────────

  Future<bool> forgotPassword(String email) async {
    final response = await dio.post(
      'auth/forgot-password/',
      data: {'email': email},
    );

    return response.statusCode == 200;
  }

  // ─── Session ──────────────────────────────────────────────────────────────

  Future<void> logout() async {
    try {
      // Sign out of Google silently — ignore errors if not signed in via Google.
      await _googleSignIn.signOut();
    } catch (_) {}
    await TokenService.deleteToken();
  }

  // ─── Profile ──────────────────────────────────────────────────────────────

  Future<User?> getProfile() async {
    final profileResponse = await dio.get('profile/');
    return UserModel.fromJson(profileResponse.data as Map<String, dynamic>);
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

    final summaryResponse = await dio.get('profile/');
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
