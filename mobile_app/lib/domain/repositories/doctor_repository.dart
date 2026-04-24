import '../entities/doctor.dart';

abstract class DoctorRepository {
  Future<List<String>> getSpecializations();
  Future<List<DoctorListItemEntity>> listDoctors({String? specialization});
  Future<DoctorProfileEntity> getDoctorByProfileId(String profileId);
}
