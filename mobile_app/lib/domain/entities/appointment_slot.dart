class AppointmentSlotEntity {
  final String labelLocal;
  final DateTime startAtUtc;

  const AppointmentSlotEntity({
    required this.labelLocal,
    required this.startAtUtc,
  });
}

class DoctorSlotsEntity {
  final String doctorId;
  final DateTime date;
  final String? timezone;
  final int slotDurationMins;
  final List<AppointmentSlotEntity> slots;

  const DoctorSlotsEntity({
    required this.doctorId,
    required this.date,
    required this.timezone,
    required this.slotDurationMins,
    required this.slots,
  });
}
