import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'core/constants/app_routes.dart';
import 'injection_container.dart' as di;
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await di.init();

  const storage = FlutterSecureStorage();

  // Honor `remember_me=false` — clear stale session before deciding route.
  final remember = await storage.read(key: 'remember_me');
  if (remember == 'false') {
    await storage.delete(key: 'access_token');
    await storage.delete(key: 'refresh_token');
    await storage.delete(key: 'user_role');
    await storage.delete(key: 'user_id');
  }

  final token = await storage.read(key: 'access_token');
  final role = await storage.read(key: 'user_role');
  final welcomeSeen = await storage.read(key: 'welcome_seen');

  String initialRoute;
  if (token != null && role != null) {
    initialRoute =
        role == 'doctor' ? AppRoutes.doctorDashboard : AppRoutes.patientDashboard;
  } else if (welcomeSeen != 'true' && remember == null) {
    // Only show welcome to first-time users who have never logged in.
    // If remember_me is set (even 'false'), the user has logged in before.
    initialRoute = AppRoutes.welcome;
  } else {
    initialRoute = AppRoutes.login;
  }

  runApp(HealthcareApp(initialRoute: initialRoute));
}
