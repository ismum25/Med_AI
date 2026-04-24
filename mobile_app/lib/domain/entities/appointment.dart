class AppointmentEntity {
  final String id;
  final String patientId;
  final String doctorId;
  final DateTime scheduledAt;
  final int durationMins;
  final String status;
  final String? reason;
  final String? notes;
  final String? doctorFullName;
  final String? doctorSpecialization;
  final String? doctorProfileId;

  const AppointmentEntity({
    required this.id,
    required this.patientId,
    required this.doctorId,
    required this.scheduledAt,
    required this.durationMins,
    required this.status,
    this.reason,
    this.notes,
    this.doctorFullName,
    this.doctorSpecialization,
    this.doctorProfileId,
  });
}
