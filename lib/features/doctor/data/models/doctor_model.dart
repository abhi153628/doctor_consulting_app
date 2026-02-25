import 'package:doctor_booking_app/features/doctor/domain/entities/doctor_entity.dart';
import 'package:doctor_booking_app/features/auth/domain/entities/user_entity.dart';

class DoctorModel extends DoctorEntity {
  const DoctorModel({
    required super.id,
    required super.email,
    required super.name,
    required super.role,
    super.profileImageUrl,
    required super.specialization,
    super.isApproved,
    super.isOnline,
    super.availableTimeSlots,
    super.rating,
    super.totalConsultations,
    super.phoneNumber,
    super.consultationFee,
  });

  factory DoctorModel.fromJson(Map<String, dynamic> json) {
    return DoctorModel(
      id: json['id'] ?? '',
      email: json['email'] ?? '',
      name: json['name'] ?? '',
      role: UserRole.values.firstWhere(
        (e) => e.name == json['role'],
        orElse: () => UserRole.doctor,
      ),
      profileImageUrl: json['profileImageUrl'],
      specialization: json['specialization'] ?? '',
      isApproved: json['isApproved'] ?? false,
      isOnline: json['isOnline'] ?? false,
      availableTimeSlots: List<String>.from(json['availableTimeSlots'] ?? []),
      rating: (json['rating'] ?? 0.0).toDouble(),
      totalConsultations: json['totalConsultations'] ?? 0,
      phoneNumber: json['phoneNumber'],
      consultationFee: (json['consultationFee'] ?? 500.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'role': role.name,
      'profileImageUrl': profileImageUrl,
      'specialization': specialization,
      'isApproved': isApproved,
      'isOnline': isOnline,
      'availableTimeSlots': availableTimeSlots,
      'rating': rating,
      'totalConsultations': totalConsultations,
      'phoneNumber': phoneNumber,
      'consultationFee': consultationFee,
    };
  }
}
