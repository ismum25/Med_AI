import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_ds.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;
  final _storage = const FlutterSecureStorage();

  AuthRepositoryImpl(this.remoteDataSource);

  @override
  Future<Map<String, String>> login(
    String email,
    String password, {
    required bool rememberMe,
  }) async {
    final tokens = await remoteDataSource.login(email, password);
    await _storage.write(key: 'access_token', value: tokens['access_token']);
    await _storage.write(key: 'refresh_token', value: tokens['refresh_token']);
    await _storage.write(key: 'user_role', value: tokens['role']);
    await _storage.write(key: 'user_id', value: tokens['user_id']);
    await _storage.write(
      key: 'remember_me',
      value: rememberMe ? 'true' : 'false',
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
    await _storage.deleteAll();
  }
}
