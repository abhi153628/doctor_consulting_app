import 'package:equatable/equatable.dart';

class CallEntity extends Equatable {
  final String? id;
  final String channelName;
  final String? token;
  final String callerId;
  final String callerName;
  final String receiverId;
  final String receiverName;
  final String status; // dialing, accepted, rejected, ended
  final DateTime timestamp;

  const CallEntity({
    this.id,
    required this.channelName,
    this.token,
    required this.callerId,
    required this.callerName,
    required this.receiverId,
    required this.receiverName,
    required this.status,
    required this.timestamp,
  });

  @override
  List<Object?> get props => [
    id,
    channelName,
    token,
    callerId,
    callerName,
    receiverId,
    receiverName,
    status,
    timestamp,
  ];
}
