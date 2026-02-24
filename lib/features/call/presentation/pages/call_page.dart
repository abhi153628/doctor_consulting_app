import 'dart:async';
import 'package:flutter/material.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/call_bloc.dart';
import '../../data/datasources/call_remote_data_source.dart';
import '../../../../injection_container.dart';

class CallPage extends StatefulWidget {
  final String channelId;
  final String? remoteName;

  const CallPage({super.key, required this.channelId, this.remoteName});

  @override
  State<CallPage> createState() => _CallPageState();
}

class _CallPageState extends State<CallPage> {
  Timer? _durationTimer;
  int _durationSeconds = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CallBloc>().add(JoinCallEvent(widget.channelId));
    });
  }

  @override
  void dispose() {
    _durationTimer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    if (_durationTimer != null) return;
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _durationSeconds++;
        });
      }
    });
  }

  String _formatDuration(int seconds) {
    final mins = seconds ~/ 60;
    final secs = seconds % 60;
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // Prevent accidental back-press without ending call
      onPopInvoked: (didPop) {
        if (!didPop) {
          context.read<CallBloc>().add(LeaveCallEvent());
        }
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: BlocConsumer<CallBloc, CallState>(
          listener: (context, state) {
            if (state is CallEnded) {
              Navigator.of(context).pop();
            } else if (state is CallError) {
              // Show error dialog then exit
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (_) => AlertDialog(
                  title: const Row(
                    children: [
                      Icon(Icons.error_outline, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Call Failed'),
                    ],
                  ),
                  content: SingleChildScrollView(
                    child: Text(
                      state.message,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop(); // close dialog
                        Navigator.of(context).pop(); // close CallPage
                      },
                      child: const Text('OK'),
                    ),
                  ],
                ),
              );
            }
          },
          builder: (context, state) {
            if (state is CallInChannel) {
              return _buildActiveCall(context, state);
            }

            // Show connecting/waiting screen for all pre-connected states
            String label = 'Connecting...';
            String? name = widget.remoteName;
            if (state is CallDialing) {
              label = 'Calling...';
              name = state.call.receiverName;
            } else if (state is CallRinging) {
              label = 'Incoming call';
              name = state.call.callerName;
            }

            return _buildConnectingScreen(context, label, name);
          },
        ),
      ),
    );
  }

  // ─── CONNECTING SCREEN ────────────────────────────────────────────────────

  Widget _buildConnectingScreen(
    BuildContext context,
    String label,
    String? name,
  ) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF1A237E), Color(0xFF000000)],
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            const Spacer(),
            // Avatar
            Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.15),
                border: Border.all(color: Colors.white38, width: 2),
              ),
              child: const Icon(Icons.person, size: 60, color: Colors.white70),
            ),
            const SizedBox(height: 24),
            if (name != null && name.isNotEmpty)
              Text(
                name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white54,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  label,
                  style: const TextStyle(color: Colors.white54, fontSize: 16),
                ),
              ],
            ),
            const Spacer(),
            // End call button
            GestureDetector(
              onTap: () => context.read<CallBloc>().add(LeaveCallEvent()),
              child: Container(
                width: 72,
                height: 72,
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.call_end,
                  color: Colors.white,
                  size: 32,
                ),
              ),
            ),
            const SizedBox(height: 56),
          ],
        ),
      ),
    );
  }

  // ─── ACTIVE CALL SCREEN ────────────────────────────────────────────────────

  Widget _buildActiveCall(BuildContext context, CallInChannel state) {
    return Stack(
      children: [
        // Remote video (fullscreen)
        _buildRemoteVideo(state),
        // Local video (picture-in-picture, top-right)
        _buildLocalVideo(state),
        // Controls at the bottom
        _buildControls(context, state),
        // Remote name overlay at top
        _buildTopBar(state),
      ],
    );
  }

  Widget _buildRemoteVideo(CallInChannel state) {
    if (state.remoteUids.isEmpty) {
      return Container(
        color: Colors.black,
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Colors.white38, strokeWidth: 2),
              SizedBox(height: 16),
              Text(
                'Waiting for the other person...',
                style: TextStyle(color: Colors.white54, fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }

    // Start timer once someone joins
    _startTimer();

    return SizedBox.expand(
      child: AgoraVideoView(
        controller: VideoViewController.remote(
          rtcEngine: sl<CallRemoteDataSource>().engine,
          canvas: VideoCanvas(uid: state.remoteUids.first),
          connection: RtcConnection(channelId: state.channelId),
        ),
      ),
    );
  }

  Widget _buildLocalVideo(CallInChannel state) {
    return Positioned(
      top: 56,
      right: 16,
      child: GestureDetector(
        // Allow tapping to switch camera
        child: Container(
          width: 110,
          height: 160,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white60, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.4),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: state.isCameraDisabled
                ? Container(
                    color: Colors.grey[850],
                    child: const Icon(
                      Icons.videocam_off,
                      color: Colors.white54,
                      size: 32,
                    ),
                  )
                : AgoraVideoView(
                    controller: VideoViewController(
                      rtcEngine: sl<CallRemoteDataSource>().engine,
                      canvas: const VideoCanvas(uid: 0),
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(CallInChannel state) {
    final name =
        state.callMetadata?.receiverName ??
        state.callMetadata?.callerName ??
        '';
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 48, 16, 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.black.withOpacity(0.7), Colors.transparent],
          ),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.fiber_manual_record,
              color: Colors.green,
              size: 12,
            ),
            const SizedBox(width: 6),
            const Text(
              'Live',
              style: TextStyle(color: Colors.white70, fontSize: 12),
            ),
            const Spacer(),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (name.isNotEmpty)
                  Text(
                    name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                Text(
                  _formatDuration(_durationSeconds),
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControls(BuildContext context, CallInChannel state) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.fromLTRB(0, 24, 0, 48),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [Colors.black.withOpacity(0.85), Colors.transparent],
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _controlButton(
              icon: state.isMuted ? Icons.mic_off_rounded : Icons.mic_rounded,
              label: state.isMuted ? 'Unmute' : 'Mute',
              backgroundColor: state.isMuted
                  ? Colors.red.withOpacity(0.8)
                  : Colors.white.withOpacity(0.15),
              onPressed: () {
                context.read<CallBloc>().add(ToggleMuteEvent(!state.isMuted));
              },
            ),
            // End call — larger
            GestureDetector(
              onTap: () => context.read<CallBloc>().add(LeaveCallEvent()),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.call_end_rounded,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'End',
                    style: TextStyle(color: Colors.white60, fontSize: 12),
                  ),
                ],
              ),
            ),
            _controlButton(
              icon: state.isCameraDisabled
                  ? Icons.videocam_off_rounded
                  : Icons.videocam_rounded,
              label: state.isCameraDisabled ? 'Camera off' : 'Camera',
              backgroundColor: state.isCameraDisabled
                  ? Colors.red.withOpacity(0.8)
                  : Colors.white.withOpacity(0.15),
              onPressed: () {
                context.read<CallBloc>().add(
                  ToggleCameraEvent(!state.isCameraDisabled),
                );
              },
            ),
            _controlButton(
              icon: Icons.flip_camera_ios_rounded,
              label: 'Flip',
              backgroundColor: Colors.white.withOpacity(0.15),
              onPressed: () {
                context.read<CallBloc>().add(SwitchCameraEvent());
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _controlButton({
    required IconData icon,
    required String label,
    required Color backgroundColor,
    required VoidCallback onPressed,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: backgroundColor,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(color: Colors.white60, fontSize: 11),
          ),
        ],
      ),
    );
  }
}
