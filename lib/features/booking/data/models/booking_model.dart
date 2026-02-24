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
    super.status,
  });

  factory BookingModel.fromJson(Map<String, dynamic> json) {
    return BookingModel(
      id: json['id'] ?? '',
      doctorId: json['doctorId'] ?? '',
      userId: json['userId'] ?? '',
      startTime: json['startTime'] != null
          ? DateTime.parse(json['startTime'])
          : DateTime.now(),
      endTime: json['endTime'] != null
          ? DateTime.parse(json['endTime'])
          : DateTime.now(),
      durationMinutes: json['durationMinutes'] ?? 0,
      totalAmount: (json['totalAmount'] ?? 0.0).toDouble(),
      commission: (json['commission'] ?? 0.0).toDouble(),
      doctorEarning: (json['doctorEarning'] ?? 0.0).toDouble(),
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
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'durationMinutes': durationMinutes,
      'totalAmount': totalAmount,
      'commission': commission,
      'doctorEarning': doctorEarning,
      'status': status.name,
    };
  }
}
