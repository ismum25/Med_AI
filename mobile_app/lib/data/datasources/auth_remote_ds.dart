import '../../core/constants/api_endpoints.dart';
import '../../core/network/dio_client.dart';
import '../models/user_model.dart';

abstract class AuthRemoteDataSource {
  Future<Map<String, String>> login(String email, String password);
  Future<UserModel> register({
    required String email,
    required String password,
    required String role,
    required String fullName,
    String? specialization,
    String? licenseNumber,
  });
  Future<UserModel> getCurrentUser();
  Future<void> logout(String refreshToken);
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final DioClient client;
  AuthRemoteDataSourceImpl(this.client);

  @override
  Future<Map<String, String>> login(String email, String password) async {
    final response = await client.dio.post(
      ApiEndpoints.login,
      data: {'email': email, 'password': password},
    );
    return {
      'access_token': response.data['access_token'],
      'refresh_token': response.data['refresh_token'],
      'role': response.data['role'],
      'user_id': response.data['user_id'],
    };
  }

  @override
  Future<UserModel> register({
    required String email,
    required String password,
    required String role,
    required String fullName,
    String? specialization,
    String? licenseNumber,
  }) async {
    final response = await client.dio.post(
      ApiEndpoints.register,
      data: {
        'email': email,
        'password': password,
        'role': role,
        'full_name': fullName,
        if (specialization != null) 'specialization': specialization,
        if (licenseNumber != null) 'license_number': licenseNumber,
      },
    );
    return UserModel.fromJson(response.data);
  }

  @override
  Future<UserModel> getCurrentUser() async {
    final response = await client.dio.get(ApiEndpoints.me);
    return UserModel.fromJson(response.data);
  }

  @override
  Future<void> logout(String refreshToken) async {
    await client.dio.post(ApiEndpoints.logout, data: {'refresh_token': refreshToken});
  }
}
