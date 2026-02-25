import 'package:equatable/equatable.dart';
import 'package:doctor_booking_app/features/chat/domain/entities/message_entity.dart';

class ChatEntity extends Equatable {
  final String id;
  final List<String> participantIds;
  final Map<String, String> participantNames;
  final MessageEntity? lastMessage;

  const ChatEntity({
    required this.id,
    required this.participantIds,
    required this.participantNames,
    this.lastMessage,
  });

  @override
  List<Object?> get props => [
    id,
    participantIds,
    participantNames,
    lastMessage,
  ];
}
