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
import '../../../../../shared/widgets/redesign/bb_avatar.dart';
import '../../../../../shared/widgets/redesign/bb_skeleton.dart';
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
const double _kAvatar = 24; // assistant bubble avatar (handoff 24)
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
// Layout/responsive — ONE desktop breakpoint shared by the screen layout, the
// message-bubble max-width, and the premium header. audit/132 R1: below this,
// 768 folds COHERENTLY to mobile (no distinct tablet tier — accepted).
const double _kDesktopBp = 1200;
const double _kConsentBtnW = 220; // consent "Prihvati" button width
const double _kDesktopListW =
    300; // desktop split chat-list panel (handoff 300)
const double _kDividerW = 1; // desktop split hairline divider
const double _kTabletBp = 600; // suggestion-chip density tier (4/3/2) only
const int _kTypingDotCount = 3; // streaming typing indicator dot count
const double _kTypingDot = 6; // typing dot diameter
const double _kTypingDotGap = 3; // gap between typing dots

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
    final isDesktop = MediaQuery.sizeOf(context).width >= _kDesktopBp;

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
                    const _AiHeroIllustration(size: _kConsentIcon),
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
                      width: _kConsentBtnW,
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
                      width: _kDesktopListW,
                      child: _buildDesktopChatListContent(
                        chatState,
                        chatsAsync,
                        l10n,
                      ),
                    ),
                    VerticalDivider(
                      width: _kDividerW,
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
            loading: _buildChatListSkeleton,
            error: (e, st) => _buildEmptyState(l10n),
          ),
        ),
        // New Chat button at bottom — only when chat list is shown
        if (hasChats) Center(child: _buildNewChatButton(l10n)),
      ],
    );
  }

  /// Shimmer placeholder for the chat-list load state — replaces a bare
  /// spinner with chat-row skeletons (predictable layout, no jump-cut).
  Widget _buildChatListSkeleton() {
    final BBColorSet c = BBColor.of(context);
    return ListView(
      padding: const EdgeInsets.fromLTRB(_k12, BBSpace.sm, _k12, 0),
      children: <Widget>[
        for (int i = 0; i < 5; i++)
          Container(
            margin: const EdgeInsets.only(bottom: BBSpace.xs),
            padding: const EdgeInsets.all(_kBubblePadH),
            decoration: BoxDecoration(
              color: c.surface,
              borderRadius: BBRadius.smAll,
              border: Border.all(color: c.border),
            ),
            // Inline listRow shape on the redesign BbSkeleton (audit F1b —
            // core/widgets BBSkeleton is retired with the core bb_* dup set).
            child: const Row(
              children: <Widget>[
                BbSkeleton(width: 40, height: 40, radius: 20),
                SizedBox(width: BBSpace.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      BbSkeleton(width: 180, height: 14),
                      SizedBox(height: BBSpace.xs),
                      BbSkeleton(width: 120, height: 12),
                    ],
                  ),
                ),
              ],
            ),
          ),
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
            // Mascot hero with radial glow — shared with consent + quick-reply.
            const _AiHeroIllustration(),
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
            loading: _buildChatListSkeleton,
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

    // Owner identity for the user-bubble avatar (mirrors OwnerAppDrawer).
    final owner = ref.watch(enhancedAuthProvider).userModel;
    final String first = owner?.firstName.trim() ?? '';
    final String last = owner?.lastName.trim() ?? '';
    final String fullName = '$first $last'.trim();
    final String userName = fullName.isNotEmpty
        ? fullName
        : (owner?.displayName ?? '');
    final String? userAvatarUrl = owner?.avatarUrl;

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
          return buildAiMessageBubble(
            context,
            messages[index],
            typing: false,
            userName: userName,
            userAvatarUrl: userAvatarUrl,
          );
        }
        // Streaming bubble — animated typing dots until the first chunk lands,
        // then the streamed text replaces them. The streaming heartbeat
        // (provider copyWith → ref.listen → animateTo) is untouched; this only
        // swaps the render body of the in-flight assistant bubble.
        final bool waiting = chatState.streamingText.isEmpty;
        return buildAiMessageBubble(
          context,
          AiChatMessage(
            role: 'assistant',
            content: waiting ? '' : chatState.streamingText,
            timestamp: DateTime.now(),
          ),
          isStreaming: true,
          typing: waiting,
          userName: userName,
          userAvatarUrl: userAvatarUrl,
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
            const _AiHeroIllustration(size: _kConsentIcon),
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

    // Suggestion density per handoff: 4 desktop · 3 tablet-band · 2 mobile.
    // The layout still folds tablet→mobile (R1) — only the chip COUNT tiers.
    final double w = MediaQuery.sizeOf(context).width;
    final int count = w >= _kDesktopBp
        ? 4
        : w >= _kTabletBp
        ? 3
        : 2;
    final List<String> chips = <String>[
      l10n.aiAssistantChipAddUnit,
      l10n.aiAssistantChipPricing,
      l10n.aiAssistantChipStripe,
      l10n.aiAssistantChipIcal,
      l10n.aiAssistantChipEmbed,
    ].take(count).toList();

    return _StaggeredChips(
      children: <Widget>[
        for (final String chip in chips)
          ActionChip(
            avatar: Icon(
              Icons.auto_awesome,
              size: _kChipIcon,
              color: c.primary,
            ),
            label: Text(chip, style: BBType.label(context)),
            backgroundColor: c.surfaceVariant,
            shape: RoundedRectangleBorder(
              borderRadius: BBRadius.mdAll,
              side: BorderSide(color: c.primary.withValues(alpha: 0.2)),
            ),
            onPressed: chatState.isStreaming
                ? null
                : () => _sendQuickReply(chip),
          ),
      ],
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
                    minLines: MediaQuery.sizeOf(context).width >= _kDesktopBp
                        ? 2
                        : 1,
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

/// Single chat bubble — user = solid `primary` (right) with an initials
/// avatar, assistant = `surface` + border (left) with the brand avatar.
/// Mirrors `ai-assistant.jsx` bubbles (tail corner [BBRadius.xs], 24px avatar,
/// 11px timestamp, max-width 70/78%). [typing] swaps the body for an animated
/// typing indicator; [userName]/[userAvatarUrl] feed the user-side avatar.
/// Top-level + [visibleForTesting] so the overflow golden can pump it without
/// the full screen / providers.
@visibleForTesting
Widget buildAiMessageBubble(
  BuildContext context,
  AiChatMessage message, {
  // Required (not optional) so a call site that forgets to wire them is a
  // COMPILE error, not a silent live failure — the full-screen pump that would
  // otherwise test the wiring is blocked by provider StateNotifiers (audit/132).
  required bool typing,
  required String? userName,
  required String? userAvatarUrl,
  bool isStreaming = false,
}) {
  final BBColorSet c = BBColor.of(context);
  final bool isUser = message.isUser;
  final bool isMobileWidth = MediaQuery.sizeOf(context).width < 600;
  final double maxW =
      MediaQuery.sizeOf(context).width *
      (isMobileWidth ? _kUserMaxW : _kUserMaxWDesktop);

  final Widget content = typing
      ? const _TypingDots()
      : isUser
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
          if (isUser) ...[
            const SizedBox(width: BBSpace.xs),
            BbAvatar(
              name: userName ?? '',
              imageUrl: userAvatarUrl,
              size: BbAvatarSize.xs,
            ),
          ],
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
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
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
        tooltip: AppLocalizations.of(context).sendMessage,
        icon: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          transitionBuilder: (Widget child, Animation<double> anim) =>
              FadeTransition(
                opacity: anim,
                child: ScaleTransition(scale: anim, child: child),
              ),
          child: streaming
              ? const SizedBox(
                  key: ValueKey<String>('streaming'),
                  width: _kSendIcon,
                  height: _kSendIcon,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: _kOnPrimaryMuted,
                  ),
                )
              : const Icon(Icons.send_rounded, key: ValueKey<String>('idle')),
        ),
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

/// Mascot illustration with the handoff radial-glow halo + asset-fail fallback.
/// Shared by the empty-state, consent, and quick-reply heroes so all three
/// carry the same glowing hero (handoff `ai-assistant.jsx` consent/empty hero).
/// Wrapped in [ExcludeSemantics] — decorative illustration; surrounding text
/// provides the accessible description.
class _AiHeroIllustration extends StatelessWidget {
  const _AiHeroIllustration({this.size = _kEmptyIllustration});

  final double size;

  @override
  Widget build(BuildContext context) {
    final BBColorSet c = BBColor.of(context);
    return ExcludeSemantics(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          gradient: RadialGradient(
            radius: 0.7,
            colors: <Color>[
              c.primary.withValues(alpha: 0.32),
              c.primary.withValues(alpha: 0.0),
            ],
          ),
        ),
        child: Image.asset(
          'assets/images/assistant_illustration.png',
          fit: BoxFit.contain,
          errorBuilder: (_, _, _) =>
              Icon(Icons.auto_awesome, size: size * 0.5, color: c.primary),
        ),
      ),
    );
  }
}

/// Animated three-dot "typing" indicator shown in the assistant bubble while
/// awaiting the first streamed chunk (premium replacement for the static
/// '...'). ADDITIVE motion only — never touches the streaming pipeline
/// (copyWith → ref.listen → animateTo). Reduced-motion → static glyph.
class _TypingDots extends StatefulWidget {
  const _TypingDots();

  @override
  State<_TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<_TypingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final BBColorSet c = BBColor.of(context);
    if (BBMotion.reduced(context)) {
      return Text(
        '…',
        style: BBType.body(context).copyWith(color: c.textTertiary),
      );
    }
    return SizedBox(
      height: BBType.body(context).fontSize,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          for (int i = 0; i < _kTypingDotCount; i++) ...<Widget>[
            if (i > 0) const SizedBox(width: _kTypingDotGap),
            _dot(i, c.textTertiary),
          ],
        ],
      ),
    );
  }

  Widget _dot(int index, Color color) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (BuildContext _, Widget? _) {
        final double phase = (_ctrl.value + index * 0.18) % 1.0;
        // Triangle wave 0→1→0 → gentle per-dot opacity pulse.
        final double t = (1.0 - (phase * 2.0 - 1.0).abs()).clamp(0.0, 1.0);
        return Opacity(
          opacity: 0.35 + 0.65 * t,
          child: Container(
            width: _kTypingDot,
            height: _kTypingDot,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
        );
      },
    );
  }
}

/// Wraps suggestion chips in a Wrap with a subtle staggered fade+rise on first
/// mount (forward-once — no repeating ticker). Reduced-motion → plain Wrap.
class _StaggeredChips extends StatefulWidget {
  const _StaggeredChips({required this.children});

  final List<Widget> children;

  @override
  State<_StaggeredChips> createState() => _StaggeredChipsState();
}

class _StaggeredChipsState extends State<_StaggeredChips>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    )..forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool reduced = BBMotion.reduced(context);
    final int n = widget.children.length;
    return Wrap(
      spacing: BBSpace.xs,
      runSpacing: BBSpace.xs,
      alignment: WrapAlignment.center,
      children: <Widget>[
        for (int i = 0; i < n; i++)
          if (reduced) widget.children[i] else _staggerItem(i, n),
      ],
    );
  }

  Widget _staggerItem(int i, int n) {
    final double start = n <= 1 ? 0.0 : (i / n) * 0.5;
    final Animation<double> anim = CurvedAnimation(
      parent: _ctrl,
      curve: Interval(
        start,
        (start + 0.5).clamp(0.0, 1.0),
        curve: Curves.easeOut,
      ),
    );
    return FadeTransition(
      opacity: anim,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.18),
          end: Offset.zero,
        ).animate(anim),
        child: widget.children[i],
      ),
    );
  }
}
