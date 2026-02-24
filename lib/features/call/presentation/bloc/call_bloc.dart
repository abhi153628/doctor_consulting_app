import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import '../../domain/entities/call_entity.dart';
import '../../data/datasources/call_remote_data_source.dart';

// Events
abstract class CallEvent extends Equatable {
  const CallEvent();
  @override
  List<Object?> get props => [];
}

class InitiateCallEvent extends CallEvent {
  final String callerId;
  final String callerName;
  final String receiverId;
  final String receiverName;

  const InitiateCallEvent({
    required this.callerId,
    required this.callerName,
    required this.receiverId,
    required this.receiverName,
  });
}

class AcceptCallEvent extends CallEvent {
  final CallEntity call;
  const AcceptCallEvent(this.call);
}

class RejectCallEvent extends CallEvent {
  final String callId;
  const RejectCallEvent(this.callId);
}

class IncomingCallReceivedEvent extends CallEvent {
  final CallEntity call;
  const IncomingCallReceivedEvent(this.call);
}

class CallStatusUpdatedEvent extends CallEvent {
  final CallEntity? call;
  const CallStatusUpdatedEvent(this.call);
}

class JoinCallEvent extends CallEvent {
  final String channelId;
  const JoinCallEvent(this.channelId);
}

class LeaveCallEvent extends CallEvent {}

class RemoteUserJoinedEvent extends CallEvent {
  final int uid;
  const RemoteUserJoinedEvent(this.uid);
}

class RemoteUserOfflineEvent extends CallEvent {
  final int uid;
  const RemoteUserOfflineEvent(this.uid);
}

class ToggleMuteEvent extends CallEvent {
  final bool muted;
  const ToggleMuteEvent(this.muted);
}

class ToggleCameraEvent extends CallEvent {
  final bool disabled;
  const ToggleCameraEvent(this.disabled);
}

class SwitchCameraEvent extends CallEvent {}

class _CallErrorInternalEvent extends CallEvent {
  final String message;
  const _CallErrorInternalEvent(this.message);
}

// States
abstract class CallState extends Equatable {
  const CallState();
  @override
  List<Object?> get props => [];
}

class CallInitial extends CallState {}

class CallRinging extends CallState {
  final CallEntity call;
  const CallRinging(this.call);
  @override
  List<Object?> get props => [call];
}

class CallDialing extends CallState {
  final CallEntity call;
  const CallDialing(this.call);
  @override
  List<Object?> get props => [call];
}

class CallInChannel extends CallState {
  final String channelId;
  final List<int> remoteUids;
  final bool isMuted;
  final bool isCameraDisabled;
  final CallEntity? callMetadata;

  const CallInChannel({
    required this.channelId,
    this.remoteUids = const [],
    this.isMuted = false,
    this.isCameraDisabled = false,
    this.callMetadata,
  });

  CallInChannel copyWith({
    String? channelId,
    List<int>? remoteUids,
    bool? isMuted,
    bool? isCameraDisabled,
    CallEntity? callMetadata,
  }) {
    return CallInChannel(
      channelId: channelId ?? this.channelId,
      remoteUids: remoteUids ?? this.remoteUids,
      isMuted: isMuted ?? this.isMuted,
      isCameraDisabled: isCameraDisabled ?? this.isCameraDisabled,
      callMetadata: callMetadata ?? this.callMetadata,
    );
  }

  @override
  List<Object?> get props => [
    channelId,
    remoteUids,
    isMuted,
    isCameraDisabled,
    callMetadata,
  ];
}

class CallEnded extends CallState {}

class CallError extends CallState {
  final String message;
  const CallError(this.message);
}

// BLoC
class CallBloc extends Bloc<CallEvent, CallState> {
  final CallRemoteDataSource remoteDataSource;
  StreamSubscription? _incomingCallSubscription;
  StreamSubscription? _callStatusSubscription;
  final List<int> _bufferedRemoteUids = [];

  CallBloc({required this.remoteDataSource}) : super(CallInitial()) {
    on<InitiateCallEvent>(_onInitiateCall);
    on<AcceptCallEvent>(_onAcceptCall);
    on<RejectCallEvent>(_onRejectCall);
    on<IncomingCallReceivedEvent>(_onIncomingCallReceived);
    on<CallStatusUpdatedEvent>(_onCallStatusUpdated);
    on<JoinCallEvent>(_onJoinCall);
    on<LeaveCallEvent>(_onLeaveCall);
    on<RemoteUserJoinedEvent>(_onRemoteUserJoined);
    on<RemoteUserOfflineEvent>(_onRemoteUserOffline);
    on<ToggleMuteEvent>(_onToggleMute);
    on<ToggleCameraEvent>(_onToggleCamera);
    on<SwitchCameraEvent>(_onSwitchCamera);
    on<_CallErrorInternalEvent>(
      (event, emit) => emit(CallError(event.message)),
    );
  }

  void listenToIncomingCalls(String userId) {
    _incomingCallSubscription?.cancel();
    _incomingCallSubscription = remoteDataSource
        .streamIncomingCalls(userId)
        .listen((calls) {
          if (calls.isNotEmpty) {
            add(IncomingCallReceivedEvent(calls.first));
          }
        });
  }

  Future<void> _onInitiateCall(
    InitiateCallEvent event,
    Emitter<CallState> emit,
  ) async {
    final callId = const Uuid().v4();
    final call = CallEntity(
      id: callId,
      channelName: callId,
      callerId: event.callerId,
      callerName: event.callerName,
      receiverId: event.receiverId,
      receiverName: event.receiverName,
      status: 'dialing',
      timestamp: DateTime.now(),
    );

    try {
      await remoteDataSource.createCall(call);
      emit(CallDialing(call));

      _callStatusSubscription?.cancel();
      _callStatusSubscription = remoteDataSource
          .streamCallStatus(callId)
          .listen((updatedCall) {
            add(CallStatusUpdatedEvent(updatedCall));
          });
    } catch (e) {
      emit(CallError(e.toString()));
    }
  }

  Future<void> _onAcceptCall(
    AcceptCallEvent event,
    Emitter<CallState> emit,
  ) async {
    try {
      // Only update Firestore. CallPage.initState() fires JoinCallEvent itself.
      await remoteDataSource.updateCallStatus(event.call.id!, 'accepted');
      // Keep the CallRinging state so CallPage shows the correct connecting screen.
      // The JoinCallEvent from CallPage.initState will move us to CallInChannel.
    } catch (e) {
      emit(CallError(e.toString()));
    }
  }

  Future<void> _onRejectCall(
    RejectCallEvent event,
    Emitter<CallState> emit,
  ) async {
    try {
      await remoteDataSource.updateCallStatus(event.callId, 'rejected');
      emit(CallEnded());
    } catch (e) {
      emit(CallError(e.toString()));
    }
  }

  void _onIncomingCallReceived(
    IncomingCallReceivedEvent event,
    Emitter<CallState> emit,
  ) {
    // Only handle if not already in a call
    if (state is! CallInChannel &&
        state is! CallDialing &&
        state is! CallRinging) {
      emit(CallRinging(event.call));

      _callStatusSubscription?.cancel();
      _callStatusSubscription = remoteDataSource
          .streamCallStatus(event.call.id!)
          .listen((updatedCall) {
            add(CallStatusUpdatedEvent(updatedCall));
          });
    }
  }

  Future<void> _onCallStatusUpdated(
    CallStatusUpdatedEvent event,
    Emitter<CallState> emit,
  ) async {
    if (event.call == null ||
        event.call!.status == 'ended' ||
        event.call!.status == 'rejected') {
      _callStatusSubscription?.cancel();
      if (state is CallInChannel) {
        add(LeaveCallEvent());
      } else {
        emit(CallEnded());
      }
    }
    // 'accepted' is handled by CallPage.initState -> JoinCallEvent.
    // No extra dispatch needed here.
  }

  Future<void> _onJoinCall(JoinCallEvent event, Emitter<CallState> emit) async {
    try {
      await remoteDataSource.initEngine(
        onUserJoined: (uid) => add(RemoteUserJoinedEvent(uid)),
        onUserOffline: (uid) => add(RemoteUserOfflineEvent(uid)),
        onLeaveChannel: () => add(LeaveCallEvent()),
        onError: (message) => add(_CallErrorInternalEvent(message)),
      );
      await remoteDataSource.joinChannel(event.channelId);

      CallEntity? metadata;
      if (state is CallDialing) {
        metadata = (state as CallDialing).call;
      } else if (state is CallRinging) {
        metadata = (state as CallRinging).call;
      }

      emit(
        CallInChannel(
          channelId: event.channelId,
          callMetadata: metadata,
          remoteUids: List.from(_bufferedRemoteUids),
        ),
      );
    } catch (e) {
      emit(CallError(e.toString()));
    }
  }

  Future<void> _onLeaveCall(
    LeaveCallEvent event,
    Emitter<CallState> emit,
  ) async {
    if (state is CallInChannel) {
      final call = (state as CallInChannel).callMetadata;
      if (call?.id != null) {
        await remoteDataSource.updateCallStatus(call!.id!, 'ended');
      }
    } else if (state is CallDialing) {
      final call = (state as CallDialing).call;
      await remoteDataSource.updateCallStatus(call.id!, 'ended');
    }

    _callStatusSubscription?.cancel();
    _bufferedRemoteUids.clear();
    await remoteDataSource.leaveChannel();
    emit(CallEnded());
  }

  void _onRemoteUserJoined(
    RemoteUserJoinedEvent event,
    Emitter<CallState> emit,
  ) {
    if (!_bufferedRemoteUids.contains(event.uid)) {
      _bufferedRemoteUids.add(event.uid);
    }
    if (state is CallInChannel) {
      final currentState = state as CallInChannel;
      emit(currentState.copyWith(remoteUids: List.from(_bufferedRemoteUids)));
    }
  }

  void _onRemoteUserOffline(
    RemoteUserOfflineEvent event,
    Emitter<CallState> emit,
  ) {
    _bufferedRemoteUids.remove(event.uid);
    if (state is CallInChannel) {
      final currentState = state as CallInChannel;
      emit(currentState.copyWith(remoteUids: List.from(_bufferedRemoteUids)));
    }
  }

  Future<void> _onToggleMute(
    ToggleMuteEvent event,
    Emitter<CallState> emit,
  ) async {
    if (state is CallInChannel) {
      await remoteDataSource.toggleMute(event.muted);
      emit((state as CallInChannel).copyWith(isMuted: event.muted));
    }
  }

  Future<void> _onToggleCamera(
    ToggleCameraEvent event,
    Emitter<CallState> emit,
  ) async {
    if (state is CallInChannel) {
      await remoteDataSource.toggleVideo(event.disabled);
      emit((state as CallInChannel).copyWith(isCameraDisabled: event.disabled));
    }
  }

  Future<void> _onSwitchCamera(
    SwitchCameraEvent event,
    Emitter<CallState> emit,
  ) async {
    await remoteDataSource.switchCamera();
  }

  @override
  Future<void> close() {
    _incomingCallSubscription?.cancel();
    _callStatusSubscription?.cancel();
    return super.close();
  }
}
