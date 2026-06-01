import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/common_app_bar.dart';
import '../../../../core/design/bb_redesign_tokens.dart';
import '../../../../core/design/tokens.dart';
import '../../../../shared/widgets/redesign.dart';

class PrivacyPolicyScreen extends StatefulWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  State<PrivacyPolicyScreen> createState() => _PrivacyPolicyScreenState();
}

class _PrivacyPolicyScreenState extends State<PrivacyPolicyScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _showScrollToTop = false;

  final Map<String, GlobalKey> _sectionKeys = {
    'intro': GlobalKey(),
    'collect': GlobalKey(),
    'legal': GlobalKey(),
    'use': GlobalKey(),
    'sharing': GlobalKey(),
    'security': GlobalKey(),
    'retention': GlobalKey(),
    'rights': GlobalKey(),
    'cookies': GlobalKey(),
    'transfers': GlobalKey(),
    'children': GlobalKey(),
    'changes': GlobalKey(),
    'dpo': GlobalKey(),
    'authority': GlobalKey(),
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
        title: l10n.privacyScreenTitle,
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
                        eyebrow: 'PRAVNO · PRIVATNOST',
                        title: l10n.privacyScreenHeaderTitle,
                        lastUpdated: l10n.privacyScreenLastUpdated(
                          DateTime.now().year.toString(),
                        ),
                        isMobile: isMobile,
                      ),
                      SizedBox(height: isMobile ? 16 : 24),
                      _LegalTocCard(
                        title: l10n.privacyScreenToc,
                        items: [
                          ('1. ${l10n.privacyScreenSection1Title}', 'intro'),
                          ('2. ${l10n.privacyScreenSection2Title}', 'collect'),
                          ('3. ${l10n.privacyScreenSection3Title}', 'legal'),
                          ('4. ${l10n.privacyScreenSection4Title}', 'use'),
                          ('5. ${l10n.privacyScreenSection5Title}', 'sharing'),
                          ('6. ${l10n.privacyScreenSection6Title}', 'security'),
                          (
                            '7. ${l10n.privacyScreenSection7Title}',
                            'retention',
                          ),
                          ('8. ${l10n.privacyScreenSection8Title}', 'rights'),
                          ('9. ${l10n.privacyScreenSection9Title}', 'cookies'),
                          (
                            '10. ${l10n.privacyScreenSection10Title}',
                            'transfers',
                          ),
                          (
                            '11. ${l10n.privacyScreenSection11Title}',
                            'children',
                          ),
                          (
                            '12. ${l10n.privacyScreenSection12Title}',
                            'changes',
                          ),
                          ('13. ${l10n.privacyScreenSection13Title}', 'dpo'),
                          (
                            '14. ${l10n.privacyScreenSection14Title}',
                            'authority',
                          ),
                        ],
                        onTapKey: _scrollToSection,
                        isMobile: isMobile,
                      ),
                      SizedBox(height: isMobile ? 16 : 24),
                      _LegalSectionCard(
                        sectionKey: _sectionKeys['intro']!,
                        title: l10n.privacyScreenSection1Title,
                        body: l10n.privacyScreenSection1Body,
                        isMobile: isMobile,
                      ),
                      _LegalSectionCard(
                        sectionKey: _sectionKeys['collect']!,
                        title: l10n.privacyScreenSection2Title,
                        body: l10n.privacyScreenSection2Body,
                        isMobile: isMobile,
                      ),
                      _LegalSectionCard(
                        sectionKey: _sectionKeys['legal']!,
                        title: l10n.privacyScreenSection3Title,
                        body: l10n.privacyScreenSection3Body,
                        isMobile: isMobile,
                      ),
                      _LegalSectionCard(
                        sectionKey: _sectionKeys['use']!,
                        title: l10n.privacyScreenSection4Title,
                        body: l10n.privacyScreenSection4Body,
                        isMobile: isMobile,
                      ),
                      _LegalSectionCard(
                        sectionKey: _sectionKeys['sharing']!,
                        title: l10n.privacyScreenSection5Title,
                        body: l10n.privacyScreenSection5Body,
                        isMobile: isMobile,
                      ),
                      _LegalSectionCard(
                        sectionKey: _sectionKeys['security']!,
                        title: l10n.privacyScreenSection6Title,
                        body: l10n.privacyScreenSection6Body,
                        isMobile: isMobile,
                      ),
                      _LegalSectionCard(
                        sectionKey: _sectionKeys['retention']!,
                        title: l10n.privacyScreenSection7Title,
                        body: l10n.privacyScreenSection7Body,
                        isMobile: isMobile,
                      ),
                      _LegalSectionCard(
                        sectionKey: _sectionKeys['rights']!,
                        title: l10n.privacyScreenSection8Title,
                        body: l10n.privacyScreenSection8Body,
                        isMobile: isMobile,
                      ),
                      _LegalSectionCard(
                        sectionKey: _sectionKeys['cookies']!,
                        title: l10n.privacyScreenSection9Title,
                        body: l10n.privacyScreenSection9Body,
                        isMobile: isMobile,
                      ),
                      _LegalSectionCard(
                        sectionKey: _sectionKeys['transfers']!,
                        title: l10n.privacyScreenSection10Title,
                        body: l10n.privacyScreenSection10Body,
                        isMobile: isMobile,
                      ),
                      _LegalSectionCard(
                        sectionKey: _sectionKeys['children']!,
                        title: l10n.privacyScreenSection11Title,
                        body: l10n.privacyScreenSection11Body,
                        isMobile: isMobile,
                      ),
                      _LegalSectionCard(
                        sectionKey: _sectionKeys['changes']!,
                        title: l10n.privacyScreenSection12Title,
                        body: l10n.privacyScreenSection12Body,
                        isMobile: isMobile,
                      ),
                      _LegalSectionCard(
                        sectionKey: _sectionKeys['dpo']!,
                        title: l10n.privacyScreenSection13Title,
                        body: l10n.privacyScreenSection13Body,
                        isMobile: isMobile,
                      ),
                      _LegalSectionCard(
                        sectionKey: _sectionKeys['authority']!,
                        title: l10n.privacyScreenSection14Title,
                        body: l10n.privacyScreenSection14Body,
                        isMobile: isMobile,
                      ),
                      SizedBox(height: isMobile ? 16 : 24),
                      _LegalNoticeCard(
                        icon: 'shield',
                        title: l10n.privacyScreenGdprNotice,
                        body: l10n.privacyScreenGdprNoticeBody,
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
