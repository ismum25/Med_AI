import '../repositories/doctor_repository.dart';

class GetDoctorSpecializationsUseCase {
  final DoctorRepository repository;
  GetDoctorSpecializationsUseCase(this.repository);

  Future<List<String>> call() => repository.getSpecializations();
}
