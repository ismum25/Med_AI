import '../entities/appointment.dart';
import '../entities/appointment_slot.dart';

abstract class AppointmentRepository {
  Future<List<AppointmentEntity>> getAppointments({String? status});
  Future<AppointmentEntity> bookAppointment({
    required String doctorId,
    required DateTime scheduledAt,
    String? reason,
  });
  Future<DoctorSlotsEntity> getDoctorSlots({
    required String doctorUserId,
    required DateTime date,
  });
  Future<AppointmentEntity> cancelAppointment(String id, {String? reason});
}
