import '../../domain/entities/appointment.dart';
import '../../domain/repositories/appointment_repository.dart';
import '../datasources/appointment_remote_ds.dart';

class AppointmentRepositoryImpl implements AppointmentRepository {
  final AppointmentRemoteDataSource remoteDataSource;
  AppointmentRepositoryImpl(this.remoteDataSource);

  @override
  Future<List<AppointmentEntity>> getAppointments({String? status}) =>
      remoteDataSource.getAppointments(status: status);

  @override
  Future<AppointmentEntity> bookAppointment({
    required String doctorId,
    required DateTime scheduledAt,
    String? reason,
  }) =>
      remoteDataSource.bookAppointment(
        doctorId: doctorId,
        scheduledAt: scheduledAt,
        reason: reason,
      );

  @override
  Future<AppointmentEntity> cancelAppointment(String id, {String? reason}) =>
      remoteDataSource.cancelAppointment(id, reason: reason);
}
