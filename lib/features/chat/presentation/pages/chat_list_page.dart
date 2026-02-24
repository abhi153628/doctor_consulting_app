import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:doctor_booking_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:doctor_booking_app/features/chat/presentation/bloc/chat_bloc.dart';
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
          if (state is ChatsLoaded) {
            if (state.chats.isEmpty) {
              return _buildEmptyState();
            }
            return ListView.separated(
              itemCount: state.chats.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final chat = state.chats[index];
                return _buildChatTile(chat);
              },
            );
          }
          if (state is ChatLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is ChatError) {
            return Center(child: Text(state.message));
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
    // Determine receiver name (the other person)
    // In a real app, we'd fetch the user profile.
    // For now, we'll try to guess or use "Participant"
    final receiverName = lastMessage.senderId == currentUser.id
        ? 'Patient' // Placeholder, ideally fetch from participants
        : 'Doctor'; // Placeholder

    return ListTile(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                ChatPage(chatId: chat.id, receiverName: receiverName),
          ),
        ).then((_) {
          // Refresh chats when coming back (to update unread status)
          context.read<ChatBloc>().add(GetChatsEvent(currentUser.id));
        });
      },
      leading: CircleAvatar(
        backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
        child: Icon(Icons.person, color: AppTheme.primaryColor),
      ),
      title: Text(
        receiverName,
        style: TextStyle(
          fontWeight: isUnread ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      subtitle: Text(
        lastMessage.content,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontWeight: isUnread ? FontWeight.w600 : FontWeight.normal,
          color: isUnread ? Colors.black87 : Colors.grey,
        ),
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            DateFormat('hh:mm a').format(lastMessage.timestamp),
            style: TextStyle(
              fontSize: 12,
              color: isUnread ? AppTheme.primaryColor : Colors.grey,
            ),
          ),
          if (isUnread) ...[
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor,
                shape: BoxShape.circle,
              ),
              child: const Text(
                '', // Or count if we had it
                style: TextStyle(color: Colors.white, fontSize: 10),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_outlined, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'No messages yet',
            style: TextStyle(color: Colors.grey[600], fontSize: 16),
          ),
        ],
      ),
    );
  }
}
