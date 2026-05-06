import 'package:dio/dio.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../domain/entities/user.dart';
import '../models/user_model.dart';
import '../../../../core/services/storage.dart';

class AuthRemoteDataSource {
  final Dio dio;

  // google_sign_in v7 uses a singleton instance.
  // Initialize is called lazily in signInWithGoogle().
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

  /// Signs the user in with Google and exchanges the ID token for our backend
  /// JWT tokens.  Works with google_sign_in v7.x.
  Future<User?> signInWithGoogle() async {
    // Initialise the singleton once. This configures the OAuth client.
    if (!_googleInitialized) {
      await _googleSignIn.initialize();
      _googleInitialized = true;
    }

    // Trigger the native Google sign-in UI.
    final GoogleSignInAccount account = await _googleSignIn.authenticate();
    final GoogleSignInAuthentication auth = account.authentication;
    final String? idToken = auth.idToken;

    if (idToken == null || idToken.isEmpty) {
      throw Exception('Google sign-in failed: id_token is missing.');
    }

    // Send the ID token to our backend for verification and JWT issuance.
    final response = await dio.post(
      'auth/google/',
      data: {
        'id_token': idToken,
        'token': idToken, // belt-and-suspenders: accept both field names
      },
    );

    final data = response.data as Map<String, dynamic>;
    final tokensMap = data['tokens'] as Map<String, dynamic>?;
    final accessToken =
        tokensMap?['access']?.toString() ??
        data['access']?.toString() ??
        data['access_token']?.toString();
    final refreshToken =
        tokensMap?['refresh']?.toString() ??
        data['refresh']?.toString() ??
        data['refresh_token']?.toString();

    if (accessToken != null && accessToken.isNotEmpty) {
      await TokenService.saveTokens(
        accessToken: accessToken,
        refreshToken: refreshToken,
      );
    }

    final userData = (data['user'] ?? data) as Map<String, dynamic>;
    return UserModel.fromJson(userData);
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
