import 'package:get_it/get_it.dart';
import 'core/network/dio_client.dart';
import 'data/datasources/auth_remote_ds.dart';
import 'data/datasources/appointment_remote_ds.dart';
import 'data/datasources/doctor_remote_ds.dart';
import 'data/datasources/report_remote_ds.dart';
import 'data/repositories/auth_repo_impl.dart';
import 'data/repositories/appointment_repo_impl.dart';
import 'data/repositories/doctor_repo_impl.dart';
import 'data/repositories/report_repo_impl.dart';
import 'domain/repositories/auth_repository.dart';
import 'domain/repositories/appointment_repository.dart';
import 'domain/repositories/doctor_repository.dart';
import 'domain/repositories/report_repository.dart';
import 'domain/usecases/login_usecase.dart';
import 'domain/usecases/register_usecase.dart';
import 'domain/usecases/get_appointments_usecase.dart';
import 'domain/usecases/book_appointment_usecase.dart';
import 'domain/usecases/get_doctor_slots_usecase.dart';
import 'domain/usecases/upload_report_usecase.dart';
import 'domain/usecases/update_report_usecase.dart';
import 'domain/usecases/get_doctor_specializations_usecase.dart';
import 'domain/usecases/list_doctors_usecase.dart';
import 'domain/usecases/get_doctor_profile_usecase.dart';
import 'presentation/auth/bloc/auth_bloc.dart';
import 'presentation/appointments/bloc/appointment_bloc.dart';
import 'presentation/appointments/cubit/doctor_discovery_cubit.dart';
import 'presentation/reports/bloc/report_bloc.dart';

final sl = GetIt.instance;

Future<void> init() async {
  if (sl.isRegistered<DioClient>()) {
    await sl.reset();
  }

  // Network
  sl.registerLazySingleton<DioClient>(() => DioClient());

  // Data sources
  sl.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSourceImpl(sl()),
  );
  sl.registerLazySingleton<AppointmentRemoteDataSource>(
    () => AppointmentRemoteDataSourceImpl(sl()),
  );
  sl.registerLazySingleton<ReportRemoteDataSource>(
    () => ReportRemoteDataSourceImpl(sl()),
  );
  sl.registerLazySingleton<DoctorRemoteDataSource>(
    () => DoctorRemoteDataSourceImpl(sl()),
  );

  // Repositories
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(sl()),
  );
  sl.registerLazySingleton<AppointmentRepository>(
    () => AppointmentRepositoryImpl(sl()),
  );
  sl.registerLazySingleton<ReportRepository>(
    () => ReportRepositoryImpl(sl()),
  );
  sl.registerLazySingleton<DoctorRepository>(
    () => DoctorRepositoryImpl(sl()),
  );

  // Use cases
  sl.registerLazySingleton(() => LoginUseCase(sl()));
  sl.registerLazySingleton(() => RegisterUseCase(sl()));
  sl.registerLazySingleton(() => GetAppointmentsUseCase(sl()));
  sl.registerLazySingleton(() => BookAppointmentUseCase(sl()));
  sl.registerLazySingleton(() => GetDoctorSlotsUseCase(sl()));
  sl.registerLazySingleton(() => UploadReportUseCase(sl()));
  sl.registerLazySingleton(() => UpdateReportUseCase(sl()));
  sl.registerLazySingleton(() => GetDoctorSpecializationsUseCase(sl()));
  sl.registerLazySingleton(() => ListDoctorsUseCase(sl()));
  sl.registerLazySingleton(() => GetDoctorProfileUseCase(sl()));

  // BLoCs (factories so each widget tree gets a fresh instance)
  sl.registerFactory(() => AuthBloc(loginUseCase: sl(), registerUseCase: sl()));
  sl.registerFactory(
    () => AppointmentBloc(
      getAppointments: sl(),
      bookAppointment: sl(),
      getDoctorSlots: sl(),
    ),
  );
  sl.registerFactory(
    () => DoctorDiscoveryCubit(
      getSpecializations: sl(),
      listDoctors: sl(),
    ),
  );
  sl.registerFactory(() => ReportBloc(uploadReport: sl()));
}
