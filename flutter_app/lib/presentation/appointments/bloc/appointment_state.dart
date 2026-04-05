import 'package:equatable/equatable.dart';
import '../../../domain/entities/appointment.dart';

abstract class AppointmentState extends Equatable {
  @override
  List<Object?> get props => [];
}

class AppointmentInitial extends AppointmentState {}
class AppointmentLoading extends AppointmentState {}

class AppointmentsLoaded extends AppointmentState {
  final List<AppointmentEntity> appointments;
  AppointmentsLoaded(this.appointments);
  @override
  List<Object?> get props => [appointments];
}

class AppointmentBooked extends AppointmentState {
  final AppointmentEntity appointment;
  AppointmentBooked(this.appointment);
}

class AppointmentError extends AppointmentState {
  final String message;
  AppointmentError(this.message);
  @override
  List<Object?> get props => [message];
}
