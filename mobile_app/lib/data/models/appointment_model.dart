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
  });

  factory AppointmentModel.fromJson(Map<String, dynamic> json) {
    return AppointmentModel(
      id: json['id'],
      patientId: json['patient_id'],
      doctorId: json['doctor_id'],
      scheduledAt: DateTime.parse(json['scheduled_at']),
      durationMins: json['duration_mins'] ?? 30,
      status: json['status'],
      reason: json['reason'],
      notes: json['notes'],
    );
  }
}
