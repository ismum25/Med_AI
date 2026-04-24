import '../../core/constants/api_endpoints.dart';
import '../../core/network/dio_client.dart';
import '../models/appointment_model.dart';
import '../models/appointment_slot_model.dart';

abstract class AppointmentRemoteDataSource {
  Future<List<AppointmentModel>> getAppointments({String? status});
  Future<AppointmentModel> bookAppointment({
    required String doctorId,
    required DateTime scheduledAt,
    String? reason,
  });
  Future<DoctorSlotsModel> getDoctorSlots({
    required String doctorUserId,
    required DateTime date,
  });
  Future<AppointmentModel> cancelAppointment(String id, {String? reason});
}

class AppointmentRemoteDataSourceImpl implements AppointmentRemoteDataSource {
  final DioClient client;
  AppointmentRemoteDataSourceImpl(this.client);

  @override
  Future<List<AppointmentModel>> getAppointments({String? status}) async {
    final response = await client.dio.get(
      ApiEndpoints.appointments,
      queryParameters: status != null ? {'status': status} : null,
    );
    return (response.data as List).map((j) => AppointmentModel.fromJson(j)).toList();
  }

  @override
  Future<AppointmentModel> bookAppointment({
    required String doctorId,
    required DateTime scheduledAt,
    String? reason,
  }) async {
    final response = await client.dio.post(
      ApiEndpoints.appointments,
      data: {
        'doctor_id': doctorId,
        'scheduled_at': scheduledAt.toUtc().toIso8601String(),
        if (reason != null) 'reason': reason,
      },
    );
    return AppointmentModel.fromJson(response.data);
  }

  @override
  Future<AppointmentModel> cancelAppointment(String id, {String? reason}) async {
    final response = await client.dio.delete(
      ApiEndpoints.appointmentById(id),
      queryParameters: reason != null ? {'reason': reason} : null,
    );
    return AppointmentModel.fromJson(response.data);
  }

  @override
  Future<DoctorSlotsModel> getDoctorSlots({
    required String doctorUserId,
    required DateTime date,
  }) async {
    final response = await client.dio.get(
      ApiEndpoints.doctorSlots(doctorUserId),
      queryParameters: {'date': date.toIso8601String().split('T').first},
    );
    return DoctorSlotsModel.fromJson(response.data as Map<String, dynamic>);
  }
}
