import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'core/constants/app_routes.dart';
import 'injection_container.dart' as di;
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await di.init();

  const storage = FlutterSecureStorage();
  final token = await storage.read(key: 'access_token');
  final role = await storage.read(key: 'user_role');

  String initialRoute = AppRoutes.login;
  if (token != null && role != null) {
    initialRoute = role == 'doctor' ? AppRoutes.doctorDashboard : AppRoutes.patientDashboard;
  }

  runApp(HealthcareApp(initialRoute: initialRoute));
}
