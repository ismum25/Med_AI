import '../entities/user.dart';
import '../repositories/auth_repository.dart';

class RegisterUseCase {
  final AuthRepository repository;
  RegisterUseCase(this.repository);

  Future<UserEntity> call({
    required String email,
    required String password,
    required String role,
    required String fullName,
    String? specialization,
    String? licenseNumber,
  }) {
    return repository.register(
      email: email,
      password: password,
      role: role,
      fullName: fullName,
      specialization: specialization,
      licenseNumber: licenseNumber,
    );
  }
}
