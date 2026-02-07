import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../../core/theme/app_shadows.dart';
import '../../../../../core/theme/gradient_extensions.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../../core/providers/enhanced_auth_provider.dart';
import '../../../../../shared/widgets/common_app_bar.dart';
import '../../providers/ai_chat_provider.dart';
import '../../widgets/owner_app_drawer.dart';
import '../../../domain/models/ai_chat.dart';

class AiAssistantScreen extends ConsumerStatefulWidget {
  const AiAssistantScreen({super.key});

  @override
  ConsumerState<AiAssistantScreen> createState() => _AiAssistantScreenState();
}

class _AiAssistantScreenState extends ConsumerState<AiAssistantScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final _focusNode = FocusNode();
  bool _showNewChat = false;

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;
    _messageController.clear();
    ref.read(aiChatNotifierProvider.notifier).sendMessage(text);
    _scrollToBottom();
  }

  void _sendQuickReply(String text) {
    _messageController.text = text;
    _sendMessage();
  }

  @override
  Widget build(BuildContext context) {
    final consentAsync = ref.watch(aiChatConsentProvider);
    final chatState = ref.watch(aiChatNotifierProvider);
    final chatsAsync = ref.watch(aiChatsProvider);
    final l10n = AppLocalizations.of(context);
    final isDesktop = MediaQuery.sizeOf(context).width >= 1200;

    // Scroll to bottom when streaming text updates
    ref.listen(aiChatNotifierProvider, (prev, next) {
      if (next.isStreaming && next.streamingText != prev?.streamingText) {
        _scrollToBottom();
      }
      if (!next.isStreaming && (prev?.isStreaming ?? false)) {
        _scrollToBottom();
      }
    });

    // Show consent screen if not yet accepted
    final hasConsent = consentAsync.valueOrNull ?? false;
    if (!hasConsent && !consentAsync.isLoading) {
      return _buildConsentScreen(l10n);
    }

    if (isDesktop) {
      return _buildDesktopLayout(chatState, chatsAsync, l10n);
    }

    // Mobile: show either chat list or active chat
    if (chatState.currentChat != null ||
        chatState.isStreaming ||
        _showNewChat) {
      return _buildActiveChatView(chatState, l10n, showBackButton: true);
    }

    return _buildChatListView(chatState, chatsAsync, l10n);
  }

  // ---------------------------------------------------------------------------
  // Consent screen
  // ---------------------------------------------------------------------------

  Widget _buildConsentScreen(AppLocalizations l10n) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      drawer: const OwnerAppDrawer(currentRoute: 'ai-assistant'),
      appBar: CommonAppBar(
        title: l10n.aiAssistantTitle,
        leadingIcon: Icons.menu,
        onLeadingIconTap: (context) => Scaffold.of(context).openDrawer(),
      ),
      body: Container(
        decoration: BoxDecoration(gradient: context.gradients.pageBackground),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: ClipOval(
                      child: Image.asset(
                        'assets/images/assistant_illustration.png',
                        width: 48,
                        height: 48,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    l10n.aiAssistantTitle,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF2D2D2D)
                          : const Color(0xFFF5F5F5),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: AppShadows.getElevation(1, isDark: isDark),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildConsentItem(
                          Icons.psychology_outlined,
                          l10n.aiConsentProcessing,
                          theme,
                        ),
                        const SizedBox(height: 12),
                        _buildConsentItem(
                          Icons.history,
                          l10n.aiConsentStorage,
                          theme,
                        ),
                        const SizedBox(height: 12),
                        _buildConsentItem(
                          Icons.delete_outline,
                          l10n.aiConsentDeletion,
                          theme,
                        ),
                        const SizedBox(height: 12),
                        _buildConsentItem(
                          Icons.shield_outlined,
                          l10n.aiConsentPrivacy,
                          theme,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: 220,
                    child: ElevatedButton(
                      onPressed: _acceptConsent,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        foregroundColor: Colors.white,
                      ),
                      child: Text(l10n.aiConsentAccept),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    l10n.aiAssistantDisclaimer,
                    style: TextStyle(
                      fontSize: 11,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildConsentItem(IconData icon, String text, ThemeData theme) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: theme.colorScheme.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 14,
              height: 1.4,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _acceptConsent() async {
    final userId = ref.read(enhancedAuthProvider).firebaseUser?.uid;
    if (userId == null) return;

    await grantAiChatConsent(userId);
    ref.invalidate(aiChatConsentProvider);
  }

  // ---------------------------------------------------------------------------
  // Desktop: split view
  // ---------------------------------------------------------------------------

  Widget _buildDesktopLayout(
    AiChatState chatState,
    AsyncValue<List<AiChat>> chatsAsync,
    AppLocalizations l10n,
  ) {
    return Scaffold(
      drawer: const OwnerAppDrawer(currentRoute: 'ai-assistant'),
      appBar: CommonAppBar(
        title: l10n.aiAssistantTitle,
        leadingIcon: Icons.menu,
        onLeadingIconTap: (context) => Scaffold.of(context).openDrawer(),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: TextButton.icon(
              onPressed: () {
                ref.read(aiChatNotifierProvider.notifier).createNewChat();
              },
              icon: const Icon(Icons.add, color: Colors.white, size: 20),
              label: Text(
                l10n.aiAssistantNewChat,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: TextButton.styleFrom(
                backgroundColor: Colors.white.withValues(alpha: 0.15),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(gradient: context.gradients.pageBackground),
        child: Row(
          children: [
            // Left: chat list (desktop new chat opens in right panel)
            SizedBox(
              width: 320,
              child: _buildDesktopChatListContent(chatState, chatsAsync, l10n),
            ),
            VerticalDivider(width: 1, color: context.gradients.sectionBorder),
            // Right: active chat or welcome
            Expanded(child: _buildChatArea(chatState, l10n)),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Chat List View (mobile full screen)
  // ---------------------------------------------------------------------------

  Widget _buildChatListView(
    AiChatState chatState,
    AsyncValue<List<AiChat>> chatsAsync,
    AppLocalizations l10n,
  ) {
    return Scaffold(
      drawer: const OwnerAppDrawer(currentRoute: 'ai-assistant'),
      appBar: CommonAppBar(
        title: l10n.aiAssistantTitle,
        leadingIcon: Icons.menu,
        onLeadingIconTap: (context) => Scaffold.of(context).openDrawer(),
      ),
      body: Container(
        decoration: BoxDecoration(gradient: context.gradients.pageBackground),
        child: _buildChatListContent(chatState, chatsAsync, l10n),
      ),
    );
  }

  void _onNewChatPressed() {
    ref.read(aiChatNotifierProvider.notifier).createNewChat();
    setState(() => _showNewChat = true);
  }

  Widget _buildNewChatButton(AppLocalizations l10n) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        16,
        MediaQuery.paddingOf(context).bottom + 12,
      ),
      child: SizedBox(
        width: 200,
        child: ElevatedButton.icon(
          onPressed: _onNewChatPressed,
          icon: const Icon(Icons.chat_outlined, size: 18),
          label: Text(l10n.aiAssistantNewChat),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            foregroundColor: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildChatListContent(
    AiChatState chatState,
    AsyncValue<List<AiChat>> chatsAsync,
    AppLocalizations l10n,
  ) {
    final hasChats = chatsAsync.valueOrNull?.isNotEmpty ?? false;
    return Column(
      children: [
        // Chat list or empty state (empty state includes New Chat button)
        Expanded(
          child: chatsAsync.when(
            data: (chats) {
              if (chats.isEmpty) {
                return _buildEmptyState(l10n);
              }
              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(12, 16, 12, 0),
                itemCount: chats.length,
                itemBuilder: (context, index) =>
                    _buildChatListItem(chats[index], l10n),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, st) => _buildEmptyState(l10n),
          ),
        ),
        // New Chat button at bottom — only when chat list is shown
        if (hasChats) Center(child: _buildNewChatButton(l10n)),
      ],
    );
  }

  Widget _buildEmptyState(AppLocalizations l10n) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            'assets/images/assistant_illustration.png',
            width: 200,
            height: 200,
          ),
          const SizedBox(height: 24),
          Text(
            l10n.aiAssistantNoChats,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              l10n.aiAssistantWelcomeSubtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: 200,
            child: ElevatedButton.icon(
              onPressed: _onNewChatPressed,
              icon: const Icon(Icons.chat_outlined, size: 18),
              label: Text(l10n.aiAssistantNewChat),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Desktop variant — new chat just clears the right panel
  Widget _buildDesktopChatListContent(
    AiChatState chatState,
    AsyncValue<List<AiChat>> chatsAsync,
    AppLocalizations l10n,
  ) {
    final hasChats = chatsAsync.valueOrNull?.isNotEmpty ?? false;
    return Column(
      children: [
        Expanded(
          child: chatsAsync.when(
            data: (chats) {
              if (chats.isEmpty) {
                return _buildEmptyState(l10n);
              }
              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(12, 16, 12, 0),
                itemCount: chats.length,
                itemBuilder: (context, index) =>
                    _buildChatListItem(chats[index], l10n),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, st) => _buildEmptyState(l10n),
          ),
        ),
        if (hasChats)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: SizedBox(
                width: 200,
                child: ElevatedButton.icon(
                  onPressed: () {
                    ref.read(aiChatNotifierProvider.notifier).createNewChat();
                  },
                  icon: const Icon(Icons.chat_outlined, size: 18),
                  label: Text(l10n.aiAssistantNewChat),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildChatListItem(AiChat chat, AppLocalizations l10n) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isSelected =
        ref.read(aiChatNotifierProvider).currentChat?.id == chat.id;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Dismissible(
        key: ValueKey(chat.id),
        direction: DismissDirection.endToStart,
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          decoration: BoxDecoration(
            color: theme.colorScheme.error,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.delete, color: Colors.white),
        ),
        confirmDismiss: (_) async {
          return await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: Text(l10n.aiAssistantDeleteChat),
              content: Text(l10n.aiAssistantDeleteConfirm),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text(l10n.cancel),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: Text(l10n.delete),
                ),
              ],
            ),
          );
        },
        onDismissed: (_) {
          ref.read(aiChatNotifierProvider.notifier).deleteChat(chat.id);
        },
        child: Material(
          color: isSelected
              ? theme.colorScheme.primary.withValues(alpha: 0.08)
              : (isDark ? const Color(0xFF2D2D2D) : Colors.white),
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () {
              ref.read(aiChatNotifierProvider.notifier).loadChat(chat.id);
            },
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected
                      ? theme.colorScheme.primary.withValues(alpha: 0.3)
                      : (isDark
                            ? Colors.white.withValues(alpha: 0.06)
                            : Colors.black.withValues(alpha: 0.06)),
                ),
                boxShadow: AppShadows.getElevation(1, isDark: isDark),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isDark
                              ? const Color(0xFF2D2D2E)
                              : Colors.white,
                          border: Border.all(
                            color: theme.colorScheme.primary.withValues(
                              alpha: 0.2,
                            ),
                          ),
                        ),
                        child: ClipOval(
                          child: Image.asset(
                            'assets/images/assistant_illustration.png',
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          chat.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                      ),
                      Text(
                        _formatDate(chat.updatedAt),
                        style: TextStyle(
                          fontSize: 11,
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (chat.lastMessagePreview.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      chat.lastMessagePreview,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.6,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}d';
    return '${date.day}.${date.month}.';
  }

  // ---------------------------------------------------------------------------
  // Active Chat View (mobile full screen)
  // ---------------------------------------------------------------------------

  Widget _buildActiveChatView(
    AiChatState chatState,
    AppLocalizations l10n, {
    bool showBackButton = false,
  }) {
    return Scaffold(
      drawer: const OwnerAppDrawer(currentRoute: 'ai-assistant'),
      appBar: CommonAppBar(
        title: chatState.currentChat?.title ?? l10n.aiAssistantNewChat,
        leadingIcon: showBackButton ? Icons.arrow_back : Icons.menu,
        onLeadingIconTap: showBackButton
            ? (_) {
                ref.read(aiChatNotifierProvider.notifier).createNewChat();
                setState(() => _showNewChat = false);
              }
            : (context) => Scaffold.of(context).openDrawer(),
      ),
      body: Container(
        decoration: BoxDecoration(gradient: context.gradients.pageBackground),
        child: _buildChatArea(chatState, l10n),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Chat Area (messages + input bar)
  // ---------------------------------------------------------------------------

  Widget _buildChatArea(AiChatState chatState, AppLocalizations l10n) {
    final messages = chatState.currentChat?.messages ?? [];

    return Column(
      children: [
        // Messages
        Expanded(
          child: messages.isEmpty && !chatState.isStreaming
              ? _buildQuickReplies(chatState, l10n)
              : _buildMessageList(chatState, l10n),
        ),
        // Error banner
        if (chatState.error != null) _buildErrorBanner(chatState, l10n),
        // Input bar
        _buildInputBar(chatState, l10n),
      ],
    );
  }

  Widget _buildMessageList(AiChatState chatState, AppLocalizations l10n) {
    final messages = chatState.currentChat?.messages ?? [];

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      itemCount: messages.length + (chatState.isStreaming ? 1 : 0),
      itemBuilder: (context, index) {
        if (index < messages.length) {
          return _buildMessageBubble(messages[index]);
        }
        // Streaming message
        return _buildMessageBubble(
          AiChatMessage(
            role: 'assistant',
            content: chatState.streamingText.isEmpty
                ? '...'
                : chatState.streamingText,
            timestamp: DateTime.now(),
          ),
          isStreaming: true,
        );
      },
    );
  }

  Widget _buildMessageBubble(
    AiChatMessage message, {
    bool isStreaming = false,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isUser = message.isUser;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (!isUser) ...[
              Container(
                margin: const EdgeInsets.only(right: 8, bottom: 4),
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDark ? const Color(0xFF2D2D2E) : Colors.white,
                  border: Border.all(
                    color: theme.colorScheme.primary.withValues(alpha: 0.2),
                  ),
                ),
                child: ClipOval(
                  child: Image.asset(
                    'assets/images/assistant_illustration.png',
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ],
            Flexible(
              child: Container(
                constraints: BoxConstraints(
                  maxWidth:
                      MediaQuery.sizeOf(context).width * (isUser ? 0.8 : 0.72),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  gradient: isUser
                      ? LinearGradient(
                          colors: [
                            theme.colorScheme.primary,
                            theme.colorScheme.primary.withValues(alpha: 0.8),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : null,
                  color: isUser
                      ? null
                      : (isDark ? const Color(0xFF2D2D2E) : Colors.white),
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(20),
                    topRight: const Radius.circular(20),
                    bottomLeft: Radius.circular(isUser ? 20 : 4),
                    bottomRight: Radius.circular(isUser ? 4 : 20),
                  ),
                  border: !isUser
                      ? Border.all(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.05)
                              : Colors.black.withValues(alpha: 0.05),
                        )
                      : null,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(
                        alpha: isDark ? 0.2 : 0.05,
                      ),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: isUser
                    ? Text(
                        message.content,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          height: 1.4,
                        ),
                      )
                    : MarkdownBody(
                        data: message.content,
                        selectable: true,
                        styleSheet: MarkdownStyleSheet(
                          p: TextStyle(
                            color: theme.colorScheme.onSurface,
                            fontSize: 14,
                            height: 1.5,
                          ),
                          strong: TextStyle(
                            color: theme.colorScheme.onSurface,
                            fontWeight: FontWeight.w600,
                          ),
                          listBullet: TextStyle(
                            color: theme.colorScheme.onSurface,
                            fontSize: 14,
                          ),
                          code: TextStyle(
                            backgroundColor: isDark
                                ? const Color(0xFF1A1A1A)
                                : const Color(0xFFE8E8E8),
                            color: theme.colorScheme.onSurface,
                            fontSize: 13,
                          ),
                          h1: TextStyle(
                            color: theme.colorScheme.onSurface,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          h2: TextStyle(
                            color: theme.colorScheme.onSurface,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          h3: TextStyle(
                            color: theme.colorScheme.onSurface,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                          blockSpacing: 8,
                        ),
                        onTapLink: (text, href, title) {
                          if (href != null) {
                            launchUrl(
                              Uri.parse(href),
                              mode: LaunchMode.externalApplication,
                            );
                          }
                        },
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Quick reply chips + welcome
  // ---------------------------------------------------------------------------

  Widget _buildQuickReplies(AiChatState chatState, AppLocalizations l10n) {
    final theme = Theme.of(context);

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.lightbulb_outline,
              size: 32,
              color: theme.colorScheme.primary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 12),
            Text(
              l10n.aiAssistantSuggestions,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 16),
            _buildQuickChips(chatState, l10n),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickChips(AiChatState chatState, AppLocalizations l10n) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final chips = [
      l10n.aiAssistantChipAddUnit,
      l10n.aiAssistantChipPricing,
      l10n.aiAssistantChipStripe,
      l10n.aiAssistantChipIcal,
      l10n.aiAssistantChipEmbed,
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: chips.map((chip) {
        return ActionChip(
          label: Text(
            chip,
            style: TextStyle(fontSize: 13, color: theme.colorScheme.onSurface),
          ),
          backgroundColor: isDark
              ? const Color(0xFF2D2D2D)
              : const Color(0xFFF5F5F5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(
              color: theme.colorScheme.primary.withValues(alpha: 0.2),
            ),
          ),
          onPressed: chatState.isStreaming ? null : () => _sendQuickReply(chip),
        );
      }).toList(),
    );
  }

  // ---------------------------------------------------------------------------
  // Error banner
  // ---------------------------------------------------------------------------

  Widget _buildErrorBanner(AiChatState chatState, AppLocalizations l10n) {
    final theme = Theme.of(context);
    String message;
    if (chatState.error == 'daily_limit') {
      message = l10n.aiAssistantDailyLimit;
    } else if (chatState.error == 'ai_error') {
      message = l10n.aiAssistantAiError;
    } else {
      message = chatState.error ?? l10n.aiAssistantError;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: theme.colorScheme.error.withValues(alpha: 0.1),
      child: Text(
        message,
        style: TextStyle(fontSize: 13, color: theme.colorScheme.error),
        textAlign: TextAlign.center,
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Input bar
  // ---------------------------------------------------------------------------

  Widget _buildInputBar(AiChatState chatState, AppLocalizations l10n) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        16,
        MediaQuery.paddingOf(context).bottom + 16,
      ),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.1 : 0.02),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: _messageController,
                focusNode: _focusNode,
                enabled: !chatState.isStreaming,
                maxLines: 5,
                minLines: 1,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _sendMessage(),
                decoration: InputDecoration(
                  hintText: l10n.aiAssistantPlaceholder,
                  hintStyle: TextStyle(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                    fontSize: 14,
                  ),
                  filled: true,
                  fillColor: isDark
                      ? const Color(0xFF2D2D2E)
                      : const Color(0xFFF8F9FA),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide(
                      color: theme.colorScheme.primary.withValues(alpha: 0.3),
                    ),
                  ),
                ),
                style: TextStyle(
                  fontSize: 14,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: Container(
              height: 48,
              width: 48,
              decoration: BoxDecoration(
                gradient: chatState.isStreaming
                    ? null
                    : LinearGradient(
                        colors: [
                          theme.colorScheme.primary,
                          theme.colorScheme.primary.withValues(alpha: 0.8),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                color: chatState.isStreaming
                    ? theme.colorScheme.primary.withValues(alpha: 0.3)
                    : null,
                shape: BoxShape.circle,
                boxShadow: chatState.isStreaming
                    ? null
                    : [
                        BoxShadow(
                          color: theme.colorScheme.primary.withValues(
                            alpha: 0.3,
                          ),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
              ),
              child: IconButton(
                onPressed: chatState.isStreaming ? null : _sendMessage,
                icon: chatState.isStreaming
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white.withValues(alpha: 0.7),
                        ),
                      )
                    : const Icon(Icons.send_rounded, size: 22),
                color: Colors.white,
                splashRadius: 24,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
