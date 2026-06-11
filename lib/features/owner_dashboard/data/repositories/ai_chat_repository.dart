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

  // ---------------------------------------------------------------------------
  // Server-authoritative daily AI quota (audit/123 F-123)
  // ---------------------------------------------------------------------------
  // The counter lives at users/{uid}/data/ai_usage as {day, count}. Firestore
  // rules pin `day` to request.time and enforce monotonic increment, so a
  // tampered or restarted client cannot reset it — the previous in-memory
  // counter reset to 0 on every app launch.

  DocumentReference<Map<String, dynamic>> _aiUsageDoc(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('data')
        .doc('ai_usage');
  }

  /// Day bucket as `YYYYMMDD` int — must match the rules' request.time
  /// formula, which evaluates in UTC; local time would diverge between local
  /// and UTC midnight and the rules would deny every write in that window.
  int _todayBucket() {
    final now = DateTime.now().toUtc();
    return now.year * 10000 + now.month * 100 + now.day;
  }

  /// Atomically consume one unit of today's AI quota.
  ///
  /// Returns the new usage count on success, or `null` if [limit] is already
  /// reached. Runs in a transaction so concurrent sends can't both slip past
  /// the cap. The day rolls over automatically when [_todayBucket] changes.
  Future<int?> tryConsumeDailyAiQuota(
    String userId, {
    required int limit,
  }) async {
    final docRef = _aiUsageDoc(userId);
    return _firestore.runTransaction<int?>((tx) async {
      final snap = await tx.get(docRef);
      final today = _todayBucket();
      final data = snap.data();
      final sameDay = snap.exists && data?['day'] == today;
      final current = sameDay ? (data?['count'] as int? ?? 0) : 0;
      if (current >= limit) return null;
      final next = current + 1;
      tx.set(docRef, {'day': today, 'count': next});
      return next;
    });
  }

  /// Today's AI usage count (0 if absent or from a previous day). Display only.
  Future<int> getDailyAiUsage(String userId) async {
    final snap = await _aiUsageDoc(userId).get();
    if (!snap.exists) return 0;
    final data = snap.data();
    return data?['day'] == _todayBucket() ? (data?['count'] as int? ?? 0) : 0;
  }
}
