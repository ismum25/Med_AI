import '../../domain/entities/appointment_slot.dart';

class AppointmentSlotModel extends AppointmentSlotEntity {
  const AppointmentSlotModel({
    required super.labelLocal,
    required super.startAtUtc,
  });

  factory AppointmentSlotModel.fromJson(Map<String, dynamic> json) {
    return AppointmentSlotModel(
      labelLocal: json['label_local'] as String,
      startAtUtc: DateTime.parse(json['start_at_utc'] as String),
    );
  }
}

class DoctorSlotsModel extends DoctorSlotsEntity {
  const DoctorSlotsModel({
    required super.doctorId,
    required super.date,
    required super.timezone,
    required super.slotDurationMins,
    required super.slots,
  });

  factory DoctorSlotsModel.fromJson(Map<String, dynamic> json) {
    return DoctorSlotsModel(
      doctorId: json['doctor_id'].toString(),
      date: DateTime.parse(json['date'] as String),
      timezone: json['timezone'] as String?,
      slotDurationMins: json['slot_duration_mins'] as int? ?? 30,
      slots: (json['slots'] as List)
          .map((e) => AppointmentSlotModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
