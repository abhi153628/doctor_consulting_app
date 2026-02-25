import 'package:dartz/dartz.dart';
import 'package:doctor_booking_app/core/error/failures.dart';
import 'package:doctor_booking_app/features/chat/domain/entities/chat_entity.dart';
import 'package:doctor_booking_app/features/chat/domain/entities/message_entity.dart';

abstract class ChatRepository {
  Stream<List<ChatEntity>> getChats(String userId);
  Stream<List<MessageEntity>> getMessages(String chatId);
  Future<Either<Failure, void>> sendMessage(MessageEntity message);
  Future<Either<Failure, void>> markMessagesAsRead(
    String chatId,
    String userId,
  );
}
