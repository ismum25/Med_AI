class ApiEndpoints {
  // 10.0.2.2 = host machine from Android emulator; use actual LAN IP for physical device
  static const String baseUrl = 'http://10.0.2.2:8000/api/v1';

  static const String register = '/auth/register';
  static const String login = '/auth/login';
  static const String refresh = '/auth/refresh';
  static const String logout = '/auth/logout';
  static const String me = '/auth/me';

  static const String doctors = '/users/doctors';
  static const String myProfile = '/users/me/profile';
  static const String myPatients = '/users/my/patients';
  static const String doctorProfileUpdate = '/users/me/doctor-profile';

  static const String appointments = '/appointments';
  static String appointmentById(String id) => '/appointments/$id';

  static const String reports = '/reports';
  static const String reportsPendingReview = '/reports/queue/pending-review';
  static String reportById(String id) => '/reports/$id';
  static String reportDownload(String id) => '/reports/$id/download';
  static String verifyReport(String id) => '/reports/$id/verify';
  static String patientReports(String patientId) => '/reports/patient/$patientId';

  static String ocrStatus(String id) => '/ocr/jobs/$id';

  static const String chatSessions = '/chat/sessions';
  static String chatSession(String id) => '/chat/sessions/$id';
  static String chatMessages(String id) => '/chat/sessions/$id/messages';
}
