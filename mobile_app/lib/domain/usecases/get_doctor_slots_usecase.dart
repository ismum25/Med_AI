import '../entities/appointment_slot.dart';
import '../repositories/appointment_repository.dart';

class GetDoctorSlotsUseCase {
  final AppointmentRepository repository;
  GetDoctorSlotsUseCase(this.repository);

  Future<DoctorSlotsEntity> call({
    required String doctorUserId,
    required DateTime date,
  }) {
    return repository.getDoctorSlots(
      doctorUserId: doctorUserId,
      date: date,
    );
  }
}
