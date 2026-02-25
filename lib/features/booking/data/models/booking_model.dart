import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/booking_entity.dart';

class BookingModel extends BookingEntity {
  const BookingModel({
    required super.id,
    required super.doctorId,
    required super.userId,
    required super.startTime,
    required super.endTime,
    required super.durationMinutes,
    required super.totalAmount,
    required super.commission,
    required super.doctorEarning,
    required super.doctorName,
    required super.patientName,
    super.status,
  });

  factory BookingModel.fromJson(Map<String, dynamic> json) {
    // Handle both Firestore Timestamp and ISO8601 String formats
    DateTime parseTime(dynamic value) {
      if (value == null) return DateTime.now();
      if (value is Timestamp) return value.toDate();
      if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
      return DateTime.now();
    }

    return BookingModel(
      id: json['id'] ?? '',
      doctorId: json['doctorId'] ?? '',
      userId: json['userId'] ?? '',
      startTime: parseTime(json['startTime']),
      endTime: parseTime(json['endTime']),
      durationMinutes: json['durationMinutes'] ?? 0,
      totalAmount: (json['totalAmount'] ?? 0.0).toDouble(),
      commission: (json['commission'] ?? 0.0).toDouble(),
      doctorEarning: (json['doctorEarning'] ?? 0.0).toDouble(),
      doctorName: json['doctorName'] ?? '',
      patientName: json['patientName'] ?? '',
      status: BookingStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => BookingStatus.pending,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'doctorId': doctorId,
      'userId': userId,
      'startTime': Timestamp.fromDate(startTime),
      'endTime': Timestamp.fromDate(endTime),
      'durationMinutes': durationMinutes,
      'totalAmount': totalAmount,
      'commission': commission,
      'doctorEarning': doctorEarning,
      'doctorName': doctorName,
      'patientName': patientName,
      'status': status.name,
    };
  }
}
