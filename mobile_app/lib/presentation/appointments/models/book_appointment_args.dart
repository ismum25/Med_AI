class BookAppointmentArgs {
  final String doctorUserId;
  final String doctorProfileId;
  final String doctorName;
  final String specialization;

  const BookAppointmentArgs({
    required this.doctorUserId,
    required this.doctorProfileId,
    required this.doctorName,
    required this.specialization,
  });
}
