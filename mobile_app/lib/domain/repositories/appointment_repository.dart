import '../entities/appointment.dart';

abstract class AppointmentRepository {
  Future<List<AppointmentEntity>> getAppointments({String? status});
  Future<AppointmentEntity> bookAppointment({
    required String doctorId,
    required DateTime scheduledAt,
    String? reason,
  });
  Future<AppointmentEntity> cancelAppointment(String id, {String? reason});
}
