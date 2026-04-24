import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/network/api_error_message.dart';
import '../../../domain/usecases/get_appointments_usecase.dart';
import '../../../domain/usecases/book_appointment_usecase.dart';
import '../../../domain/usecases/get_doctor_slots_usecase.dart';
import 'appointment_event.dart';
import 'appointment_state.dart';

class AppointmentBloc extends Bloc<AppointmentEvent, AppointmentState> {
  final GetAppointmentsUseCase getAppointments;
  final BookAppointmentUseCase bookAppointment;
  final GetDoctorSlotsUseCase getDoctorSlots;

  AppointmentBloc({
    required this.getAppointments,
    required this.bookAppointment,
    required this.getDoctorSlots,
  })
      : super(AppointmentInitial()) {
    on<LoadAppointments>((event, emit) async {
      emit(AppointmentLoading());
      try {
        final list = await getAppointments(status: event.status);
        emit(AppointmentsLoaded(list));
      } catch (e) {
        emit(AppointmentError(userFacingApiMessage(e)));
      }
    });

    on<BookAppointment>((event, emit) async {
      emit(AppointmentLoading());
      try {
        final appt = await bookAppointment(
          doctorId: event.doctorId,
          scheduledAt: event.scheduledAt,
          reason: event.reason,
        );
        emit(AppointmentBooked(appt));
      } catch (e) {
        emit(AppointmentError(userFacingApiMessage(e)));
      }
    });

    on<LoadDoctorSlots>((event, emit) async {
      emit(DoctorSlotsLoading());
      try {
        final slots = await getDoctorSlots(
          doctorUserId: event.doctorUserId,
          date: event.date,
        );
        emit(DoctorSlotsLoaded(slots));
      } catch (e) {
        emit(AppointmentError(userFacingApiMessage(e)));
      }
    });
  }
}
