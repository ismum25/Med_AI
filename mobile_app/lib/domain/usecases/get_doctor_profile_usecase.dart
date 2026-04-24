import '../entities/doctor.dart';
import '../repositories/doctor_repository.dart';

class GetDoctorProfileUseCase {
  final DoctorRepository repository;
  GetDoctorProfileUseCase(this.repository);

  Future<DoctorProfileEntity> call(String profileId) =>
      repository.getDoctorByProfileId(profileId);
}
