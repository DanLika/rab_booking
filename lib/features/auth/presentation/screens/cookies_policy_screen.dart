import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/config/router_owner.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/common_app_bar.dart';
import '../../../../core/design/bb_redesign_tokens.dart';
import '../../../../core/design/tokens.dart';
import '../../../../shared/widgets/redesign.dart';

class CookiesPolicyScreen extends StatefulWidget {
  const CookiesPolicyScreen({super.key});

  @override
  State<CookiesPolicyScreen> createState() => _CookiesPolicyScreenState();
}

class _CookiesPolicyScreenState extends State<CookiesPolicyScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _showScrollToTop = false;

  final Map<String, GlobalKey> _sectionKeys = {
    'what': GlobalKey(),
    'how': GlobalKey(),
    'types': GlobalKey(),
    'choices': GlobalKey(),
    'thirdparty': GlobalKey(),
    'updates': GlobalKey(),
    'more': GlobalKey(),
  };

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.offset > 300 && !_showScrollToTop) {
      setState(() => _showScrollToTop = true);
    } else if (_scrollController.offset <= 300 && _showScrollToTop) {
      setState(() => _showScrollToTop = false);
    }
  }

  void _scrollToSection(String key) {
    final ctx = _sectionKeys[key]?.currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }

  void _scrollToTop() {
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final rd = BbRedesignTokens.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final horizontalPadding = isMobile
        ? 16.0
        : screenWidth < 900
        ? 24.0
        : 32.0;
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: rd.shellBg,
      appBar: CommonAppBar(
        title: l10n.cookiesScreenTitle,
        leadingIcon: Icons.arrow_back,
        onLeadingIconTap: (context) {
          if (context.canPop()) {
            context.pop();
          } else {
            context.go('/owner/profile');
          }
        },
      ),
      body: SafeArea(
        child: Stack(
          alignment:
              Alignment.topLeft, // Explicit to avoid TextDirection null check
          children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1200),
                child: SingleChildScrollView(
                  controller: _scrollController,
                  padding: EdgeInsets.symmetric(
                    horizontal: horizontalPadding,
                    vertical: isMobile ? 16 : 24,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _LegalHeaderCard(
                        eyebrow: 'PRAVNO · KOLAČIĆI',
                        title: l10n.cookiesScreenHeaderTitle,
                        lastUpdated: l10n.cookiesScreenLastUpdated(
                          DateTime.now().toString().split(' ')[0],
                        ),
                        isMobile: isMobile,
                      ),
                      SizedBox(height: isMobile ? 16 : 24),
                      _LegalTocCard(
                        title: l10n.cookiesScreenToc,
                        items: [
                          ('1. ${l10n.cookiesScreenSection1Title}', 'what'),
                          ('2. ${l10n.cookiesScreenSection2Title}', 'how'),
                          ('3. ${l10n.cookiesScreenSection3Title}', 'types'),
                          ('4. ${l10n.cookiesScreenSection4Title}', 'choices'),
                          (
                            '5. ${l10n.cookiesScreenSection5Title}',
                            'thirdparty',
                          ),
                          ('6. ${l10n.cookiesScreenSection6Title}', 'updates'),
                          ('7. ${l10n.cookiesScreenSection7Title}', 'more'),
                        ],
                        onTapKey: _scrollToSection,
                        isMobile: isMobile,
                      ),
                      SizedBox(height: isMobile ? 16 : 24),
                      _LegalSectionCard(
                        sectionKey: _sectionKeys['what']!,
                        title: l10n.cookiesScreenSection1Title,
                        body: l10n.cookiesScreenSection1Body,
                        isMobile: isMobile,
                      ),
                      _LegalSectionCard(
                        sectionKey: _sectionKeys['how']!,
                        title: l10n.cookiesScreenSection2Title,
                        body: l10n.cookiesScreenSection2Body,
                        isMobile: isMobile,
                      ),
                      _LegalSectionCard(
                        sectionKey: _sectionKeys['types']!,
                        title: l10n.cookiesScreenSection3Title,
                        body: l10n.cookiesScreenSection3Body,
                        isMobile: isMobile,
                      ),
                      _LegalSectionCard(
                        sectionKey: _sectionKeys['choices']!,
                        title: l10n.cookiesScreenSection4Title,
                        body: l10n.cookiesScreenSection4Body,
                        isMobile: isMobile,
                      ),
                      _LegalSectionCard(
                        sectionKey: _sectionKeys['thirdparty']!,
                        title: l10n.cookiesScreenSection5Title,
                        body: l10n.cookiesScreenSection5Body,
                        isMobile: isMobile,
                      ),
                      _LegalSectionCard(
                        sectionKey: _sectionKeys['updates']!,
                        title: l10n.cookiesScreenSection6Title,
                        body: l10n.cookiesScreenSection6Body,
                        isMobile: isMobile,
                      ),
                      _LegalSectionCard(
                        sectionKey: _sectionKeys['more']!,
                        title: l10n.cookiesScreenSection7Title,
                        body: l10n.cookiesScreenSection7Body,
                        isMobile: isMobile,
                      ),
                      SizedBox(height: isMobile ? 8 : 16),
                      _PrivacyLinkCard(
                        title: l10n.cookiesScreenPrivacyLinkTitle,
                        body: l10n.cookiesScreenPrivacyLinkBody,
                        buttonLabel: l10n.cookiesScreenPrivacyLinkButton,
                        onPressed: () => context.go(OwnerRoutes.privacyPolicy),
                        isMobile: isMobile,
                      ),
                      SizedBox(height: isMobile ? 16 : 24),
                      _LegalNoticeCard(
                        icon: 'info',
                        title: l10n.cookiesScreenLegalNotice,
                        body: l10n.cookiesScreenLegalNoticeBody,
                        isMobile: isMobile,
                      ),
                      SizedBox(height: isMobile ? 16 : 24),
                    ],
                  ),
                ),
              ),
            ),
            if (_showScrollToTop)
              Positioned(
                bottom: isMobile ? 16 : 24,
                right: isMobile ? 16 : 24,
                child: FloatingActionButton(
                  onPressed: _scrollToTop,
                  backgroundColor: theme.colorScheme.primary,
                  child: const Icon(Icons.arrow_upward, color: Colors.white),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _LegalHeaderCard extends StatelessWidget {
  const _LegalHeaderCard({
    required this.eyebrow,
    required this.title,
    required this.lastUpdated,
    required this.isMobile,
  });

  final String eyebrow;
  final String title;
  final String lastUpdated;
  final bool isMobile;

  @override
  Widget build(BuildContext context) {
    final c = BBColor.of(context);
    return BbCard(
      padding: EdgeInsets.all(isMobile ? 16 : 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            eyebrow,
            style: BBType.eyebrow(context).copyWith(color: c.primary),
          ),
          SizedBox(height: isMobile ? 8 : 12),
          Text(
            title,
            style: isMobile ? BBType.h1(context) : BBType.display(context),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          Text(
            lastUpdated,
            style: BBType.bodyNum(context).copyWith(color: c.textTertiary),
          ),
        ],
      ),
    );
  }
}

class _LegalTocCard extends StatelessWidget {
  const _LegalTocCard({
    required this.title,
    required this.items,
    required this.onTapKey,
    required this.isMobile,
  });

  final String title;
  final List<(String, String)> items;
  final void Function(String) onTapKey;
  final bool isMobile;

  @override
  Widget build(BuildContext context) {
    final c = BBColor.of(context);
    return BbCard(
      padding: EdgeInsets.all(isMobile ? 16 : 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          BbSectionHeader(title: title, level: BbSectionHeaderLevel.h3),
          for (final item in items)
            InkWell(
              onTap: () => onTapKey(item.$2),
              borderRadius: BBRadius.smAll,
              child: Padding(
                padding: EdgeInsets.symmetric(
                  vertical: isMobile ? 8 : 10,
                  horizontal: 8,
                ),
                child: Row(
                  children: [
                    BbIcon(name: 'chevron_right', size: 18, color: c.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        item.$1,
                        style: BBType.body(
                          context,
                        ).copyWith(color: c.textPrimary),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _LegalSectionCard extends StatelessWidget {
  const _LegalSectionCard({
    required this.sectionKey,
    required this.title,
    required this.body,
    required this.isMobile,
  });

  final GlobalKey sectionKey;
  final String title;
  final String body;
  final bool isMobile;

  @override
  Widget build(BuildContext context) {
    final c = BBColor.of(context);
    return Padding(
      key: sectionKey,
      padding: EdgeInsets.only(bottom: isMobile ? 12 : 16),
      child: BbCard(
        padding: EdgeInsets.all(isMobile ? 16 : 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            BbSectionHeader(title: title, level: BbSectionHeaderLevel.h3),
            Text(
              body,
              style: BBType.body(
                context,
              ).copyWith(height: 1.7, color: c.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

class _PrivacyLinkCard extends StatelessWidget {
  const _PrivacyLinkCard({
    required this.title,
    required this.body,
    required this.buttonLabel,
    required this.onPressed,
    required this.isMobile,
  });

  final String title;
  final String body;
  final String buttonLabel;
  final VoidCallback onPressed;
  final bool isMobile;

  @override
  Widget build(BuildContext context) {
    final c = BBColor.of(context);
    return BbCard(
      variant: BbCardVariant.accentLeft,
      accentTone: BbCardAccentTone.primary,
      padding: EdgeInsets.all(isMobile ? 16 : 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: c.primary.withValues(alpha: 0.12),
                  borderRadius: BBRadius.smAll,
                ),
                child: BbIcon(
                  name: 'privacy_tip',
                  size: isMobile ? 20 : 24,
                  color: c.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(title, style: BBType.h3(context)),
                ),
              ),
            ],
          ),
          SizedBox(height: isMobile ? 10 : 12),
          Text(
            body,
            style: BBType.body(
              context,
            ).copyWith(height: 1.6, color: c.textSecondary),
          ),
          SizedBox(height: isMobile ? 14 : 16),
          BbButton(
            label: buttonLabel,
            iconRight: 'arrow_forward',
            onPressed: onPressed,
            fullWidth: true,
            size: isMobile ? BbButtonSize.md : BbButtonSize.lg,
          ),
        ],
      ),
    );
  }
}

class _LegalNoticeCard extends StatelessWidget {
  const _LegalNoticeCard({
    required this.icon,
    required this.title,
    required this.body,
    required this.isMobile,
  });

  final String icon;
  final String title;
  final String body;
  final bool isMobile;

  @override
  Widget build(BuildContext context) {
    final c = BBColor.of(context);
    return BbCard(
      variant: BbCardVariant.accentLeft,
      accentTone: BbCardAccentTone.primary,
      padding: EdgeInsets.all(isMobile ? 16 : 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: c.primary.withValues(alpha: 0.12),
                  borderRadius: BBRadius.smAll,
                ),
                child: BbIcon(
                  name: icon,
                  size: isMobile ? 20 : 24,
                  color: c.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(title, style: BBType.h3(context)),
                ),
              ),
            ],
          ),
          SizedBox(height: isMobile ? 10 : 12),
          Text(
            body,
            style: BBType.body(
              context,
            ).copyWith(height: 1.6, color: c.textSecondary),
          ),
        ],
      ),
    );
  }
}
