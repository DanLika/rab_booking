import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../../core/config/router_owner.dart';
import '../../../../../core/design/tokens.dart';
import '../../../../../core/theme/gradient_extensions.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../../core/providers/enhanced_auth_provider.dart';
import '../../../../../shared/widgets/common_app_bar.dart';
import '../../../../../shared/widgets/redesign/bb_dialog.dart';
import '../../providers/ai_chat_provider.dart';
import '../../widgets/guides/ai_assistant_premium_header.dart';
import '../../widgets/owner_app_drawer.dart';
import '../../../domain/models/ai_chat.dart';

// ── AI chat metrics — off-8px-grid values sourced from
// `design_handoff/source/ai-assistant.jsx`. Token-first (BBSpace/BBRadius/
// BBType/BBColor/BBShadow); these named consts cover the handoff's off-scale
// primitives so the file carries 0 raw colour/size literals.
const double _kBubblePadH = 14; // handoff bubble padding 12×14
const double _kBubblePadV = 12;
const double _kMsgGap = 14; // gap between message rows
const double _k12 = 12; // handoff 12px gap/pad (off the BBSpace 8px scale)
const double _kAvatar = 32; // assistant bubble avatar (handoff 32)
const double _kAvatarSm = 20; // chat-list-item mini avatar
const double _kTile = 36; // consent/feature icon tile
const double _kTileIcon = 20; // glyph inside a 36px tile
const double _kBtnIcon = 18; // leading glyph on the New-Chat button
const double _kChipIcon = 16; // auto_awesome glyph on suggestion chips
const double _kConsentIcon = 96; // consent hero glyph
const double _kEmptyIllustration = 200; // empty-state illustration
const double _kTimeSize = 11; // timestamp font (handoff 11)
const double _kSendBtn = 44; // composer send button (handoff md icon button)
const double _kSendIcon = 20; // send glyph / streaming spinner
const double _kNewChatBtnW = 200; // New-Chat CTA width
const double _kUserMaxW = 0.78; // bubble max-width factor (mobile)
const double _kUserMaxWDesktop = 0.70; // bubble max-width factor (desktop)
const Color _kOnPrimary = Colors.white; // text/icon on primary fill
const Color _kOnPrimaryMuted = Colors.white70; // muted on-primary (timestamps)

String _formatBubbleTime(DateTime t) {
  final String h = t.hour.toString().padLeft(2, '0');
  final String m = t.minute.toString().padLeft(2, '0');
  return '$h:$m';
}

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
    final BBColorSet c = BBColor.of(context);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) context.go(OwnerRoutes.overview);
      },
      child: Scaffold(
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
              padding: const EdgeInsets.all(BBSpace.md),
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: BBConstraint.maxWidgetWidth,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const AiBrandAvatar(size: _kConsentIcon),
                    const SizedBox(height: BBSpace.sm),
                    Text(
                      'BOOKBED AI',
                      style: BBType.eyebrow(context).copyWith(color: c.primary),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: BBSpace.xxs),
                    Text(
                      l10n.aiAssistantTitle,
                      style: BBType.h2(context),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: BBSpace.xs),
                    Text(
                      l10n.aiAssistantWelcomeSubtitle,
                      style: BBType.body(
                        context,
                      ).copyWith(color: c.textSecondary),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: BBSpace.md),
                    Container(
                      padding: const EdgeInsets.all(BBSpace.sm),
                      decoration: BoxDecoration(
                        color: c.surface,
                        borderRadius: BBRadius.smAll,
                        border: Border.all(color: c.border),
                        boxShadow: BBShadow.resting(context),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildConsentItem(
                            Icons.psychology_outlined,
                            l10n.aiConsentProcessing,
                          ),
                          const SizedBox(height: BBSpace.sm),
                          _buildConsentItem(
                            Icons.history,
                            l10n.aiConsentStorage,
                          ),
                          const SizedBox(height: BBSpace.sm),
                          _buildConsentItem(
                            Icons.delete_outline,
                            l10n.aiConsentDeletion,
                          ),
                          const SizedBox(height: BBSpace.sm),
                          _buildConsentItem(
                            Icons.shield_outlined,
                            l10n.aiConsentPrivacy,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: BBSpace.md),
                    SizedBox(
                      width: 220,
                      child: ElevatedButton(
                        onPressed: _acceptConsent,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: _k12),
                          shape: const RoundedRectangleBorder(
                            borderRadius: BBRadius.smAll,
                          ),
                          foregroundColor: _kOnPrimary,
                        ),
                        child: Text(l10n.aiConsentAccept),
                      ),
                    ),
                    const SizedBox(height: BBSpace.xs),
                    Text(
                      l10n.aiAssistantDisclaimer,
                      style: BBType.caption(
                        context,
                      ).copyWith(color: c.textTertiary),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildConsentItem(IconData icon, String text) {
    final BBColorSet c = BBColor.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: _kTile,
          height: _kTile,
          decoration: BoxDecoration(
            color: c.primary.withValues(alpha: 0.10),
            borderRadius: BBRadius.smAll,
          ),
          child: Icon(icon, size: _kTileIcon, color: c.primary),
        ),
        const SizedBox(width: _k12),
        Expanded(
          child: Text(
            text,
            style: BBType.body(context).copyWith(color: c.textSecondary),
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
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) context.go(OwnerRoutes.overview);
      },
      child: Scaffold(
        drawer: const OwnerAppDrawer(currentRoute: 'ai-assistant'),
        appBar: CommonAppBar(
          title: l10n.aiAssistantTitle,
          showTitle: false,
          leadingIcon: Icons.menu,
          onLeadingIconTap: (context) => Scaffold.of(context).openDrawer(),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: BBSpace.sm),
              child: TextButton.icon(
                onPressed: () {
                  ref.read(aiChatNotifierProvider.notifier).createNewChat();
                },
                icon: const Icon(Icons.add, size: _kTileIcon),
                label: Text(
                  l10n.aiAssistantNewChat,
                  style: BBType.label(context),
                ),
                style: TextButton.styleFrom(
                  foregroundColor: BBColor.of(context).primary,
                  backgroundColor: BBColor.of(
                    context,
                  ).primary.withValues(alpha: 0.10),
                  padding: const EdgeInsets.symmetric(
                    horizontal: BBSpace.sm,
                    vertical: BBSpace.xs,
                  ),
                  shape: const RoundedRectangleBorder(
                    borderRadius: BBRadius.mdAll,
                  ),
                ),
              ),
            ),
          ],
        ),
        body: Container(
          decoration: BoxDecoration(gradient: context.gradients.pageBackground),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  BBSpace.md,
                  BBSpace.sm,
                  BBSpace.md,
                  BBSpace.xs,
                ),
                child: AiAssistantPremiumHeader(title: l10n.aiAssistantTitle),
              ),
              Expanded(
                child: Row(
                  children: [
                    // Left: chat list (desktop new chat opens in right panel)
                    SizedBox(
                      width: 320,
                      child: _buildDesktopChatListContent(
                        chatState,
                        chatsAsync,
                        l10n,
                      ),
                    ),
                    VerticalDivider(
                      width: 1,
                      color: context.gradients.sectionBorder,
                    ),
                    // Right: active chat or welcome
                    Expanded(child: _buildChatArea(chatState, l10n)),
                  ],
                ),
              ),
            ],
          ),
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
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) context.go(OwnerRoutes.overview);
      },
      child: Scaffold(
        drawer: const OwnerAppDrawer(currentRoute: 'ai-assistant'),
        appBar: CommonAppBar(
          title: l10n.aiAssistantTitle,
          showTitle: false,
          leadingIcon: Icons.menu,
          onLeadingIconTap: (context) => Scaffold.of(context).openDrawer(),
        ),
        body: Container(
          decoration: BoxDecoration(gradient: context.gradients.pageBackground),
          child: _buildChatListContent(chatState, chatsAsync, l10n),
        ),
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
        BBSpace.sm,
        _k12,
        BBSpace.sm,
        MediaQuery.paddingOf(context).bottom + _k12,
      ),
      child: _NewChatButton(
        label: l10n.aiAssistantNewChat,
        onPressed: _onNewChatPressed,
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
        Padding(
          padding: const EdgeInsets.fromLTRB(
            BBSpace.sm,
            BBSpace.sm,
            BBSpace.sm,
            BBSpace.xs,
          ),
          child: AiAssistantPremiumHeader(title: l10n.aiAssistantTitle),
        ),
        // Chat list or empty state (empty state includes New Chat button)
        Expanded(
          child: chatsAsync.when(
            data: (chats) {
              if (chats.isEmpty) {
                return _buildEmptyState(l10n);
              }
              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(_k12, BBSpace.sm, _k12, 0),
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
    final BBColorSet c = BBColor.of(context);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(BBSpace.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Radial primary backdrop behind the illustration (handoff hero).
            Container(
              width: _kEmptyIllustration,
              height: _kEmptyIllustration,
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  radius: 0.7,
                  colors: [
                    c.primary.withValues(alpha: 0.32),
                    c.primary.withValues(alpha: 0.0),
                  ],
                ),
              ),
              child: Image.asset(
                'assets/images/assistant_illustration.png',
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) => Icon(
                  Icons.auto_awesome,
                  size: _kEmptyIllustration * 0.5,
                  color: c.primary,
                ),
              ),
            ),
            const SizedBox(height: BBSpace.md),
            Text(
              'BOOKBED AI',
              style: BBType.eyebrow(context).copyWith(color: c.primary),
            ),
            const SizedBox(height: BBSpace.xxs),
            Text(
              l10n.aiAssistantWelcome,
              style: BBType.h2(context),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: BBSpace.xs),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: BBSpace.lg),
              child: Text(
                l10n.aiAssistantWelcomeSubtitle,
                textAlign: TextAlign.center,
                style: BBType.body(context).copyWith(color: c.textSecondary),
              ),
            ),
            const SizedBox(height: BBSpace.md),
            _NewChatButton(
              label: l10n.aiAssistantNewChat,
              onPressed: _onNewChatPressed,
            ),
          ],
        ),
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
                padding: const EdgeInsets.fromLTRB(_k12, BBSpace.sm, _k12, 0),
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
              padding: const EdgeInsets.all(_k12),
              child: _NewChatButton(
                label: l10n.aiAssistantNewChat,
                onPressed: () {
                  ref.read(aiChatNotifierProvider.notifier).createNewChat();
                },
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildChatListItem(AiChat chat, AppLocalizations l10n) {
    final BBColorSet c = BBColor.of(context);
    final bool isSelected =
        ref.read(aiChatNotifierProvider).currentChat?.id == chat.id;

    return Padding(
      padding: const EdgeInsets.only(bottom: BBSpace.xs),
      child: Dismissible(
        key: ValueKey(chat.id),
        direction: DismissDirection.endToStart,
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: BBSpace.sm),
          decoration: const BoxDecoration(
            color: BBColor.error,
            borderRadius: BBRadius.smAll,
          ),
          child: const Icon(Icons.delete, color: _kOnPrimary),
        ),
        confirmDismiss: (_) async => await _showDeleteChatDialog(l10n) ?? false,
        onDismissed: (_) {
          ref.read(aiChatNotifierProvider.notifier).deleteChat(chat.id);
        },
        child: Material(
          color: isSelected ? c.primary.withValues(alpha: 0.08) : c.surface,
          borderRadius: BBRadius.smAll,
          child: InkWell(
            borderRadius: BBRadius.smAll,
            onTap: () {
              ref.read(aiChatNotifierProvider.notifier).loadChat(chat.id);
            },
            child: Container(
              padding: const EdgeInsets.all(_kBubblePadH),
              decoration: BoxDecoration(
                borderRadius: BBRadius.smAll,
                border: Border.all(
                  color: isSelected
                      ? c.primary.withValues(alpha: 0.3)
                      : c.border,
                ),
                boxShadow: BBShadow.resting(context),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const AiBrandAvatar(size: _kAvatarSm),
                      const SizedBox(width: BBSpace.xs),
                      Expanded(
                        child: Text(
                          chat.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: BBType.body(
                            context,
                          ).copyWith(fontWeight: FontWeight.w600),
                        ),
                      ),
                      Text(
                        _formatDate(chat.updatedAt),
                        style: BBType.caption(
                          context,
                        ).copyWith(fontSize: _kTimeSize, color: c.textTertiary),
                      ),
                    ],
                  ),
                  if (chat.lastMessagePreview.isNotEmpty) ...[
                    const SizedBox(height: BBSpace.xxs),
                    Text(
                      chat.lastMessagePreview,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: BBType.label(context).copyWith(
                        fontWeight: FontWeight.w400,
                        color: c.textSecondary,
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
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          if (showBackButton) {
            // Go back to chat list
            ref.read(aiChatNotifierProvider.notifier).createNewChat();
            setState(() => _showNewChat = false);
          } else {
            // Go to dashboard
            context.go(OwnerRoutes.overview);
          }
        }
      },
      child: Scaffold(
        drawer: const OwnerAppDrawer(currentRoute: 'ai-assistant'),
        appBar: CommonAppBar(
          title: chatState.currentChat?.title ?? l10n.aiAssistantNewChat,
          showTitle: false,
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
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Chat Area (messages + input bar)
  // ---------------------------------------------------------------------------

  Widget _buildChatArea(AiChatState chatState, AppLocalizations l10n) {
    final messages = chatState.currentChat?.messages ?? [];
    final bool showConversationHeader =
        chatState.currentChat != null || chatState.isStreaming;
    final bool canCopy = messages.any(
      (m) => m.isAssistant && m.content.trim().isNotEmpty,
    );

    return Column(
      children: [
        // Per-conversation header (brand avatar + title + status + actions).
        // CommonAppBar carries showTitle:false so this is the only title.
        if (showConversationHeader)
          AiConversationHeader(
            title: chatState.currentChat?.title ?? l10n.aiAssistantNewChat,
            copyTooltip: l10n.aiAssistantCopyLast,
            deleteTooltip: l10n.aiAssistantDeleteChat,
            onCopy: canCopy
                ? () => _copyLastAssistantMessage(chatState, l10n)
                : null,
            onDelete: chatState.currentChat != null
                ? () => _confirmDeleteCurrentChat(chatState, l10n)
                : null,
          ),
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
      padding: const EdgeInsets.fromLTRB(
        BBSpace.sm,
        BBSpace.sm,
        BBSpace.sm,
        BBSpace.xs,
      ),
      itemCount: messages.length + (chatState.isStreaming ? 1 : 0),
      itemBuilder: (context, index) {
        if (index < messages.length) {
          return buildAiMessageBubble(context, messages[index]);
        }
        // Streaming message
        return buildAiMessageBubble(
          context,
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

  // ---------------------------------------------------------------------------
  // Quick reply chips + welcome
  // ---------------------------------------------------------------------------

  Widget _buildQuickReplies(AiChatState chatState, AppLocalizations l10n) {
    final BBColorSet c = BBColor.of(context);

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(BBSpace.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const AiBrandAvatar(size: _kConsentIcon),
            const SizedBox(height: BBSpace.sm),
            Text(
              l10n.aiAssistantWelcome,
              style: BBType.h3(context),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: BBSpace.xs),
            Text(
              l10n.aiAssistantSuggestions,
              style: BBType.caption(context).copyWith(color: c.textTertiary),
            ),
            const SizedBox(height: BBSpace.sm),
            _buildQuickChips(chatState, l10n),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickChips(AiChatState chatState, AppLocalizations l10n) {
    final BBColorSet c = BBColor.of(context);

    final chips = [
      l10n.aiAssistantChipAddUnit,
      l10n.aiAssistantChipPricing,
      l10n.aiAssistantChipStripe,
      l10n.aiAssistantChipIcal,
      l10n.aiAssistantChipEmbed,
    ];

    return Wrap(
      spacing: BBSpace.xs,
      runSpacing: BBSpace.xs,
      alignment: WrapAlignment.center,
      children: chips.map((chip) {
        return ActionChip(
          avatar: Icon(Icons.auto_awesome, size: _kChipIcon, color: c.primary),
          label: Text(chip, style: BBType.label(context)),
          backgroundColor: c.surfaceVariant,
          shape: RoundedRectangleBorder(
            borderRadius: BBRadius.mdAll,
            side: BorderSide(color: c.primary.withValues(alpha: 0.2)),
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
    final BBColorSet c = BBColor.of(context);
    String message;
    if (chatState.error == 'daily_limit') {
      message = l10n.aiAssistantDailyLimit;
    } else if (chatState.error == 'ai_unavailable') {
      message = l10n.aiAssistantUnavailable;
    } else if (chatState.error == 'ai_error') {
      message = l10n.aiAssistantAiError;
    } else {
      // Unknown sentinel — never display raw exception text.
      message = l10n.aiAssistantError;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: BBSpace.sm,
        vertical: _k12,
      ),
      color: c.error.withValues(alpha: 0.1),
      child: Text(
        message,
        style: BBType.label(
          context,
        ).copyWith(fontWeight: FontWeight.w400, color: c.error),
        textAlign: TextAlign.center,
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Input bar
  // ---------------------------------------------------------------------------

  Widget _buildInputBar(AiChatState chatState, AppLocalizations l10n) {
    final BBColorSet c = BBColor.of(context);

    return Container(
      padding: EdgeInsets.fromLTRB(
        BBSpace.sm,
        _k12,
        BBSpace.sm,
        MediaQuery.paddingOf(context).bottom + BBSpace.sm,
      ),
      decoration: BoxDecoration(
        color: c.surface,
        border: Border(top: BorderSide(color: c.border)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Bordered composer pill: transparent field + send button.
          Container(
            padding: const EdgeInsets.fromLTRB(
              BBSpace.sm,
              BBSpace.xxs,
              BBSpace.xxs,
              BBSpace.xxs,
            ),
            decoration: BoxDecoration(
              color: c.surface,
              borderRadius: BBRadius.mdAll,
              border: Border.all(color: c.border),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    focusNode: _focusNode,
                    enabled: !chatState.isStreaming,
                    maxLines: 5,
                    minLines: 1,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendMessage(),
                    style: BBType.body(context),
                    decoration: InputDecoration(
                      isCollapsed: true,
                      hintText: l10n.aiAssistantPlaceholder,
                      hintStyle: BBType.body(
                        context,
                      ).copyWith(color: c.textTertiary),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: _k12,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: BBSpace.xs),
                _SendButton(
                  streaming: chatState.isStreaming,
                  onSend: _sendMessage,
                ),
              ],
            ),
          ),
          const SizedBox(height: BBSpace.xs),
          // Orientation disclaimer (handoff composer footer).
          Text(
            l10n.aiAssistantDisclaimer,
            textAlign: TextAlign.center,
            style: BBType.caption(context).copyWith(color: c.textTertiary),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Conversation actions (copy / delete)
  // ---------------------------------------------------------------------------

  Future<bool?> _showDeleteChatDialog(AppLocalizations l10n) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => BbDialog(
        title: l10n.aiAssistantDeleteChat,
        body: l10n.aiAssistantDeleteConfirm,
        destructive: true,
        secondary: BbDialogAction(
          label: l10n.cancel,
          onPressed: () => Navigator.pop(ctx, false),
        ),
        primary: BbDialogAction(
          label: l10n.delete,
          onPressed: () => Navigator.pop(ctx, true),
        ),
      ),
    );
  }

  void _copyLastAssistantMessage(AiChatState chatState, AppLocalizations l10n) {
    final messages = chatState.currentChat?.messages ?? const <AiChatMessage>[];
    final assistantMessages = messages
        .where((m) => m.isAssistant && m.content.trim().isNotEmpty)
        .toList();
    if (assistantMessages.isEmpty) return;
    Clipboard.setData(ClipboardData(text: assistantMessages.last.content));
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(l10n.aiAssistantMessageCopied)));
  }

  Future<void> _confirmDeleteCurrentChat(
    AiChatState chatState,
    AppLocalizations l10n,
  ) async {
    final chat = chatState.currentChat;
    if (chat == null) return;
    final bool? confirmed = await _showDeleteChatDialog(l10n);
    if (confirmed != true || !mounted) return;
    final notifier = ref.read(aiChatNotifierProvider.notifier);
    await notifier.deleteChat(chat.id);
    if (!mounted) return;
    // Return to the chat list (clears the active session / desktop right panel).
    await notifier.createNewChat();
    if (mounted) setState(() => _showNewChat = false);
  }
}

/// Single chat bubble — user = solid `primary` (right), assistant = `surface`
/// + border (left) with brand avatar. Mirrors `ai-assistant.jsx` bubbles
/// (tail corner [BBRadius.xs], 32px avatar, 11px timestamp, max-width 70/78%).
/// Top-level + [visibleForTesting] so the overflow golden can pump it without
/// the full screen / providers.
@visibleForTesting
Widget buildAiMessageBubble(
  BuildContext context,
  AiChatMessage message, {
  bool isStreaming = false,
}) {
  final BBColorSet c = BBColor.of(context);
  final bool isUser = message.isUser;
  final bool isMobileWidth = MediaQuery.sizeOf(context).width < 600;
  final double maxW =
      MediaQuery.sizeOf(context).width *
      (isMobileWidth ? _kUserMaxW : _kUserMaxWDesktop);

  final Widget content = isUser
      ? Text(
          message.content,
          style: BBType.body(context).copyWith(color: _kOnPrimary),
        )
      : MarkdownBody(
          data: message.content,
          selectable: true,
          styleSheet: MarkdownStyleSheet(
            p: BBType.body(context),
            strong: BBType.body(context).copyWith(fontWeight: FontWeight.w600),
            listBullet: BBType.body(context),
            code: BBType.mono(
              context,
            ).copyWith(backgroundColor: c.surfaceVariant),
            h1: BBType.h3(context),
            h2: BBType.bodyLg(context).copyWith(fontWeight: FontWeight.w600),
            h3: BBType.body(context).copyWith(fontWeight: FontWeight.w600),
            blockSpacing: BBSpace.xs,
          ),
          onTapLink: (text, href, title) {
            // F-NEW-03: scheme allowlist. Gemini-streamed markdown can contain
            // arbitrary URLs (prompt injection, model hallucination, RAG-
            // poisoned KB). Only http(s) are safe for
            // `launchUrl(LaunchMode.externalApplication)` — custom schemes
            // (bookbed://, intent://, mailto:, tel:, sms:, data:) hand the URI
            // to OS app handlers and become a deep-link injection surface for
            // any installed app.
            if (href == null) return;
            final Uri? uri = Uri.tryParse(href);
            if (uri == null) return;
            if (uri.scheme != 'http' && uri.scheme != 'https') {
              return;
            }
            launchUrl(uri, mode: LaunchMode.externalApplication);
          },
        );

  final Widget bubble = Container(
    constraints: BoxConstraints(maxWidth: maxW),
    padding: const EdgeInsets.symmetric(
      horizontal: _kBubblePadH,
      vertical: _kBubblePadV,
    ),
    decoration: BoxDecoration(
      color: isUser ? c.primary : c.surface,
      borderRadius: BorderRadius.only(
        topLeft: Radius.circular(isUser ? BBRadius.md : BBRadius.xs),
        topRight: Radius.circular(isUser ? BBRadius.xs : BBRadius.md),
        bottomLeft: const Radius.circular(BBRadius.md),
        bottomRight: const Radius.circular(BBRadius.md),
      ),
      border: isUser ? null : Border.all(color: c.border),
      boxShadow: BBShadow.resting(context),
    ),
    child: Column(
      crossAxisAlignment: isUser
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        content,
        if (!isStreaming) ...[
          const SizedBox(height: BBSpace.xxs),
          Text(
            _formatBubbleTime(message.timestamp),
            style: BBType.caption(context).copyWith(
              fontSize: _kTimeSize,
              color: isUser ? _kOnPrimaryMuted : c.textTertiary,
            ),
          ),
        ],
      ],
    ),
  );

  return Align(
    alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
    child: Padding(
      padding: const EdgeInsets.only(bottom: _kMsgGap),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            const AiBrandAvatar(size: _kAvatar),
            const SizedBox(width: BBSpace.xs),
          ],
          Flexible(child: bubble),
        ],
      ),
    ),
  );
}

/// Solid-primary circular send button (handoff composer). Streaming → dimmed
/// with a spinner.
class _SendButton extends StatelessWidget {
  const _SendButton({required this.streaming, required this.onSend});

  final bool streaming;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    final BBColorSet c = BBColor.of(context);
    return Container(
      width: _kSendBtn,
      height: _kSendBtn,
      decoration: BoxDecoration(
        color: streaming ? c.primary.withValues(alpha: 0.3) : c.primary,
        shape: BoxShape.circle,
      ),
      child: IconButton(
        onPressed: streaming ? null : onSend,
        padding: EdgeInsets.zero,
        color: _kOnPrimary,
        iconSize: _kSendIcon,
        icon: streaming
            ? const SizedBox(
                width: _kSendIcon,
                height: _kSendIcon,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: _kOnPrimaryMuted,
                ),
              )
            : const Icon(Icons.send_rounded),
      ),
    );
  }
}

/// Shared New-Chat CTA (primary filled). Used by the empty state + chat-list
/// footers.
class _NewChatButton extends StatelessWidget {
  const _NewChatButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: _kNewChatBtnW,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: const Icon(Icons.chat_outlined, size: _kBtnIcon),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: _k12),
          shape: const RoundedRectangleBorder(borderRadius: BBRadius.smAll),
          foregroundColor: _kOnPrimary,
        ),
      ),
    );
  }
}
