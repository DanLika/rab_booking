import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_ai/firebase_ai.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/enhanced_auth_provider.dart';
import '../../../../core/services/logging_service.dart';
import '../../data/repositories/ai_chat_repository.dart';
import '../../domain/models/ai_chat.dart';

// ---------------------------------------------------------------------------
// Repository provider
// ---------------------------------------------------------------------------

final aiChatRepositoryProvider = Provider<AiChatRepository>((ref) {
  return AiChatRepository();
});

// ---------------------------------------------------------------------------
// AI consent provider (Firestore-backed for GDPR audit)
// ---------------------------------------------------------------------------

final aiChatConsentProvider = FutureProvider<bool>((ref) async {
  final authState = ref.watch(enhancedAuthProvider);
  final userId = authState.firebaseUser?.uid;
  if (userId == null) return false;

  try {
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('data')
        .doc('ai_consent')
        .get();
    return doc.exists && (doc.data()?['accepted'] == true);
  } catch (e) {
    return false;
  }
});

/// Grant AI chat consent (stored in Firestore for GDPR audit)
Future<void> grantAiChatConsent(String userId) async {
  await FirebaseFirestore.instance
      .collection('users')
      .doc(userId)
      .collection('data')
      .doc('ai_consent')
      .set({'accepted': true, 'accepted_at': FieldValue.serverTimestamp()});
}

// ---------------------------------------------------------------------------
// Chat list stream
// ---------------------------------------------------------------------------

final aiChatsProvider = StreamProvider<List<AiChat>>((ref) {
  final authState = ref.watch(enhancedAuthProvider);
  final userId = authState.firebaseUser?.uid;
  if (userId == null) return Stream.value([]);

  final repo = ref.watch(aiChatRepositoryProvider);
  return repo.getChats(userId);
});

// ---------------------------------------------------------------------------
// Gemini model (lazy singleton)
// ---------------------------------------------------------------------------

final _aiModelProvider = FutureProvider<GenerativeModel>((ref) async {
  // ignore: avoid_print
  print('[AiChat] Loading KB from assets...');
  final kb = await rootBundle.loadString('assets/kb/bookbed_knowledge_base.md');
  // ignore: avoid_print
  print('[AiChat] KB loaded: ${kb.length} chars');

  final ai = FirebaseAI.googleAI();
  // ignore: avoid_print
  print('[AiChat] Creating generative model...');
  final model = ai.generativeModel(
    model: 'gemini-2.5-flash-lite',
    systemInstruction: Content.system(kb),
  );
  // ignore: avoid_print
  print('[AiChat] Model created successfully');
  return model;
});

// ---------------------------------------------------------------------------
// Active chat state
// ---------------------------------------------------------------------------

class AiChatState {
  final AiChat? currentChat;
  final bool isLoading;
  final bool isStreaming;
  final String streamingText;
  final String? error;
  final int dailyMessageCount;
  final DateTime? dailyCountResetDate;

  const AiChatState({
    this.currentChat,
    this.isLoading = false,
    this.isStreaming = false,
    this.streamingText = '',
    this.error,
    this.dailyMessageCount = 0,
    this.dailyCountResetDate,
  });

  AiChatState copyWith({
    AiChat? currentChat,
    bool? isLoading,
    bool? isStreaming,
    String? streamingText,
    String? error,
    int? dailyMessageCount,
    DateTime? dailyCountResetDate,
    bool clearChat = false,
    bool clearError = false,
  }) {
    return AiChatState(
      currentChat: clearChat ? null : (currentChat ?? this.currentChat),
      isLoading: isLoading ?? this.isLoading,
      isStreaming: isStreaming ?? this.isStreaming,
      streamingText: streamingText ?? this.streamingText,
      error: clearError ? null : (error ?? this.error),
      dailyMessageCount: dailyMessageCount ?? this.dailyMessageCount,
      dailyCountResetDate: dailyCountResetDate ?? this.dailyCountResetDate,
    );
  }

  bool get hasReachedDailyLimit {
    _checkDayReset();
    return dailyMessageCount >= 30;
  }

  void _checkDayReset() {
    // This is a pure check — actual reset happens in the notifier
  }
}

// ---------------------------------------------------------------------------
// Predefined answers + blocked keywords
// ---------------------------------------------------------------------------

/// Technical keywords that indicate off-topic questions.
/// Returns a canned response instead of calling Gemini.
const _blockedKeywords = [
  'firebase',
  'firestore',
  'flutter',
  'api',
  'backend',
  'database',
  'server',
  'cloud function',
  'sdk',
  'endpoint',
  'graphql',
  'rest api',
  'sql',
  'mongodb',
  'docker',
  'kubernetes',
  'aws',
  'terraform',
  'github',
  'git',
  'npm',
  'node',
  'react',
  'angular',
  'vue',
  'python',
  'java',
  'kotlin',
  'swift',
  'xcode',
  'android studio',
  'source code',
  'izvorni kod',
  'programiranje',
  'programski jezik',
];

/// Predefined answers for common questions (keyword → answer).
/// Checked before calling Gemini to save API costs.
const _predefinedAnswers = <_PredefinedAnswer>[
  _PredefinedAnswer(
    keywords: [
      'cijena',
      'pricing',
      'price',
      'postavi cijene',
      'set up pricing',
      'koliko kosta',
      'how much',
    ],
    answerHr: '''Da biste postavili cijene za vaš smještaj:

1. Otvorite **Smještajne jedinice** u izborniku
2. Odaberite jedinicu i idite na tab **Cjenovnik**
3. Postavite **baznu cijenu po noćenju**
4. Po potrebi dodajte **vikend cijene** (petkom i subotom)
5. Za sezonske cijene, koristite **kalendar cijena** gdje možete označiti datume i postaviti prilagođene cijene

Cijene se automatski prikazuju u vašem widgetu za rezervacije.''',
    answerEn: '''To set up pricing for your accommodation:

1. Open **Units** from the menu
2. Select a unit and go to the **Pricing** tab
3. Set your **base price per night**
4. Optionally add **weekend prices** (Friday and Saturday)
5. For seasonal pricing, use the **price calendar** where you can select dates and set custom prices

Prices are automatically displayed in your booking widget.''',
  ),
  _PredefinedAnswer(
    keywords: [
      'stripe',
      'placanje',
      'plaćanje',
      'payment',
      'kartice',
      'card',
      'connect stripe',
      'poveži stripe',
    ],
    answerHr: '''Da biste omogućili plaćanje karticom:

1. Otvorite **Integracije → Stripe plaćanja** u izborniku
2. Kliknite **Poveži Stripe račun**
3. Slijedite Stripe upute za kreiranje ili povezivanje računa
4. Nakon povezivanja, omogućite kartično plaćanje u **postavkama widgeta** za svaku jedinicu

Novac od rezervacija ide direktno na vaš Stripe račun. BookBed trenutno ne naplaćuje proviziju.''',
    answerEn: '''To enable card payments:

1. Open **Integrations → Stripe Payments** from the menu
2. Click **Connect Stripe Account**
3. Follow the Stripe instructions to create or link an account
4. After connecting, enable card payments in **widget settings** for each unit

Reservation payments go directly to your Stripe account. BookBed currently does not charge a commission.''',
  ),
  _PredefinedAnswer(
    keywords: [
      'ical',
      'sync',
      'sinkronizacija',
      'booking.com',
      'airbnb',
      'kalendar sync',
      'calendar sync',
    ],
    answerHr: '''Za sinkronizaciju kalendara s Booking.com ili Airbnb:

**Import (primanje rezervacija):**
1. Otvorite **Integracije → Uvoz rezervacija**
2. Kliknite **Dodaj novi feed**
3. Zalijepite iCal URL iz Booking.com/Airbnb panela
4. BookBed automatski sinkronizira svakih 15 minuta

**Export (slanje dostupnosti):**
1. Otvorite **Integracije → Izvoz kalendara**
2. Kopirajte URL za svaku platformu
3. Zalijepite URL u Booking.com/Airbnb panel za uvoz

Svaka platforma dobiva poseban URL koji isključuje njene vlastite rezervacije.''',
    answerEn: '''To sync your calendar with Booking.com or Airbnb:

**Import (receiving bookings):**
1. Open **Integrations → Import Bookings**
2. Click **Add New Feed**
3. Paste the iCal URL from your Booking.com/Airbnb panel
4. BookBed automatically syncs every 15 minutes

**Export (sending availability):**
1. Open **Integrations → Export Calendar**
2. Copy the URL for each platform
3. Paste the URL in your Booking.com/Airbnb import panel

Each platform gets a separate URL that excludes its own bookings.''',
  ),
  _PredefinedAnswer(
    keywords: [
      'widget',
      'embed',
      'ugraditi',
      'ugradi',
      'iframe',
      'web stranica',
      'website',
    ],
    answerHr: '''Da biste ugradili BookBed widget na svoju web stranicu:

1. Otvorite **Integracije → Widget za ugradnju**
2. Odaberite jedinicu za koju želite widget
3. Kopirajte iframe kod
4. Zalijepite kod na svoju web stranicu

Widget automatski prikazuje kalendar dostupnosti, cijene i obrazac za rezervaciju.''',
    answerEn: '''To embed the BookBed widget on your website:

1. Open **Integrations → Embed Widget**
2. Select the unit you want the widget for
3. Copy the iframe code
4. Paste the code on your website

The widget automatically shows availability calendar, prices, and booking form.''',
  ),
  _PredefinedAnswer(
    keywords: [
      'apartman',
      'unit',
      'smještaj',
      'dodati',
      'add',
      'kreirati',
      'create',
      'novi',
      'new unit',
    ],
    answerHr: '''Da biste dodali novi smještaj:

1. Otvorite **Smještajne jedinice** u izborniku
2. Kliknite **Dodaj jedinicu** (ili koristite čarobnjak za brzo postavljanje)
3. Ispunite osnovne podatke: naziv, opis, kapacitet
4. Postavite cijene na tabu **Cjenovnik**
5. Po potrebi konfigurirajte postavke widgeta

Jedinica će automatski biti dostupna za rezervacije nakon postavljanja cijena.''',
    answerEn: '''To add a new accommodation unit:

1. Open **Units** from the menu
2. Click **Add Unit** (or use the wizard for quick setup)
3. Fill in basic details: name, description, capacity
4. Set prices on the **Pricing** tab
5. Optionally configure widget settings

The unit will automatically be available for bookings after pricing is set up.''',
  ),
];

class _PredefinedAnswer {
  final List<String> keywords;
  final String answerHr;
  final String answerEn;

  const _PredefinedAnswer({
    required this.keywords,
    required this.answerHr,
    required this.answerEn,
  });
}

// ---------------------------------------------------------------------------
// Chat Notifier
// ---------------------------------------------------------------------------

final aiChatNotifierProvider =
    StateNotifierProvider<AiChatNotifier, AiChatState>((ref) {
      return AiChatNotifier(ref);
    });

class AiChatNotifier extends StateNotifier<AiChatState> {
  final Ref _ref;
  ChatSession? _chatSession;

  AiChatNotifier(this._ref) : super(const AiChatState());

  String? get _userId => _ref.read(enhancedAuthProvider).firebaseUser?.uid;

  AiChatRepository get _repo => _ref.read(aiChatRepositoryProvider);

  /// Detect language from text (simple heuristic)
  String _detectLanguage(String text) {
    final lower = text.toLowerCase();
    // Croatian-specific characters and common words
    const hrIndicators = [
      'ć',
      'č',
      'ž',
      'š',
      'đ',
      'kako',
      'gdje',
      'zašto',
      'molim',
      'hvala',
      'trebam',
      'mogu',
      'želim',
      'imam',
      'treba',
      'pomoć',
    ];
    for (final indicator in hrIndicators) {
      if (lower.contains(indicator)) return 'hr';
    }
    return 'en';
  }

  /// Check if message contains blocked technical keywords
  String? _checkBlockedKeywords(String text) {
    final lower = text.toLowerCase();
    for (final keyword in _blockedKeywords) {
      if (lower.contains(keyword)) {
        final lang = _detectLanguage(text);
        if (lang == 'hr') {
          return 'Mogu pomoći samo s korištenjem BookBed funkcionalnosti. '
              'Za tehnička pitanja, kontaktirajte support@bookbed.io';
        }
        return 'I can only help with BookBed features. '
            'For technical questions, please contact support@bookbed.io';
      }
    }
    return null;
  }

  /// Check predefined answers map
  String? _checkPredefinedAnswers(String text) {
    final lower = text.toLowerCase();
    final lang = _detectLanguage(text);

    for (final entry in _predefinedAnswers) {
      int matchCount = 0;
      for (final keyword in entry.keywords) {
        if (lower.contains(keyword)) matchCount++;
      }
      // Require at least 1 keyword match
      if (matchCount >= 1) {
        return lang == 'hr' ? entry.answerHr : entry.answerEn;
      }
    }
    return null;
  }

  /// Reset daily counter if day has changed
  void _resetDailyCountIfNeeded() {
    final today = DateTime.now();
    final resetDate = state.dailyCountResetDate;
    if (resetDate == null ||
        today.year != resetDate.year ||
        today.month != resetDate.month ||
        today.day != resetDate.day) {
      state = state.copyWith(dailyMessageCount: 0, dailyCountResetDate: today);
    }
  }

  /// Create a new chat
  Future<void> createNewChat() async {
    _chatSession = null;
    state = state.copyWith(
      clearChat: true,
      clearError: true,
      isStreaming: false,
      streamingText: '',
    );
  }

  /// Load an existing chat
  Future<void> loadChat(String chatId) async {
    final userId = _userId;
    if (userId == null) return;

    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final chat = await _repo.getChat(userId, chatId);
      _chatSession = null; // Will be recreated on next message
      state = state.copyWith(currentChat: chat, isLoading: false);
    } catch (e, stackTrace) {
      await LoggingService.logError(
        'AiChat: Failed to load chat',
        e,
        stackTrace,
      );
      state = state.copyWith(isLoading: false, error: 'Failed to load chat');
    }
  }

  /// Send a message
  Future<void> sendMessage(String text) async {
    // ignore: avoid_print
    print(
      '[AiChat] sendMessage called: "${text.substring(0, text.length > 30 ? 30 : text.length)}"',
    );
    final userId = _userId;
    if (userId == null) {
      // ignore: avoid_print
      print('[AiChat] ERROR: userId is null!');
      return;
    }
    if (text.trim().isEmpty) return;

    // 1. Check daily limit
    _resetDailyCountIfNeeded();
    if (state.dailyMessageCount >= 30) {
      state = state.copyWith(error: 'daily_limit');
      return;
    }

    final userMessage = AiChatMessage(
      role: 'user',
      content: text.trim(),
      timestamp: DateTime.now(),
    );

    // Add user message to current chat immediately
    final existingMessages = List<AiChatMessage>.from(
      state.currentChat?.messages ?? [],
    );
    existingMessages.add(userMessage);

    final lang = _detectLanguage(text);
    final isNewChat = state.currentChat == null;
    final now = DateTime.now();

    AiChat updatedChat;
    if (isNewChat) {
      // Generate title from first message (truncated)
      final title = text.length > 40 ? '${text.substring(0, 40)}...' : text;
      updatedChat = AiChat(
        id: '', // Will be set after Firestore create
        title: title,
        messages: existingMessages,
        language: lang,
        createdAt: now,
        updatedAt: now,
        expiresAt: now.add(const Duration(days: 365)),
      );
    } else {
      updatedChat = state.currentChat!.copyWith(
        messages: existingMessages,
        updatedAt: now,
      );
    }

    state = state.copyWith(
      currentChat: updatedChat,
      isStreaming: true,
      streamingText: '',
      clearError: true,
    );

    // 2. Check blocked keywords
    // ignore: avoid_print
    print('[AiChat] Step 2: Checking blocked keywords...');
    final blockedResponse = _checkBlockedKeywords(text);
    if (blockedResponse != null) {
      // ignore: avoid_print
      print('[AiChat] BLOCKED keyword detected');
      await _handleCannedResponse(
        userId: userId,
        response: blockedResponse,
        updatedChat: updatedChat,
        isNewChat: isNewChat,
      );
      return;
    }

    // 3. Check predefined answers
    // ignore: avoid_print
    print('[AiChat] Step 3: Checking predefined answers...');
    final predefined = _checkPredefinedAnswers(text);
    if (predefined != null) {
      // ignore: avoid_print
      print('[AiChat] PREDEFINED answer found');
      await _handleCannedResponse(
        userId: userId,
        response: predefined,
        updatedChat: updatedChat,
        isNewChat: isNewChat,
      );
      return;
    }

    // 4. Call Gemini
    try {
      // ignore: avoid_print
      print('[AiChat] Step 4: Loading Gemini model...');
      final model = await _ref.read(_aiModelProvider.future);
      // ignore: avoid_print
      print('[AiChat] Step 4b: Model loaded OK');

      // Create or reuse chat session
      if (_chatSession == null) {
        // Build history from existing messages (exclude the new one)
        final history = <Content>[];
        for (final msg in existingMessages) {
          if (msg == userMessage) continue;
          if (msg.isUser) {
            history.add(Content.text(msg.content));
          } else {
            history.add(Content('model', [TextPart(msg.content)]));
          }
        }
        _chatSession = model.startChat(history: history);
      }

      // Stream response
      // ignore: avoid_print
      print('[AiChat] Step 4c: Sending to Gemini...');
      final responseStream = _chatSession!.sendMessageStream(
        Content.text(text.trim()),
      );
      final buffer = StringBuffer();

      await for (final chunk in responseStream) {
        final chunkText = chunk.text;
        if (chunkText != null) {
          buffer.write(chunkText);
          state = state.copyWith(streamingText: buffer.toString());
        }
      }

      final assistantMessage = AiChatMessage(
        role: 'assistant',
        content: buffer.toString(),
        timestamp: DateTime.now(),
      );

      existingMessages.add(assistantMessage);
      updatedChat = updatedChat.copyWith(
        messages: existingMessages,
        updatedAt: DateTime.now(),
      );

      // Save to Firestore
      if (isNewChat) {
        final chatId = await _repo.createChat(userId, updatedChat);
        updatedChat = updatedChat.copyWith(id: chatId);
      } else {
        await _repo.updateChat(
          userId,
          updatedChat.id,
          messages: existingMessages,
        );
      }

      state = state.copyWith(
        currentChat: updatedChat,
        isStreaming: false,
        streamingText: '',
        dailyMessageCount: state.dailyMessageCount + 1,
      );

      // Invalidate chat list
      _ref.invalidate(aiChatsProvider);
    } catch (e, stackTrace) {
      // ignore: avoid_print
      print('[AiChat] ERROR: $e');
      await LoggingService.logError('AiChat: Gemini error', e, stackTrace);

      // Still save the user message even if AI fails
      try {
        if (isNewChat) {
          final chatId = await _repo.createChat(userId, updatedChat);
          updatedChat = updatedChat.copyWith(id: chatId);
        } else {
          await _repo.updateChat(
            userId,
            updatedChat.id,
            messages: existingMessages,
          );
        }
      } catch (_) {
        // Ignore Firestore save errors in error path
      }

      // Show actual error for debugging (TODO: remove after fixing)
      final errorMsg = e.toString();
      state = state.copyWith(
        currentChat: updatedChat,
        isStreaming: false,
        streamingText: '',
        error: 'DEBUG: $errorMsg',
      );
      _ref.invalidate(aiChatsProvider);
    }
  }

  /// Handle canned (predefined/blocked) responses without calling Gemini
  Future<void> _handleCannedResponse({
    required String userId,
    required String response,
    required AiChat updatedChat,
    required bool isNewChat,
  }) async {
    final assistantMessage = AiChatMessage(
      role: 'assistant',
      content: response,
      timestamp: DateTime.now(),
    );

    final messages = List<AiChatMessage>.from(updatedChat.messages);
    messages.add(assistantMessage);
    var finalChat = updatedChat.copyWith(
      messages: messages,
      updatedAt: DateTime.now(),
    );

    // Save to Firestore
    if (isNewChat) {
      final chatId = await _repo.createChat(userId, finalChat);
      finalChat = finalChat.copyWith(id: chatId);
    } else {
      await _repo.updateChat(userId, finalChat.id, messages: messages);
    }

    state = state.copyWith(
      currentChat: finalChat,
      isStreaming: false,
      streamingText: '',
      dailyMessageCount: state.dailyMessageCount + 1,
    );
    _ref.invalidate(aiChatsProvider);
  }

  /// Delete a chat
  Future<void> deleteChat(String chatId) async {
    final userId = _userId;
    if (userId == null) return;

    try {
      await _repo.deleteChat(userId, chatId);
      if (state.currentChat?.id == chatId) {
        _chatSession = null;
        state = state.copyWith(clearChat: true);
      }
      _ref.invalidate(aiChatsProvider);
    } catch (e, stackTrace) {
      await LoggingService.logError('AiChat: Delete failed', e, stackTrace);
    }
  }
}
