import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../domain/repositories/chat_repository.dart';
import '../../domain/entities/chat_entity.dart';
import '../../domain/entities/message_entity.dart';

class GetChatsUseCase {
  final ChatRepository repository;
  GetChatsUseCase(this.repository);

  Future<Either<Failure, List<ChatEntity>>> call(String userId) {
    return repository.getChats(userId);
  }
}

class SendMessageUseCase {
  final ChatRepository repository;
  SendMessageUseCase(this.repository);

  Future<Either<Failure, void>> call(MessageEntity message) {
    return repository.sendMessage(message);
  }
}
