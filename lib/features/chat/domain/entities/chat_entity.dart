import 'package:equatable/equatable.dart';
import 'package:doctor_booking_app/features/chat/domain/entities/message_entity.dart';

class ChatEntity extends Equatable {
  final String id;
  final List<String> participantIds;
  final MessageEntity? lastMessage;

  const ChatEntity({
    required this.id,
    required this.participantIds,
    this.lastMessage,
  });

  @override
  List<Object?> get props => [id, participantIds, lastMessage];
}
