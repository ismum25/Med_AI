import '../../domain/entities/doctor.dart';

class DoctorListItemModel extends DoctorListItemEntity {
  const DoctorListItemModel({
    required super.profileId,
    required super.userId,
    required super.fullName,
    required super.specialization,
    super.hospital,
    super.consultationFee,
    required super.rating,
    super.yearsExperience,
  });

  factory DoctorListItemModel.fromJson(Map<String, dynamic> json) {
    return DoctorListItemModel(
      profileId: json['id'].toString(),
      userId: json['user_id'].toString(),
      fullName: json['full_name'] as String,
      specialization: json['specialization'] as String? ?? '',
      hospital: json['hospital'] as String?,
      consultationFee: (json['consultation_fee'] as num?)?.toDouble(),
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      yearsExperience: json['years_experience'] as int?,
    );
  }
}

class DoctorProfileModel extends DoctorProfileEntity {
  const DoctorProfileModel({
    required super.id,
    required super.userId,
    required super.fullName,
    required super.specialization,
    required super.licenseNumber,
    super.hospital,
    super.bio,
    super.consultationFee,
    super.availableSlots,
    super.availabilityTimezone,
    required super.rating,
    super.yearsExperience,
  });

  factory DoctorProfileModel.fromJson(Map<String, dynamic> json) {
    return DoctorProfileModel(
      id: json['id'].toString(),
      userId: json['user_id'].toString(),
      fullName: json['full_name'] as String,
      specialization: json['specialization'] as String? ?? '',
      licenseNumber: json['license_number'] as String,
      hospital: json['hospital'] as String?,
      bio: json['bio'] as String?,
      consultationFee: (json['consultation_fee'] as num?)?.toDouble(),
      availableSlots: json['available_slots'] as Map<String, dynamic>?,
      availabilityTimezone: json['availability_timezone'] as String?,
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      yearsExperience: json['years_experience'] as int?,
    );
  }
}
