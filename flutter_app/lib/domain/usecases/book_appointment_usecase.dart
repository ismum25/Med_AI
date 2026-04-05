import '../entities/appointment.dart';
import '../repositories/appointment_repository.dart';

class BookAppointmentUseCase {
  final AppointmentRepository repository;
  BookAppointmentUseCase(this.repository);

  Future<AppointmentEntity> call({
    required String doctorId,
    required DateTime scheduledAt,
    String? reason,
  }) {
    return repository.bookAppointment(
      doctorId: doctorId,
      scheduledAt: scheduledAt,
      reason: reason,
    );
  }
}
