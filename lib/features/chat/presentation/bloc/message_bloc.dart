import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:doctor_booking_app/features/chat/domain/entities/message_entity.dart';
import 'package:doctor_booking_app/features/chat/domain/repositories/chat_repository.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';

// Events
abstract class MessageEvent extends Equatable {
  const MessageEvent();
  @override
  List<Object?> get props => [];
}

class LoadMessagesEvent extends MessageEvent {
  final String chatId;
  const LoadMessagesEvent(this.chatId);
  @override
  List<Object?> get props => [chatId];
}

class SendMessageEvent extends MessageEvent {
  final MessageEntity message;
  const SendMessageEvent(this.message);
  @override
  List<Object?> get props => [message];
}

class MarkMessagesAsReadEvent extends MessageEvent {
  final String chatId;
  final String userId;
  const MarkMessagesAsReadEvent(this.chatId, this.userId);
  @override
  List<Object?> get props => [chatId, userId];
}

class ClearMessageErrorEvent extends MessageEvent {}

// States
enum MessageStatus { initial, loading, loaded, error }

class MessageState extends Equatable {
  final List<MessageEntity> messages;
  final MessageStatus status;
  final bool isSending;
  final String? errorMessage;
  final bool messageSentSuccessfully;

  const MessageState({
    this.messages = const [],
    this.status = MessageStatus.initial,
    this.isSending = false,
    this.errorMessage,
    this.messageSentSuccessfully = false,
  });

  MessageState copyWith({
    List<MessageEntity>? messages,
    MessageStatus? status,
    bool? isSending,
    String? errorMessage,
    bool? messageSentSuccessfully,
  }) {
    return MessageState(
      messages: messages ?? this.messages,
      status: status ?? this.status,
      isSending: isSending ?? this.isSending,
      errorMessage:
          errorMessage, // We usually want to clear error if not provided
      messageSentSuccessfully: messageSentSuccessfully ?? false,
    );
  }

  @override
  List<Object?> get props => [
    messages,
    status,
    isSending,
    errorMessage,
    messageSentSuccessfully,
  ];
}

// BLoC
class MessageBloc extends Bloc<MessageEvent, MessageState> {
  final ChatRepository repository;

  MessageBloc({required this.repository}) : super(const MessageState()) {
    on<LoadMessagesEvent>(_onLoadMessages, transformer: restartable());
    on<SendMessageEvent>(_onSendMessage, transformer: concurrent());
    on<MarkMessagesAsReadEvent>(
      _onMarkMessagesAsRead,
      transformer: concurrent(),
    );
    on<ClearMessageErrorEvent>(
      (event, emit) => emit(state.copyWith(errorMessage: null)),
    );
  }

  Future<void> _onLoadMessages(
    LoadMessagesEvent event,
    Emitter<MessageState> emit,
  ) async {
    emit(state.copyWith(status: MessageStatus.loading));
    await emit.forEach<List<MessageEntity>>(
      repository.getMessages(event.chatId),
      onData: (messages) =>
          state.copyWith(messages: messages, status: MessageStatus.loaded),
      onError: (error, stackTrace) => state.copyWith(
        status: MessageStatus.error,
        errorMessage: error.toString(),
      ),
    );
  }

  Future<void> _onSendMessage(
    SendMessageEvent event,
    Emitter<MessageState> emit,
  ) async {
    emit(state.copyWith(isSending: true));
    final result = await repository.sendMessage(event.message);
    result.fold(
      (failure) =>
          emit(state.copyWith(isSending: false, errorMessage: failure.message)),
      (_) =>
          emit(state.copyWith(isSending: false, messageSentSuccessfully: true)),
    );
  }

  Future<void> _onMarkMessagesAsRead(
    MarkMessagesAsReadEvent event,
    Emitter<MessageState> emit,
  ) async {
    await repository.markMessagesAsRead(event.chatId, event.userId);
  }
}
