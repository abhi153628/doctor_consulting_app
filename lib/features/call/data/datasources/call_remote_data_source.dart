import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/call_model.dart';
import '../../domain/entities/call_entity.dart';

class CallRemoteDataSource {
  static const String appId = "90c9250e806a47f79d3b499016647262";
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = "calls";

  RtcEngine? _engine;
  bool _isEngineInitialized = false;

  Future<void> initEngine({
    required Function(int uid) onUserJoined,
    required Function(int uid) onUserOffline,
    required Function() onLeaveChannel,
    Function(String errorMessage)? onError,
  }) async {
    // If engine is already initialized, release it first
    if (_isEngineInitialized && _engine != null) {
      try {
        await _engine!.leaveChannel();
        await _engine!.release();
      } catch (_) {}
      _engine = null;
      _isEngineInitialized = false;
    }

    // Request permissions
    final statuses = await [Permission.microphone, Permission.camera].request();
    final micGranted =
        statuses[Permission.microphone] == PermissionStatus.granted;
    final camGranted = statuses[Permission.camera] == PermissionStatus.granted;
    if (!micGranted || !camGranted) {
      debugPrint(
        "WARNING: Permissions not fully granted. mic=$micGranted, cam=$camGranted",
      );
    }

    _engine = createAgoraRtcEngine();

    try {
      await _engine!.initialize(
        const RtcEngineContext(
          appId: appId,
          channelProfile: ChannelProfileType.channelProfileCommunication,
        ),
      );
      _isEngineInitialized = true;
      debugPrint("Agora Engine Initialized successfully");
    } catch (e) {
      debugPrint("Agora initialize error: $e");
      rethrow;
    }

    _engine!.registerEventHandler(
      RtcEngineEventHandler(
        onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
          debugPrint(
            "LOCAL JOINED channel=${connection.channelId} uid=${connection.localUid}",
          );
        },
        onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
          debugPrint(
            "REMOTE JOINED channel=${connection.channelId} uid=$remoteUid",
          );
          onUserJoined(remoteUid);
        },
        onUserOffline:
            (
              RtcConnection connection,
              int remoteUid,
              UserOfflineReasonType reason,
            ) {
              debugPrint(
                "REMOTE LEFT channel=${connection.channelId} uid=$remoteUid reason=$reason",
              );
              onUserOffline(remoteUid);
            },
        onLeaveChannel: (RtcConnection connection, RtcStats stats) {
          debugPrint("LEFT channel=${connection.channelId}");
          onLeaveChannel();
        },
        onError: (ErrorCodeType err, String msg) {
          debugPrint("AGORA ERROR: code=$err msg=$msg");
          if (err == ErrorCodeType.errInvalidToken ||
              err == ErrorCodeType.errTokenExpired) {
            onError?.call(
              'Agora token error ($err). Please disable token authentication '
              'in your Agora Console project settings (enable \'Testing mode\' / \'No Auth\').',
            );
          }
        },
        onConnectionStateChanged:
            (
              RtcConnection connection,
              ConnectionStateType state,
              ConnectionChangedReasonType reason,
            ) {
              debugPrint(
                "CONNECTION STATE: $state reason=$reason channel=${connection.channelId}",
              );
              if (state == ConnectionStateType.connectionStateFailed) {
                onError?.call(
                  'Could not connect to call channel. '
                  'Check your Agora project: disable \'Primary Certificate\' in the '
                  'Agora Console so it uses App ID only (no token required).',
                );
              }
            },
      ),
    );

    // Enable video and audio
    await _engine!.enableVideo();
    await _engine!.enableAudio();
    await _engine!.startPreview();
    await _engine!.setVideoEncoderConfiguration(
      const VideoEncoderConfiguration(
        dimensions: VideoDimensions(width: 640, height: 360),
        frameRate: 15,
        bitrate: 800,
      ),
    );
    debugPrint("Video/audio enabled, preview started");
  }

  Future<void> joinChannel(String channelId) async {
    if (_engine == null || !_isEngineInitialized) {
      throw Exception("Agora engine not initialized. Call initEngine first.");
    }
    debugPrint("Joining channel: $channelId");
    await _engine!.joinChannel(
      token: "",
      channelId: channelId,
      uid: 0,
      options: const ChannelMediaOptions(
        clientRoleType: ClientRoleType.clientRoleBroadcaster,
        publishCameraTrack: true,
        publishMicrophoneTrack: true,
        autoSubscribeVideo: true,
        autoSubscribeAudio: true,
      ),
    );
  }

  Future<void> leaveChannel() async {
    if (_engine == null) return;
    try {
      await _engine!.leaveChannel();
      await _engine!.stopPreview();
      await _engine!.release();
    } catch (e) {
      debugPrint("Error leaving channel: $e");
    }
    _engine = null;
    _isEngineInitialized = false;
  }

  Future<void> switchCamera() async {
    await _engine?.switchCamera();
  }

  Future<void> toggleMute(bool muted) async {
    await _engine?.muteLocalAudioStream(muted);
  }

  Future<void> toggleVideo(bool disabled) async {
    await _engine?.muteLocalVideoStream(disabled);
  }

  RtcEngine get engine {
    if (_engine == null) throw Exception("Engine not initialized");
    return _engine!;
  }

  bool get isEngineInitialized => _isEngineInitialized;

  // --- SIGNALING METHODS ---

  Future<void> createCall(CallEntity call) async {
    final callModel = CallModel(
      id: call.id,
      channelName: call.channelName,
      token: call.token,
      callerId: call.callerId,
      callerName: call.callerName,
      receiverId: call.receiverId,
      receiverName: call.receiverName,
      status: call.status,
      timestamp: call.timestamp,
    );
    await _firestore
        .collection(_collection)
        .doc(call.id)
        .set(callModel.toJson());
  }

  Future<void> updateCallStatus(String callId, String status) async {
    await _firestore.collection(_collection).doc(callId).update({
      'status': status,
    });
  }

  Stream<List<CallEntity>> streamIncomingCalls(String userId) {
    return _firestore
        .collection(_collection)
        .where('receiverId', isEqualTo: userId)
        .where('status', isEqualTo: 'dialing')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => CallModel.fromJson(doc.data(), doc.id))
              .toList();
        });
  }

  Stream<CallEntity?> streamCallStatus(String callId) {
    return _firestore.collection(_collection).doc(callId).snapshots().map((
      doc,
    ) {
      if (doc.exists && doc.data() != null) {
        return CallModel.fromJson(doc.data()!, doc.id);
      }
      return null;
    });
  }
}
