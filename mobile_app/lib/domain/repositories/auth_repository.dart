import '../entities/user.dart';

abstract class AuthRepository {
  Future<Map<String, String>> login(
    String email,
    String password, {
    required bool rememberMe,
  });
  Future<UserEntity> register({
    required String email,
    required String password,
    required String role,
    required String fullName,
    String? specialization,
    String? licenseNumber,
  });
  Future<UserEntity> getCurrentUser();
  Future<void> logout(String refreshToken);
}
