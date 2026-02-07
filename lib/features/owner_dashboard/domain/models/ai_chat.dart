import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'ai_chat.freezed.dart';

/// A single message in an AI chat conversation
class AiChatMessage {
  final String role; // 'user' or 'assistant'
  final String content;
  final DateTime timestamp;

  const AiChatMessage({
    required this.role,
    required this.content,
    required this.timestamp,
  });

  factory AiChatMessage.fromMap(Map<String, dynamic> map) {
    return AiChatMessage(
      role: map['role'] as String? ?? 'user',
      content: map['content'] as String? ?? '',
      timestamp: (map['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'role': role,
      'content': content,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }

  bool get isUser => role == 'user';
  bool get isAssistant => role == 'assistant';
}

/// AI chat session stored in Firestore
/// Path: users/{userId}/ai_chats/{chatId}
@freezed
class AiChat with _$AiChat {
  const AiChat._();

  const factory AiChat({
    required String id,
    required String title,
    required List<AiChatMessage> messages,
    required String language,
    required DateTime createdAt,
    required DateTime updatedAt,
    required DateTime expiresAt,
  }) = _AiChat;

  /// Create from Firestore document
  factory AiChat.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    final messagesList =
        (data['messages'] as List<dynamic>?)
            ?.map((m) => AiChatMessage.fromMap(m as Map<String, dynamic>))
            .toList() ??
        [];

    return AiChat(
      id: doc.id,
      title: data['title'] as String? ?? 'New Chat',
      messages: messagesList,
      language: data['language'] as String? ?? 'hr',
      createdAt: (data['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updated_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
      expiresAt:
          (data['expires_at'] as Timestamp?)?.toDate() ??
          DateTime.now().add(const Duration(days: 365)),
    );
  }

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'messages': messages.map((m) => m.toMap()).toList(),
      'language': language,
      'created_at': Timestamp.fromDate(createdAt),
      'updated_at': Timestamp.fromDate(updatedAt),
      'expires_at': Timestamp.fromDate(expiresAt),
    };
  }

  /// Get preview of last message (truncated)
  String get lastMessagePreview {
    if (messages.isEmpty) return '';
    final last = messages.last;
    if (last.content.length > 80) {
      return '${last.content.substring(0, 80)}...';
    }
    return last.content;
  }

  /// Check if this chat has any messages
  bool get hasMessages => messages.isNotEmpty;
}
