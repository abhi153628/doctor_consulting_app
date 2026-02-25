import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:doctor_booking_app/features/chat/data/models/chat_model.dart';
import 'package:doctor_booking_app/features/chat/data/models/message_model.dart';

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
      batch.set(chatDoc, {
        'id': chatId,
        'participantIds': [message.senderId, message.receiverId],
        'lastMessage': message.toJson(),
      });
    } else {
      batch.update(chatDoc, {'lastMessage': message.toJson()});
    }

    final messageDoc = chatDoc.collection('messages').doc(message.id);
    batch.set(messageDoc, message.toJson());

    await batch.commit();
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
