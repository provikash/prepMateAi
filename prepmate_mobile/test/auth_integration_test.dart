import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prepmate_mobile/config/app_router.dart';
import 'package:prepmate_mobile/core/services/storage.dart';
import 'package:prepmate_mobile/features/auth/domain/entities/user.dart';
import 'package:prepmate_mobile/features/auth/domain/repositories/auth_repository.dart';
import 'package:prepmate_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:prepmate_mobile/features/auth/presentation/state/auth_state.dart';
import 'package:prepmate_mobile/features/auth/presentation/viewmodel/auth_viewmodel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
  });

  test('route guard preserves protected destination through login', () {
    final unchecked = AuthState();
    expect(authRedirect(unchecked, Uri.parse('/resume/pdf/42')), '/splash');

    final signedOut = AuthState(
      status: AuthStatus.unauthenticated,
      hasCheckedSession: true,
    );
    expect(
      authRedirect(signedOut, Uri.parse('/resume/pdf/42')),
      '/login?from=%2Fresume%2Fpdf%2F42',
    );

    final signedIn = AuthState(
      status: AuthStatus.authenticated,
      hasCheckedSession: true,
    );
    expect(authRedirect(signedIn, Uri.parse('/resume/pdf/42')), isNull);
    expect(
      authRedirect(signedIn, Uri.parse('/login?from=%2Fresume%2Fpdf%2F42')),
      '/resume/pdf/42',
    );
    expect(
      authRedirect(signedIn, Uri.parse('/login?from=https://example.com')),
      '/home',
    );
  });

  test('bootstrap without credentials finishes signed out', () async {
    final repository = _FakeAuthRepository();
    final container = ProviderContainer(
      overrides: [authRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);

    await container.read(authViewModelProvider.notifier).bootstrapSession();

    final state = container.read(authViewModelProvider);
    expect(state.status, AuthStatus.unauthenticated);
    expect(state.hasCheckedSession, isTrue);
    expect(repository.profileCalls, 0);
  });

  test('bootstrap restores a valid secure session', () async {
    FlutterSecureStorage.setMockInitialValues({'access_token': 'token'});
    final repository = _FakeAuthRepository(profile: _user);
    final container = ProviderContainer(
      overrides: [authRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);

    await container.read(authViewModelProvider.notifier).bootstrapSession();

    final state = container.read(authViewModelProvider);
    expect(state.status, AuthStatus.authenticated);
    expect(state.user?.email, _user.email);
    expect(state.hasCheckedSession, isTrue);
  });

  test('logout invokes backend and clears both secure tokens', () async {
    FlutterSecureStorage.setMockInitialValues({
      'access_token': 'access',
      'refresh_token': 'refresh',
    });
    final repository = _FakeAuthRepository(profile: _user);
    final container = ProviderContainer(
      overrides: [authRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);

    await container.read(authViewModelProvider.notifier).logout();

    expect(repository.logoutCalls, 1);
    expect(await TokenService.getAccessToken(), isNull);
    expect(await TokenService.getRefreshToken(), isNull);
    expect(
      container.read(authViewModelProvider).status,
      AuthStatus.unauthenticated,
    );
  });

  test('nested API validation errors become actionable messages', () async {
    final request = RequestOptions(path: 'auth/login/');
    final repository = _FakeAuthRepository(
      loginError: DioException(
        requestOptions: request,
        response: Response(
          requestOptions: request,
          statusCode: 400,
          data: {
            'errors': {
              'email': ['Enter a valid email address.'],
            },
          },
        ),
      ),
    );
    final container = ProviderContainer(
      overrides: [authRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);

    await container
        .read(authViewModelProvider.notifier)
        .login('invalid', 'password');

    final state = container.read(authViewModelProvider);
    expect(state.status, AuthStatus.error);
    expect(state.errorMessage, contains('Enter a valid email address.'));
  });
}

final _user = User(id: '7', email: 'user@example.com', fullName: 'Test User');

class _FakeAuthRepository implements AuthRepository {
  _FakeAuthRepository({this.profile, this.loginError});

  final User? profile;
  final Object? loginError;
  int profileCalls = 0;
  int logoutCalls = 0;

  @override
  Future<User?> login(String email, String password) async {
    if (loginError != null) throw loginError!;
    return profile;
  }

  @override
  Future<User?> getProfile() async {
    profileCalls++;
    return profile;
  }

  @override
  Future<void> logout() async {
    logoutCalls++;
    await TokenService.deleteToken();
  }

  @override
  Future<bool> forgotPassword(String email) async => true;

  @override
  Future<bool> resendVerification(String email) async => true;

  @override
  Future<bool> resetPassword(
    String email,
    String otp,
    String newPassword,
  ) async => true;

  @override
  Future<User?> signInWithGoogle() async => profile;

  @override
  Future<bool> signup(
    String name,
    String email,
    String password,
    String passwordConfirm,
  ) async => true;

  @override
  Future<User?> updateProfile(User user) async => user;

  @override
  Future<User?> uploadProfileImage(String filePath) async => profile;

  @override
  Future<bool> verifyOtp(String email, String otp, String flow) async => true;
}
