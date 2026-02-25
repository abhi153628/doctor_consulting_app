import 'package:doctor_booking_app/features/auth/domain/entities/user_entity.dart';
import 'package:equatable/equatable.dart';

class DoctorEntity extends UserEntity {
  final String specialization;
  final bool isApproved;
  final bool isOnline;
  final bool isBlocked;
  final List<String> availableTimeSlots;
  final double rating;
  final int totalConsultations;
  final double consultationFee;

  const DoctorEntity({
    required super.id,
    required super.email,
    required super.name,
    required super.role,
    super.profileImageUrl,
    super.phoneNumber,
    required this.specialization,
    this.isApproved = false,
    this.isOnline = false,
    this.isBlocked = false,
    this.availableTimeSlots = const [],
    this.rating = 0.0,
    this.totalConsultations = 0,
    this.consultationFee = 500.0,
  });

  @override
  List<Object?> get props => [
    ...super.props,
    specialization,
    isApproved,
    isOnline,
    isBlocked,
    availableTimeSlots,
    rating,
    totalConsultations,
    consultationFee,
  ];
}
