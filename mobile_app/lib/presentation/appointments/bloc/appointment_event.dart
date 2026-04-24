import 'package:equatable/equatable.dart';

abstract class AppointmentEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoadAppointments extends AppointmentEvent {
  final String? status;
  LoadAppointments({this.status});
}

class BookAppointment extends AppointmentEvent {
  final String doctorId;
  final DateTime scheduledAt;
  final String? reason;
  BookAppointment({required this.doctorId, required this.scheduledAt, this.reason});
}

class LoadDoctorSlots extends AppointmentEvent {
  final String doctorUserId;
  final DateTime date;

  LoadDoctorSlots({required this.doctorUserId, required this.date});
}
