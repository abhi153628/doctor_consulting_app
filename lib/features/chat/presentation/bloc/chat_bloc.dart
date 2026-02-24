import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:doctor_booking_app/features/chat/domain/entities/chat_entity.dart';
import 'package:doctor_booking_app/features/chat/domain/entities/message_entity.dart';
import 'package:doctor_booking_app/features/chat/domain/repositories/chat_repository.dart';

// Events
abstract class ChatEvent extends Equatable {
  const ChatEvent();
  @override
  List<Object?> get props => [];
}

class GetChatsEvent extends ChatEvent {
  final String userId;
  const GetChatsEvent(this.userId);
}

class SendMessageEvent extends ChatEvent {
  final MessageEntity message;
  const SendMessageEvent(this.message);
}

class LoadMessagesEvent extends ChatEvent {
  final String chatId;
  const LoadMessagesEvent(this.chatId);
}

class MarkMessagesAsReadEvent extends ChatEvent {
  final String chatId;
  final String userId;
  const MarkMessagesAsReadEvent(this.chatId, this.userId);
}

// States
abstract class ChatState extends Equatable {
  const ChatState();
  @override
  List<Object?> get props => [];
}

class ChatInitial extends ChatState {}

class ChatLoading extends ChatState {}

class ChatsLoaded extends ChatState {
  final List<ChatEntity> chats;
  const ChatsLoaded(this.chats);
}

class MessagesLoaded extends ChatState {
  final List<MessageEntity> messages;
  const MessagesLoaded(this.messages);
}

class ChatError extends ChatState {
  final String message;
  const ChatError(this.message);
}

// BLoC
class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final ChatRepository repository;

  ChatBloc({required this.repository}) : super(ChatInitial()) {
    on<GetChatsEvent>(_onGetChats);
    on<SendMessageEvent>(_onSendMessage);
    on<LoadMessagesEvent>(_onLoadMessages);
    on<MarkMessagesAsReadEvent>(_onMarkMessagesAsRead);
  }

  Future<void> _onGetChats(GetChatsEvent event, Emitter<ChatState> emit) async {
    emit(ChatLoading());
    final result = await repository.getChats(event.userId);
    result.fold(
      (failure) => emit(ChatError(failure.message)),
      (chats) => emit(ChatsLoaded(chats)),
    );
  }

  Future<void> _onSendMessage(
    SendMessageEvent event,
    Emitter<ChatState> emit,
  ) async {
    await repository.sendMessage(event.message);
  }

  Future<void> _onMarkMessagesAsRead(
    MarkMessagesAsReadEvent event,
    Emitter<ChatState> emit,
  ) async {
    await repository.markMessagesAsRead(event.chatId, event.userId);
  }

  Future<void> _onLoadMessages(
    LoadMessagesEvent event,
    Emitter<ChatState> emit,
  ) async {
    emit(ChatLoading());
    await emit.forEach<List<MessageEntity>>(
      repository.getMessages(event.chatId),
      onData: (messages) => MessagesLoaded(messages),
      onError: (error, stackTrace) => ChatError(error.toString()),
    );
  }
}

// Note: I'll need to handle the stream updates properly in the final implementation.
