import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/models/ai_chat.dart';

/// Repository for AI chat sessions stored in Firestore.
/// Path: users/{userId}/ai_chats/{chatId}
class AiChatRepository {
  final FirebaseFirestore _firestore;

  AiChatRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _chatsCollection(String userId) {
    return _firestore.collection('users').doc(userId).collection('ai_chats');
  }

  /// Stream of recent chats ordered by updatedAt DESC, limit 20
  Stream<List<AiChat>> getChats(String userId) {
    return _chatsCollection(userId)
        .orderBy('updated_at', descending: true)
        .limit(20)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(AiChat.fromFirestore).toList());
  }

  /// Get a single chat by ID
  Future<AiChat?> getChat(String userId, String chatId) async {
    final doc = await _chatsCollection(userId).doc(chatId).get();
    if (!doc.exists) return null;
    return AiChat.fromFirestore(doc);
  }

  /// Create a new chat and return the chatId
  Future<String> createChat(String userId, AiChat chat) async {
    final docRef = await _chatsCollection(userId).add(chat.toFirestore());
    return docRef.id;
  }

  /// Update chat with new messages and title
  Future<void> updateChat(
    String userId,
    String chatId, {
    required List<AiChatMessage> messages,
    String? title,
  }) async {
    final updates = <String, dynamic>{
      'messages': messages.map((m) => m.toMap()).toList(),
      'updated_at': Timestamp.fromDate(DateTime.now()),
    };
    if (title != null) {
      updates['title'] = title;
    }
    await _chatsCollection(userId).doc(chatId).update(updates);
  }

  /// Delete a chat
  Future<void> deleteChat(String userId, String chatId) async {
    await _chatsCollection(userId).doc(chatId).delete();
  }
}
