import 'package:dartz/dartz.dart';
import 'package:doctor_booking_app/core/error/failures.dart';
import 'package:doctor_booking_app/features/chat/domain/entities/chat_entity.dart';
import 'package:doctor_booking_app/features/chat/domain/entities/message_entity.dart';
import 'package:doctor_booking_app/features/chat/domain/repositories/chat_repository.dart';
import 'package:doctor_booking_app/features/chat/data/datasources/chat_remote_data_source.dart';
import 'package:doctor_booking_app/features/chat/data/models/message_model.dart';

class ChatRepositoryImpl implements ChatRepository {
  final ChatRemoteDataSource remoteDataSource;

  ChatRepositoryImpl({required this.remoteDataSource});

  @override
  Stream<List<ChatEntity>> getChats(String userId) {
    return remoteDataSource
        .getChats(userId)
        .map((list) => list.cast<ChatEntity>().toList());
  }

  @override
  Stream<List<MessageEntity>> getMessages(String chatId) {
    return remoteDataSource
        .getMessages(chatId)
        .map((list) => list.cast<MessageEntity>().toList());
  }

  @override
  Future<Either<Failure, void>> sendMessage(MessageEntity message) async {
    try {
      await remoteDataSource.sendMessage(
        MessageModel(
          id: message.id,
          senderId: message.senderId,
          senderName: message.senderName,
          receiverId: message.receiverId,
          receiverName: message.receiverName,
          content: message.content,
          timestamp: message.timestamp,
          isRead: message.isRead,
        ),
      );
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> markMessagesAsRead(
    String chatId,
    String userId,
  ) async {
    try {
      await remoteDataSource.markAllMessagesAsRead(chatId, userId);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
