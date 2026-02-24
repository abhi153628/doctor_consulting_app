import 'package:doctor_booking_app/features/chat/domain/entities/chat_entity.dart';
import 'package:doctor_booking_app/features/chat/data/models/message_model.dart';

class ChatModel extends ChatEntity {
  const ChatModel({
    required super.id,
    required super.participantIds,
    super.lastMessage,
  });

  factory ChatModel.fromJson(Map<String, dynamic> json) {
    return ChatModel(
      id: json['id'],
      participantIds: List<String>.from(json['participantIds']),
      lastMessage: json['lastMessage'] != null
          ? MessageModel.fromJson(json['lastMessage'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'participantIds': participantIds,
      'lastMessage': lastMessage != null
          ? (lastMessage as MessageModel).toJson()
          : null,
    };
  }
}
