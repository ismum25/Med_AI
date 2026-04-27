import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'core/constants/app_routes.dart';
import 'core/storage/session_persistence.dart';
import 'injection_container.dart' as di;
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  await di.init();

  final session = await SessionPersistence.loadForStartup();

  String initialRoute;
  if (session.token != null && session.role != null) {
    initialRoute = session.role == 'doctor'
        ? AppRoutes.doctorDashboard
        : AppRoutes.patientDashboard;
  } else if (session.welcomeSeen != 'true' && session.remember == null) {
    // Only show welcome to first-time users who have never logged in.
    // If remember_me is set (even 'false'), the user has logged in before.
    initialRoute = AppRoutes.welcome;
  } else {
    initialRoute = AppRoutes.login;
  }

  runApp(HealthcareApp(initialRoute: initialRoute));
}
