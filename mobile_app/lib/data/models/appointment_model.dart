import '../../domain/entities/appointment.dart';

class AppointmentModel extends AppointmentEntity {
  const AppointmentModel({
    required super.id,
    required super.patientId,
    required super.doctorId,
    required super.scheduledAt,
    required super.durationMins,
    required super.status,
    super.reason,
    super.notes,
    super.doctorFullName,
    super.doctorSpecialization,
    super.doctorProfileId,
  });

  factory AppointmentModel.fromJson(Map<String, dynamic> json) {
    return AppointmentModel(
      id: json['id'].toString(),
      patientId: json['patient_id'].toString(),
      doctorId: json['doctor_id'].toString(),
      scheduledAt: DateTime.parse(json['scheduled_at'] as String),
      durationMins: json['duration_mins'] as int? ?? 30,
      status: json['status'] as String,
      reason: json['reason'] as String?,
      notes: json['notes'] as String?,
      doctorFullName: json['doctor_full_name'] as String?,
      doctorSpecialization: json['doctor_specialization'] as String?,
      doctorProfileId: json['doctor_profile_id']?.toString(),
    );
  }
}
