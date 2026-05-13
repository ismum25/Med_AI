class DoctorListItemEntity {
  final String profileId;
  final String userId;
  final String fullName;
  final String specialization;
  final String? hospital;
  final double? consultationFee;
  final double rating;
  final int? yearsExperience;
  final String? sourceProfileUrl;
  final String? profileImageUrl;

  const DoctorListItemEntity({
    required this.profileId,
    required this.userId,
    required this.fullName,
    required this.specialization,
    this.hospital,
    this.consultationFee,
    required this.rating,
    this.yearsExperience,
    this.sourceProfileUrl,
    this.profileImageUrl,
  });
}

class DoctorProfileEntity {
  final String id;
  final String userId;
  final String fullName;
  final String specialization;
  final String licenseNumber;
  final String? hospital;
  final String? bio;
  final double? consultationFee;
  final Map<String, dynamic>? availableSlots;
  final String? availabilityTimezone;
  final double rating;
  final int? yearsExperience;
  final String? sourceProfileUrl;
  final String? profileImageUrl;

  const DoctorProfileEntity({
    required this.id,
    required this.userId,
    required this.fullName,
    required this.specialization,
    required this.licenseNumber,
    this.hospital,
    this.bio,
    this.consultationFee,
    this.availableSlots,
    this.availabilityTimezone,
    required this.rating,
    this.yearsExperience,
    this.sourceProfileUrl,
    this.profileImageUrl,
  });
}
