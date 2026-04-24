import '../../core/constants/api_endpoints.dart';
import '../../core/network/dio_client.dart';
import '../models/doctor_model.dart';

abstract class DoctorRemoteDataSource {
  Future<List<String>> getSpecializations();
  Future<List<DoctorListItemModel>> listDoctors({String? specialization});
  Future<DoctorProfileModel> getDoctorByProfileId(String profileId);
}

class DoctorRemoteDataSourceImpl implements DoctorRemoteDataSource {
  final DioClient client;
  DoctorRemoteDataSourceImpl(this.client);

  @override
  Future<List<String>> getSpecializations() async {
    final response = await client.dio.get(ApiEndpoints.doctorSpecializations);
    return (response.data as List).map((e) => e.toString()).toList();
  }

  @override
  Future<List<DoctorListItemModel>> listDoctors({String? specialization}) async {
    final response = await client.dio.get(
      ApiEndpoints.doctors,
      queryParameters:
          specialization != null && specialization.isNotEmpty
              ? {'specialization': specialization}
              : null,
    );
    return (response.data as List)
        .map((j) => DoctorListItemModel.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<DoctorProfileModel> getDoctorByProfileId(String profileId) async {
    final response = await client.dio.get(ApiEndpoints.doctorById(profileId));
    return DoctorProfileModel.fromJson(response.data as Map<String, dynamic>);
  }
}
