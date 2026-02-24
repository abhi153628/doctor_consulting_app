import 'package:doctor_booking_app/features/auth/domain/entities/user_entity.dart';
import 'package:equatable/equatable.dart';

class DoctorEntity extends UserEntity {
  final String specialization;
  final bool isApproved;
  final bool isOnline;
  final List<String> availableTimeSlots;
  final double rating;
  final int totalConsultations;
  final String? phoneNumber;

  const DoctorEntity({
    required super.id,
    required super.email,
    required super.name,
    required super.role,
    super.profileImageUrl,
    required this.specialization,
    this.isApproved = false,
    this.isOnline = false,
    this.availableTimeSlots = const [],
    this.rating = 0.0,
    this.totalConsultations = 0,
    this.phoneNumber,
  });

  @override
  List<Object?> get props => [
    ...super.props,
    specialization,
    isApproved,
    isOnline,
    availableTimeSlots,
    rating,
    totalConsultations,
    phoneNumber,
  ];
}
