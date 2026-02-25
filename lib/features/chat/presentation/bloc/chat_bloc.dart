import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:doctor_booking_app/features/chat/domain/entities/chat_entity.dart';
import 'package:doctor_booking_app/features/chat/domain/repositories/chat_repository.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';

// Events
abstract class ChatEvent extends Equatable {
  const ChatEvent();
  @override
  List<Object?> get props => [];
}

class GetChatsEvent extends ChatEvent {
  final String userId;
  const GetChatsEvent(this.userId);
  @override
  List<Object?> get props => [userId];
}

// States
enum ChatStatus { initial, loading, loaded, error }

class ChatState extends Equatable {
  final List<ChatEntity> chats;
  final ChatStatus status;
  final String? errorMessage;

  const ChatState({
    this.chats = const [],
    this.status = ChatStatus.initial,
    this.errorMessage,
  });

  ChatState copyWith({
    List<ChatEntity>? chats,
    ChatStatus? status,
    String? errorMessage,
  }) {
    return ChatState(
      chats: chats ?? this.chats,
      status: status ?? this.status,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [chats, status, errorMessage];
}

// BLoC
class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final ChatRepository repository;

  ChatBloc({required this.repository}) : super(const ChatState()) {
    on<GetChatsEvent>(_onGetChats, transformer: restartable());
  }

  Future<void> _onGetChats(GetChatsEvent event, Emitter<ChatState> emit) async {
    emit(state.copyWith(status: ChatStatus.loading));
    await emit.forEach<List<ChatEntity>>(
      repository.getChats(event.userId),
      onData: (chats) =>
          state.copyWith(chats: chats, status: ChatStatus.loaded),
      onError: (error, stackTrace) => state.copyWith(
        status: ChatStatus.error,
        errorMessage: error.toString(),
      ),
    );
  }
}
