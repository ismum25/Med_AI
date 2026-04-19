import '../entities/appointment.dart';
import '../repositories/appointment_repository.dart';

class GetAppointmentsUseCase {
  final AppointmentRepository repository;
  GetAppointmentsUseCase(this.repository);

  Future<List<AppointmentEntity>> call({String? status}) {
    return repository.getAppointments(status: status);
  }
}
