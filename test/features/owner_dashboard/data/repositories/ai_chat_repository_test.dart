import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bookbed/features/owner_dashboard/data/repositories/ai_chat_repository.dart';
import 'package:bookbed/features/owner_dashboard/domain/models/ai_chat.dart';

void main() {
  group('AiChatRepository', () {
    late FakeFirebaseFirestore fakeFirestore;
    late AiChatRepository repository;
    const userId = 'user_123';

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      repository = AiChatRepository(firestore: fakeFirestore);
    });

    test('createChat should add chat to Firestore and return ID', () async {
      final now = DateTime.now();
      final chat = AiChat(
        id: '', // Will be assigned by Firestore
        title: 'Test Chat',
        messages: [
          AiChatMessage(role: 'user', content: 'Hello', timestamp: now),
        ],
        language: 'en',
        createdAt: now,
        updatedAt: now,
        expiresAt: now.add(const Duration(days: 365)),
      );

      final chatId = await repository.createChat(userId, chat);

      expect(chatId, isNotEmpty);

      final doc = await fakeFirestore
          .collection('users')
          .doc(userId)
          .collection('ai_chats')
          .doc(chatId)
          .get();

      expect(doc.exists, isTrue);

      final data = doc.data()!;
      expect(data['title'], 'Test Chat');
      expect(data['language'], 'en');
      expect((data['messages'] as List).length, 1);
      expect(data['messages'][0]['content'], 'Hello');
      expect(data['messages'][0]['role'], 'user');
    });

    test('getChat should return chat if it exists', () async {
      final now = DateTime.now();

      final chatData = {
        'title': 'Existing Chat',
        'language': 'hr',
        'messages': [
          {
            'role': 'user',
            'content': 'Hi',
            'timestamp': Timestamp.fromDate(now),
          }
        ],
        'created_at': Timestamp.fromDate(now),
        'updated_at': Timestamp.fromDate(now),
        'expires_at': Timestamp.fromDate(now.add(const Duration(days: 365))),
      };

      final docRef = await fakeFirestore
          .collection('users')
          .doc(userId)
          .collection('ai_chats')
          .add(chatData);

      final chat = await repository.getChat(userId, docRef.id);

      expect(chat, isNotNull);
      expect(chat!.id, docRef.id);
      expect(chat.title, 'Existing Chat');
      expect(chat.language, 'hr');
      expect(chat.messages.length, 1);
      expect(chat.messages[0].content, 'Hi');
    });

    test('getChat should return null if chat does not exist', () async {
      final chat = await repository.getChat(userId, 'invalid_id');
      expect(chat, isNull);
    });

    test('updateChat should update messages, title, and updatedAt', () async {
      final now = DateTime.now();
      final chatData = {
        'title': 'Old Title',
        'language': 'en',
        'messages': [],
        'created_at': Timestamp.fromDate(now.subtract(const Duration(days: 1))),
        'updated_at': Timestamp.fromDate(now.subtract(const Duration(days: 1))),
        'expires_at': Timestamp.fromDate(now.add(const Duration(days: 365))),
      };

      final docRef = await fakeFirestore
          .collection('users')
          .doc(userId)
          .collection('ai_chats')
          .add(chatData);

      final newMessages = [
        AiChatMessage(role: 'user', content: 'New Message', timestamp: now),
        AiChatMessage(role: 'assistant', content: 'Response', timestamp: now.add(const Duration(seconds: 1))),
      ];

      await repository.updateChat(
        userId,
        docRef.id,
        messages: newMessages,
        title: 'New Title',
      );

      final updatedDoc = await docRef.get();
      final updatedData = updatedDoc.data()!;

      expect(updatedData['title'], 'New Title');
      expect((updatedData['messages'] as List).length, 2);
      expect(updatedData['messages'][0]['content'], 'New Message');
      expect(updatedData['messages'][1]['content'], 'Response');
      expect((updatedData['updated_at'] as Timestamp).toDate().isAfter(now.subtract(const Duration(minutes: 1))), isTrue);
    });

    test('updateChat should only update messages and updatedAt when title is null', () async {
      final now = DateTime.now();
      final chatData = {
        'title': 'Original Title',
        'language': 'en',
        'messages': [],
        'created_at': Timestamp.fromDate(now.subtract(const Duration(days: 1))),
        'updated_at': Timestamp.fromDate(now.subtract(const Duration(days: 1))),
        'expires_at': Timestamp.fromDate(now.add(const Duration(days: 365))),
      };

      final docRef = await fakeFirestore
          .collection('users')
          .doc(userId)
          .collection('ai_chats')
          .add(chatData);

      final newMessages = [
        AiChatMessage(role: 'user', content: 'New Message', timestamp: now),
      ];

      await repository.updateChat(
        userId,
        docRef.id,
        messages: newMessages,
      );

      final updatedDoc = await docRef.get();
      final updatedData = updatedDoc.data()!;

      expect(updatedData['title'], 'Original Title');
      expect((updatedData['messages'] as List).length, 1);
      expect((updatedData['updated_at'] as Timestamp).toDate().isAfter(now.subtract(const Duration(minutes: 1))), isTrue);
    });

    test('deleteChat should remove the chat from Firestore', () async {
      final now = DateTime.now();
      final chatData = {
        'title': 'To Be Deleted',
        'language': 'en',
        'messages': [],
        'created_at': Timestamp.fromDate(now),
        'updated_at': Timestamp.fromDate(now),
        'expires_at': Timestamp.fromDate(now.add(const Duration(days: 365))),
      };

      final docRef = await fakeFirestore
          .collection('users')
          .doc(userId)
          .collection('ai_chats')
          .add(chatData);

      expect((await docRef.get()).exists, isTrue);

      await repository.deleteChat(userId, docRef.id);

      expect((await docRef.get()).exists, isFalse);
    });

    test('getChats should return a stream of up to 20 chats ordered by updatedAt DESC', () async {
      final now = DateTime.now();

      // Add 25 chats with different updatedAt timestamps
      for (var i = 0; i < 25; i++) {
        final chatData = {
          'title': 'Chat $i',
          'language': 'en',
          'messages': [],
          'created_at': Timestamp.fromDate(now),
          'updated_at': Timestamp.fromDate(now.subtract(Duration(days: i))),
          'expires_at': Timestamp.fromDate(now.add(const Duration(days: 365))),
        };

        await fakeFirestore
            .collection('users')
            .doc(userId)
            .collection('ai_chats')
            .add(chatData);
      }

      // It should only return 20 chats, newest first (i=0 to i=19)
      final stream = repository.getChats(userId);
      final chats = await stream.first;

      expect(chats.length, 20);
      expect(chats[0].title, 'Chat 0'); // Newest (now)
      expect(chats[19].title, 'Chat 19'); // Oldest in limit (now - 19 days)

      // Verify ordering
      for (var i = 0; i < chats.length - 1; i++) {
        expect(
          chats[i].updatedAt.isAfter(chats[i+1].updatedAt) ||
          chats[i].updatedAt.isAtSameMomentAs(chats[i+1].updatedAt),
          isTrue
        );
      }
    });
  });
}
