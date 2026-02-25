import 'package:equatable/equatable.dart';

enum BookingStatus { pending, accepted, rejected, completed, cancelled }

class BookingEntity extends Equatable {
  final String id;
  final String doctorId;
  final String userId;
  final DateTime startTime;
  final DateTime endTime;
  final int durationMinutes;
  final double totalAmount;
  final double commission;
  final double doctorEarning;
  final String doctorName;
  final String patientName;
  final BookingStatus status;

  const BookingEntity({
    required this.id,
    required this.doctorId,
    required this.userId,
    required this.startTime,
    required this.endTime,
    required this.durationMinutes,
    required this.totalAmount,
    required this.commission,
    required this.doctorEarning,
    required this.doctorName,
    required this.patientName,
    this.status = BookingStatus.pending,
  });

  @override
  List<Object?> get props => [
    id,
    doctorId,
    userId,
    startTime,
    endTime,
    durationMinutes,
    totalAmount,
    commission,
    doctorEarning,
    doctorName,
    patientName,
    status,
  ];
}
