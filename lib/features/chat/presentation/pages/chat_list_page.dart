import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:doctor_booking_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:doctor_booking_app/features/chat/presentation/bloc/chat_bloc.dart';
import 'package:doctor_booking_app/features/auth/domain/entities/user_entity.dart';
import 'package:doctor_booking_app/features/chat/presentation/pages/chat_page.dart';
import 'package:doctor_booking_app/features/chat/domain/entities/chat_entity.dart';
import 'package:intl/intl.dart';
import 'package:doctor_booking_app/core/theme/app_theme.dart';

class ChatListPage extends StatefulWidget {
  const ChatListPage({super.key});

  @override
  State<ChatListPage> createState() => _ChatListPageState();
}

class _ChatListPageState extends State<ChatListPage> {
  @override
  void initState() {
    super.initState();
    final user = (context.read<AuthBloc>().state as AuthAuthenticated).user;
    context.read<ChatBloc>().add(GetChatsEvent(user.id));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocBuilder<ChatBloc, ChatState>(
        builder: (context, state) {
          if (state.status == ChatStatus.loading && state.chats.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state.chats.isEmpty && state.status == ChatStatus.loaded) {
            return _buildEmptyState();
          }

          if (state.status == ChatStatus.error) {
            return Center(
              child: Text(state.errorMessage ?? 'An error occurred'),
            );
          }

          if (state.chats.isNotEmpty) {
            return ListView.separated(
              itemCount: state.chats.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final chat = state.chats[index];
                return _buildChatTile(chat);
              },
            );
          }

          return _buildEmptyState();
        },
      ),
    );
  }

  Widget _buildChatTile(ChatEntity chat) {
    final currentUser =
        (context.read<AuthBloc>().state as AuthAuthenticated).user;
    final lastMessage = chat.lastMessage;
    if (lastMessage == null) return const SizedBox.shrink();

    final isUnread =
        !lastMessage.isRead && lastMessage.receiverId == currentUser.id;

    // In a professional app, we'd have participant names in the chat doc.
    // For now, we'll infer based on the role.
    final bool isUserDoctor = currentUser.role == UserRole.doctor;

    // Get the other participant's name
    final otherParticipantId = chat.participantIds.firstWhere(
      (id) => id != currentUser.id,
      orElse: () => '',
    );

    String? resolvedName = chat.participantNames[otherParticipantId];

    // Fallback: If we are the receiver of the last message,
    // we can get the other person's name from that message.
    if (resolvedName == null && lastMessage.senderId == otherParticipantId) {
      resolvedName = lastMessage.senderName;
    }

    final receiverName = resolvedName ?? (isUserDoctor ? 'Patient' : 'Doctor');

    return ListTile(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                ChatPage(chatId: chat.id, receiverName: receiverName),
          ),
        );
      },
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: CircleAvatar(
        radius: 28,
        backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
        child: Icon(Icons.person, color: AppTheme.primaryColor, size: 30),
      ),
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            receiverName,
            style: TextStyle(
              fontWeight: isUnread ? FontWeight.bold : FontWeight.w600,
              fontSize: 16,
            ),
          ),
          Text(
            _formatTimestamp(lastMessage.timestamp),
            style: TextStyle(
              fontSize: 12,
              color: isUnread ? AppTheme.primaryColor : Colors.grey,
              fontWeight: isUnread ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Row(
          children: [
            Expanded(
              child: Text(
                lastMessage.content,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontWeight: isUnread ? FontWeight.w600 : FontWeight.normal,
                  color: isUnread ? Colors.black87 : Colors.grey[600],
                  fontSize: 14,
                ),
              ),
            ),
            if (isUnread)
              Container(
                margin: const EdgeInsets.only(left: 8),
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  color: AppTheme.primaryColor,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final date = DateTime(timestamp.year, timestamp.month, timestamp.day);

    if (date == today) {
      return DateFormat('hh:mm a').format(timestamp);
    } else if (date == today.subtract(const Duration(days: 1))) {
      return 'Yesterday';
    } else {
      return DateFormat('MM/dd/yy').format(timestamp);
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.chat_bubble_outline,
              size: 64,
              color: Colors.grey[400],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Your messages will appear here',
            style: TextStyle(
              color: Colors.grey[800],
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Keep in touch with your ${(context.read<AuthBloc>().state as AuthAuthenticated).user.role == UserRole.doctor ? 'patients' : 'doctors'}',
            style: TextStyle(color: Colors.grey[600], fontSize: 14),
          ),
        ],
      ),
    );
  }
}
