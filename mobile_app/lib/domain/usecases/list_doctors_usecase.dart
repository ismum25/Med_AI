import '../entities/doctor.dart';
import '../repositories/doctor_repository.dart';

class ListDoctorsUseCase {
  final DoctorRepository repository;
  ListDoctorsUseCase(this.repository);

  Future<List<DoctorListItemEntity>> call({String? specialization}) =>
      repository.listDoctors(specialization: specialization);
}
