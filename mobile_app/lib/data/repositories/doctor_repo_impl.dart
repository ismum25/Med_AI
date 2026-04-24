import '../../domain/entities/doctor.dart';
import '../../domain/repositories/doctor_repository.dart';
import '../datasources/doctor_remote_ds.dart';

class DoctorRepositoryImpl implements DoctorRepository {
  final DoctorRemoteDataSource remote;
  DoctorRepositoryImpl(this.remote);

  @override
  Future<List<String>> getSpecializations() => remote.getSpecializations();

  @override
  Future<List<DoctorListItemEntity>> listDoctors({String? specialization}) =>
      remote.listDoctors(specialization: specialization);

  @override
  Future<DoctorProfileEntity> getDoctorByProfileId(String profileId) =>
      remote.getDoctorByProfileId(profileId);
}
