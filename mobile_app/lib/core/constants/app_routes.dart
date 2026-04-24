class AppRoutes {
  static const String welcome = '/welcome';
  static const String login = '/login';
  static const String register = '/register';
  static const String patientDashboard = '/patient/dashboard';
  static const String doctorDashboard = '/doctor/dashboard';
  static const String appointments = '/appointments';
  static const String bookAppointment = '/appointments/book';
  static String patientDoctorProfile(String doctorProfileId) =>
      '/appointments/doctor/$doctorProfileId';
  static const String reports = '/reports';
  static const String uploadReport = '/reports/upload';
  static const String chat = '/chat';
  static const String patients = '/doctor/patients';
  static const String doctorAppointments = '/doctor/appointments';
  static const String doctorReview = '/doctor/review';
  static String doctorReviewDetail(String reportId) => '$doctorReview/$reportId';
  static const String doctorChat = '/doctor/chat';
  static const String patientProfile = '/patient/profile';
  static const String doctorProfile = '/doctor/profile';
}
