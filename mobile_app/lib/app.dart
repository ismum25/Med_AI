import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'core/constants/app_routes.dart';
import 'core/theme/app_theme.dart';
import 'presentation/auth/pages/login_page.dart';
import 'presentation/auth/pages/register_page.dart';
import 'presentation/dashboard/pages/patient_dashboard.dart';
import 'presentation/dashboard/pages/doctor_dashboard.dart';
import 'presentation/appointments/pages/appointment_list_page.dart';
import 'presentation/appointments/pages/book_appointment_page.dart';
import 'presentation/reports/pages/report_list_page.dart';
import 'presentation/reports/pages/upload_report_page.dart';
import 'presentation/chatbot/pages/chat_page.dart';
import 'presentation/patient/patient_shell.dart';
import 'presentation/doctor/doctor_shell.dart';
import 'presentation/doctor/pages/doctor_patients_page.dart';
import 'presentation/profile/pages/profile_page.dart';

GoRouter _buildRouter(String initialLocation) => GoRouter(
      initialLocation: initialLocation,
      routes: [
        GoRoute(path: AppRoutes.login, builder: (_, __) => const LoginPage()),
        GoRoute(path: AppRoutes.register, builder: (_, __) => const RegisterPage()),

        // Patient shell — persistent bottom nav + header
        ShellRoute(
          builder: (_, __, child) => PatientShell(child: child),
          routes: [
            GoRoute(
              path: AppRoutes.patientDashboard,
              builder: (_, __) => const PatientDashboard(),
            ),
            GoRoute(
              path: AppRoutes.appointments,
              builder: (_, __) => const AppointmentListPage(),
              routes: [
                GoRoute(
                  path: 'book',
                  builder: (_, __) => const BookAppointmentPage(),
                ),
              ],
            ),
            GoRoute(
              path: AppRoutes.reports,
              builder: (_, __) => const ReportListPage(),
              routes: [
                GoRoute(
                  path: 'upload',
                  builder: (_, __) => const UploadReportPage(),
                ),
              ],
            ),
            GoRoute(
              path: AppRoutes.chat,
              builder: (_, __) => const ChatPage(),
            ),
            GoRoute(
              path: AppRoutes.patientProfile,
              builder: (_, __) => const ProfilePage(role: 'patient'),
            ),
          ],
        ),

        // Doctor shell — persistent bottom nav + header
        ShellRoute(
          builder: (_, __, child) => DoctorShell(child: child),
          routes: [
            GoRoute(
              path: AppRoutes.doctorDashboard,
              builder: (_, __) => const DoctorDashboard(),
            ),
            GoRoute(
              path: AppRoutes.doctorAppointments,
              builder: (_, __) => const AppointmentListPage(),
            ),
            GoRoute(
              path: AppRoutes.patients,
              builder: (_, __) => const DoctorPatientsPage(),
            ),
            GoRoute(
              path: AppRoutes.doctorChat,
              builder: (_, __) => const ChatPage(),
            ),
            GoRoute(
              path: AppRoutes.doctorProfile,
              builder: (_, __) => const ProfilePage(role: 'doctor'),
            ),
          ],
        ),
      ],
    );

class HealthcareApp extends StatelessWidget {
  final String initialRoute;
  const HealthcareApp({super.key, required this.initialRoute});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Healthcare Platform',
      theme: AppTheme.lightTheme,
      routerConfig: _buildRouter(initialRoute),
      debugShowCheckedModeBanner: false,
    );
  }
}
