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
    final data = response.data as Map<String, dynamic>;
    return {
      'access_token': data['access_token'].toString(),
      'refresh_token': data['refresh_token'].toString(),
      'role': data['role'].toString(),
      'user_id': data['user_id'].toString(),
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
