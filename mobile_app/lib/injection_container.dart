import 'package:get_it/get_it.dart';
import 'core/network/dio_client.dart';
import 'data/datasources/auth_remote_ds.dart';
import 'data/datasources/appointment_remote_ds.dart';
import 'data/datasources/report_remote_ds.dart';
import 'data/repositories/auth_repo_impl.dart';
import 'data/repositories/appointment_repo_impl.dart';
import 'data/repositories/report_repo_impl.dart';
import 'domain/repositories/auth_repository.dart';
import 'domain/repositories/appointment_repository.dart';
import 'domain/repositories/report_repository.dart';
import 'domain/usecases/login_usecase.dart';
import 'domain/usecases/register_usecase.dart';
import 'domain/usecases/get_appointments_usecase.dart';
import 'domain/usecases/book_appointment_usecase.dart';
import 'domain/usecases/upload_report_usecase.dart';
import 'presentation/auth/bloc/auth_bloc.dart';
import 'presentation/appointments/bloc/appointment_bloc.dart';
import 'presentation/reports/bloc/report_bloc.dart';

final sl = GetIt.instance;

Future<void> init() async {
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

  // Use cases
  sl.registerLazySingleton(() => LoginUseCase(sl()));
  sl.registerLazySingleton(() => RegisterUseCase(sl()));
  sl.registerLazySingleton(() => GetAppointmentsUseCase(sl()));
  sl.registerLazySingleton(() => BookAppointmentUseCase(sl()));
  sl.registerLazySingleton(() => UploadReportUseCase(sl()));

  // BLoCs (factories so each widget tree gets a fresh instance)
  sl.registerFactory(() => AuthBloc(loginUseCase: sl(), registerUseCase: sl()));
  sl.registerFactory(
    () => AppointmentBloc(getAppointments: sl(), bookAppointment: sl()),
  );
  sl.registerFactory(() => ReportBloc(uploadReport: sl()));
}
