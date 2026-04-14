import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_data_source.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remote;

  AuthRepositoryImpl(this.remote);

  @override
  Future<User?> login(String email, String password) {
    return remote.login(email, password);
  }

  @override
  Future<bool> signup(String name, String email, String password) {
    return remote.signup(name, email, password);
  }

  @override
  Future<bool> verifyOtp(String email, String otp, String flow) {
    return remote.verifyOtp(email, otp, flow);
  }

  @override
  Future<void> logout() {
    return remote.logout();
  }

  @override
  Future<bool> forgotPassword(String email) {
    return remote.forgotPassword(email);
  }

  @override
  Future<User?> getProfile() {
    return remote.
  }
}
