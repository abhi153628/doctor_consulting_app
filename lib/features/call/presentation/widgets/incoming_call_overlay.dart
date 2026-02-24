import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/call_bloc.dart';
import '../pages/call_page.dart';
import '../../../../core/theme/app_theme.dart';

class IncomingCallOverlay extends StatelessWidget {
  final Widget child;

  const IncomingCallOverlay({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return BlocListener<CallBloc, CallState>(
      listener: (context, state) {
        if (state is CallRinging) {
          _showIncomingCallDialog(context, state);
        } else if (state is CallInChannel && Navigator.canPop(context)) {
          // If we transitioned to InChannel, we might need to navigate
          // But usually AcceptCallEvent handles navigation to CallPage
        }
      },
      child: child,
    );
  }

  void _showIncomingCallDialog(BuildContext context, CallRinging state) {
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (innerContext) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Incoming Video Call',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 16),
              CircleAvatar(
                radius: 40,
                backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                child: const Icon(
                  Icons.person,
                  size: 40,
                  color: AppTheme.primaryColor,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                state.call.callerName,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _callActionBtn(
                    icon: Icons.call_end,
                    color: Colors.red,
                    label: 'Decline',
                    onTap: () {
                      context.read<CallBloc>().add(
                        RejectCallEvent(state.call.id!),
                      );
                      Navigator.pop(innerContext);
                    },
                  ),
                  _callActionBtn(
                    icon: Icons.videocam,
                    color: Colors.green,
                    label: 'Accept',
                    onTap: () {
                      final call = state.call;
                      context.read<CallBloc>().add(AcceptCallEvent(call));
                      Navigator.pop(innerContext);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CallPage(
                            channelId: call.channelName,
                            remoteName: call.callerName,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _callActionBtn({
    required IconData icon,
    required Color color,
    required String label,
    required VoidCallback onTap,
  }) {
    return Column(
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 30),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
