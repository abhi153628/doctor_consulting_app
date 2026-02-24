import 'package:doctor_booking_app/features/call/domain/entities/call_entity.dart';

class CallModel extends CallEntity {
  const CallModel({
    super.id,
    required super.channelName,
    super.token,
    required super.callerId,
    required super.callerName,
    required super.receiverId,
    required super.receiverName,
    required super.status,
    required super.timestamp,
  });

  factory CallModel.fromJson(Map<String, dynamic> json, String id) {
    return CallModel(
      id: id,
      channelName: json['channelName'],
      token: json['token'],
      callerId: json['callerId'],
      callerName: json['callerName'],
      receiverId: json['receiverId'],
      receiverName: json['receiverName'],
      status: json['status'],
      timestamp: DateTime.fromMillisecondsSinceEpoch(json['timestamp']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'channelName': channelName,
      'token': token,
      'callerId': callerId,
      'callerName': callerName,
      'receiverId': receiverId,
      'receiverName': receiverName,
      'status': status,
      'timestamp': timestamp.millisecondsSinceEpoch,
    };
  }
}
