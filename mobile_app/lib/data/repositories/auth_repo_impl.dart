import '../../core/storage/session_persistence.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_ds.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;

  AuthRepositoryImpl(this.remoteDataSource);

  @override
  Future<Map<String, String>> login(
    String email,
    String password, {
    required bool rememberMe,
  }) async {
    final tokens = await remoteDataSource.login(email, password);
    await SessionPersistence.saveAfterLogin(
      accessToken: tokens['access_token']!,
      refreshToken: tokens['refresh_token']!,
      role: tokens['role']!,
      userId: tokens['user_id']!,
      rememberMe: rememberMe,
    );
    return tokens;
  }

  @override
  Future<UserEntity> register({
    required String email,
    required String password,
    required String role,
    required String fullName,
    String? specialization,
    String? licenseNumber,
  }) {
    return remoteDataSource.register(
      email: email,
      password: password,
      role: role,
      fullName: fullName,
      specialization: specialization,
      licenseNumber: licenseNumber,
    );
  }

  @override
  Future<UserEntity> getCurrentUser() => remoteDataSource.getCurrentUser();

  @override
  Future<void> logout(String refreshToken) async {
    await remoteDataSource.logout(refreshToken);
    await SessionPersistence.clearAll();
  }
}
