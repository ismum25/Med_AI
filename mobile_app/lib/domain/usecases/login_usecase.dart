import '../repositories/auth_repository.dart';

class LoginUseCase {
  final AuthRepository repository;
  LoginUseCase(this.repository);

  Future<Map<String, String>> call(
    String email,
    String password, {
    required bool rememberMe,
  }) {
    return repository.login(email, password, rememberMe: rememberMe);
  }
}
