import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:doctor_booking_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:doctor_booking_app/features/call/presentation/bloc/call_bloc.dart';
import 'package:doctor_booking_app/features/chat/presentation/bloc/message_bloc.dart';
import 'package:doctor_booking_app/features/chat/domain/entities/message_entity.dart';
import 'package:doctor_booking_app/core/theme/app_theme.dart';
import 'package:intl/intl.dart';
import 'package:doctor_booking_app/features/call/presentation/pages/call_page.dart';

import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';

class ChatPage extends StatefulWidget {
  final String chatId;
  final String receiverName;
  final String? receiverPhoneNumber;

  const ChatPage({
    super.key,
    required this.chatId,
    required this.receiverName,
    this.receiverPhoneNumber,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late String _sortedChatId;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    // Ensure chatId is always sorted consistently (id1_id2 where id1 < id2)
    final parts = widget.chatId.split('_');
    if (parts.length == 2) {
      parts.sort();
      _sortedChatId = parts.join('_');
    } else {
      _sortedChatId = widget.chatId;
    }
    context.read<MessageBloc>().add(LoadMessagesEvent(_sortedChatId));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(widget.receiverName),
        actions: [
          BlocListener<CallBloc, CallState>(
            listener: (context, state) {
              if (state is CallDialing) {
                // Navigate with the REAL channel name from the signaling call
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CallPage(
                      channelId: state.call.channelName,
                      remoteName: state.call.receiverName,
                    ),
                  ),
                );
              }
            },
            child: IconButton(
              icon: const Icon(Icons.videocam),
              onPressed: () {
                final caller =
                    (context.read<AuthBloc>().state as AuthAuthenticated).user;
                context.read<CallBloc>().add(
                  InitiateCallEvent(
                    callerId: caller.id,
                    callerName: caller.name,
                    receiverId: widget.chatId
                        .split('_')
                        .firstWhere((id) => id != caller.id),
                    receiverName: widget.receiverName,
                  ),
                );
                // Do NOT push here — BlocListener above will navigate once
                // CallDialing state has the real channelName.
              },
            ),
          ),
          IconButton(
            icon: const Icon(Icons.call),
            onPressed: () async {
              if (widget.receiverPhoneNumber != null &&
                  widget.receiverPhoneNumber!.isNotEmpty) {
                final Uri telLaunchUri = Uri(
                  scheme: 'tel',
                  path: widget.receiverPhoneNumber,
                );
                if (await canLaunchUrl(telLaunchUri)) {
                  await launchUrl(telLaunchUri);
                }
              }
            },
          ),
        ],
      ),
      body: MultiBlocListener(
        listeners: [
          BlocListener<MessageBloc, MessageState>(
            listener: (context, state) {
              if (state.status == MessageStatus.loaded) {
                if (_isSending && !state.isSending) {
                  setState(() => _isSending = false);
                }
                final currentUser =
                    (context.read<AuthBloc>().state as AuthAuthenticated).user;
                final hasUnread = state.messages.any(
                  (m) => m.receiverId == currentUser.id && !m.isRead,
                );
                if (hasUnread) {
                  context.read<MessageBloc>().add(
                    MarkMessagesAsReadEvent(_sortedChatId, currentUser.id),
                  );
                }
                // Scroll to bottom when messages load/update
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (_scrollController.hasClients) {
                    _scrollController.animateTo(
                      0.0,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOut,
                    );
                  }
                });
              }

              if (state.messageSentSuccessfully) {
                setState(() => _isSending = false);
              }

              if (state.status == MessageStatus.error &&
                  state.errorMessage != null) {
                setState(() => _isSending = false);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.errorMessage!),
                    backgroundColor: Colors.red,
                  ),
                );
                context.read<MessageBloc>().add(ClearMessageErrorEvent());
              }
            },
          ),
        ],
        child: Column(
          children: [
            Expanded(
              child: BlocBuilder<MessageBloc, MessageState>(
                builder: (context, state) {
                  if (state.status == MessageStatus.initial ||
                      (state.status == MessageStatus.loading &&
                          state.messages.isEmpty)) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  return ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    reverse: true,
                    itemCount: state.messages.length,
                    itemBuilder: (context, index) {
                      final message = state.messages[index];
                      final currentUser =
                          (context.read<AuthBloc>().state as AuthAuthenticated)
                              .user;
                      final isMe = message.senderId == currentUser.id;

                      // Check if we should show a date separator
                      bool showDateSeparator = false;
                      if (index == state.messages.length - 1) {
                        showDateSeparator = true;
                      } else {
                        final prevMessage = state.messages[index + 1];
                        if (message.timestamp.year !=
                                prevMessage.timestamp.year ||
                            message.timestamp.month !=
                                prevMessage.timestamp.month ||
                            message.timestamp.day !=
                                prevMessage.timestamp.day) {
                          showDateSeparator = true;
                        }
                      }

                      return Column(
                        children: [
                          if (showDateSeparator)
                            _buildDateSeparator(message.timestamp),
                          _buildMessageBubble(message, isMe),
                        ],
                      );
                    },
                  );
                },
              ),
            ),
            _buildMessageInput(),
          ],
        ),
      ),
    );
  }

  Widget _buildDateSeparator(DateTime date) {
    String text;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    final dateToCheck = DateTime(date.year, date.month, date.day);

    if (dateToCheck == today) {
      text = 'Today';
    } else if (dateToCheck == yesterday) {
      text = 'Yesterday';
    } else {
      text = DateFormat('MMMM d, y').format(date);
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 24),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Text(
        text,
        style: TextStyle(
          color: Colors.grey[600],
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildMessageBubble(MessageEntity message, bool isMe) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isMe ? AppTheme.primaryColor : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMe ? 16 : 0),
            bottomRight: Radius.circular(isMe ? 0 : 16),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        child: Column(
          crossAxisAlignment: isMe
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            Text(
              message.content,
              style: TextStyle(
                color: isMe ? Colors.white : Colors.black87,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  DateFormat('hh:mm a').format(message.timestamp),
                  style: TextStyle(
                    color: isMe ? Colors.white70 : Colors.grey,
                    fontSize: 10,
                  ),
                ),
                if (isMe) ...[
                  const SizedBox(width: 4),
                  Icon(
                    message.isRead ? Icons.done_all : Icons.done,
                    size: 14,
                    color: message.isRead ? Colors.blue[200] : Colors.white70,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                decoration: InputDecoration(
                  hintText: 'Type a message...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.grey[100],
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              onPressed: _isSending
                  ? null
                  : () {
                      if (_controller.text.trim().isNotEmpty) {
                        setState(() => _isSending = true);
                        final currentUser =
                            (context.read<AuthBloc>().state
                                    as AuthAuthenticated)
                                .user;
                        final receiverId = widget.chatId
                            .split('_')
                            .firstWhere((id) => id != currentUser.id);

                        final message = MessageEntity(
                          id: const Uuid().v4(),
                          senderId: currentUser.id,
                          senderName: currentUser.name,
                          receiverId: receiverId,
                          receiverName: widget.receiverName,
                          content: _controller.text.trim(),
                          timestamp: DateTime.now(),
                        );

                        context.read<MessageBloc>().add(
                          SendMessageEvent(message),
                        );
                        _controller.clear();
                      }
                    },
              icon: _isSending
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.send),
              style: IconButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
