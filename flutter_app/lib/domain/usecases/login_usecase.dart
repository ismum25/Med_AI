import '../repositories/auth_repository.dart';

class LoginUseCase {
  final AuthRepository repository;
  LoginUseCase(this.repository);

  Future<Map<String, String>> call(String email, String password) {
    return repository.login(email, password);
  }
}
