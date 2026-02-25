import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:doctor_booking_app/features/chat/data/models/chat_model.dart';
import 'package:doctor_booking_app/features/chat/data/models/message_model.dart';
import '../../../../core/services/notification_service.dart';

abstract class ChatRemoteDataSource {
  Stream<List<ChatModel>> getChats(String userId);
  Stream<List<MessageModel>> getMessages(String chatId);
  Future<void> sendMessage(MessageModel message);
  Future<void> markMessageAsRead(String chatId, String messageId);
  Future<void> markAllMessagesAsRead(String chatId, String userId);
}

class ChatRemoteDataSourceImpl implements ChatRemoteDataSource {
  final FirebaseFirestore firestore;

  ChatRemoteDataSourceImpl({required this.firestore});

  @override
  Stream<List<ChatModel>> getChats(String userId) {
    return firestore
        .collection('chats')
        .where('participantIds', arrayContains: userId)
        .orderBy('lastMessage.timestamp', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => ChatModel.fromJson(doc.data()))
              .toList(),
        );
  }

  @override
  Stream<List<MessageModel>> getMessages(String chatId) {
    return firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => MessageModel.fromJson(doc.data()))
              .toList(),
        );
  }

  @override
  Future<void> sendMessage(MessageModel message) async {
    final chatId = _getChatId(message.senderId, message.receiverId);
    final chatDoc = firestore.collection('chats').doc(chatId);
    final batch = firestore.batch();

    final doc = await chatDoc.get();
    if (!doc.exists) {
      // First message: store BOTH participant names so chat list shows correct names
      batch.set(chatDoc, {
        'id': chatId,
        'participantIds': [message.senderId, message.receiverId],
        'participantNames': {
          message.senderId: message.senderName,
          message.receiverId: message.receiverName,
        },
        'lastMessage': message.toJson(),
      });
    } else {
      // On each message: update both names in case they changed
      batch.update(chatDoc, {
        'lastMessage': message.toJson(),
        'participantNames.${message.senderId}': message.senderName,
        if (message.receiverName.isNotEmpty)
          'participantNames.${message.receiverId}': message.receiverName,
      });
    }

    final messageDoc = chatDoc.collection('messages').doc(message.id);
    batch.set(messageDoc, message.toJson());

    await batch.commit();

    // Trigger notification to Receiver
    NotificationService.sendNotification(
      receiverIds: [message.receiverId],
      title: 'New Message from ${message.senderName}',
      content: message.content,
      data: {'type': 'new_message', 'chatId': chatId},
    );
  }

  @override
  Future<void> markMessageAsRead(String chatId, String messageId) async {
    await firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .doc(messageId)
        .update({'isRead': true});
  }

  @override
  Future<void> markAllMessagesAsRead(String chatId, String userId) async {
    final batch = firestore.batch();
    final unreadMessages = await firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .where('receiverId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .get();

    for (var doc in unreadMessages.docs) {
      batch.update(doc.reference, {'isRead': true});
    }

    await batch.commit();

    // Also update the last message in the chat doc if it's the one we just read
    final chatDoc = await firestore.collection('chats').doc(chatId).get();
    if (chatDoc.exists) {
      final chatData = chatDoc.data()!;
      if (chatData['lastMessage'] != null) {
        final lastMessage = chatData['lastMessage'] as Map<String, dynamic>;
        if (lastMessage['receiverId'] == userId &&
            lastMessage['isRead'] == false) {
          lastMessage['isRead'] = true;
          await firestore.collection('chats').doc(chatId).update({
            'lastMessage': lastMessage,
          });
        }
      }
    }
  }

  String _getChatId(String id1, String id2) {
    final ids = [id1, id2]..sort();
    return ids.join('_');
  }
}
