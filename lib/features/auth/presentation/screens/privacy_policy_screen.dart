import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/common_app_bar.dart';
import '../../../../core/design/bb_redesign_tokens.dart';
import '../../../../core/design/tokens.dart';
import '../../../../shared/widgets/redesign.dart';
import '../widgets/legal_tabs_row.dart';

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
    final isDesktop = screenWidth >= 900;
    final horizontalPadding = isMobile
        ? 16.0
        : screenWidth < 900
        ? 24.0
        : 32.0;
    final l10n = AppLocalizations.of(context);

    final tocItems = <(String, String)>[
      ('1. ${l10n.privacyScreenSection1Title}', 'intro'),
      ('2. ${l10n.privacyScreenSection2Title}', 'collect'),
      ('3. ${l10n.privacyScreenSection3Title}', 'legal'),
      ('4. ${l10n.privacyScreenSection4Title}', 'use'),
      ('5. ${l10n.privacyScreenSection5Title}', 'sharing'),
      ('6. ${l10n.privacyScreenSection6Title}', 'security'),
      ('7. ${l10n.privacyScreenSection7Title}', 'retention'),
      ('8. ${l10n.privacyScreenSection8Title}', 'rights'),
      ('9. ${l10n.privacyScreenSection9Title}', 'cookies'),
      ('10. ${l10n.privacyScreenSection10Title}', 'transfers'),
      ('11. ${l10n.privacyScreenSection11Title}', 'children'),
      ('12. ${l10n.privacyScreenSection12Title}', 'changes'),
      ('13. ${l10n.privacyScreenSection13Title}', 'dpo'),
      ('14. ${l10n.privacyScreenSection14Title}', 'authority'),
    ];

    final lastUpdated = l10n.privacyScreenLastUpdated(
      DateTime.now().year.toString(),
    );

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
          alignment: Alignment.topLeft,
          children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1200),
                child: isDesktop
                    ? _buildDesktop(
                        l10n: l10n,
                        horizontalPadding: horizontalPadding,
                        tocItems: tocItems,
                        lastUpdated: lastUpdated,
                      )
                    : _buildMobile(
                        l10n: l10n,
                        horizontalPadding: horizontalPadding,
                        isMobile: isMobile,
                        tocItems: tocItems,
                        lastUpdated: lastUpdated,
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

  Widget _buildDesktop({
    required AppLocalizations l10n,
    required double horizontalPadding,
    required List<(String, String)> tocItems,
    required String lastUpdated,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 240,
            child: Padding(
              padding: const EdgeInsets.only(top: 28),
              child: SingleChildScrollView(
                child: _LegalTocSidebar(
                  title: l10n.privacyScreenToc,
                  items: tocItems,
                  onTapKey: _scrollToSection,
                  lastUpdatedLabel: l10n.lastUpdated,
                  lastUpdatedValue: lastUpdated,
                ),
              ),
            ),
          ),
          const SizedBox(width: 48),
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollController,
              padding: const EdgeInsets.only(top: 24, bottom: 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const LegalTabsRow(current: LegalTab.privacy),
                  const SizedBox(height: 28),
                  _LegalDocHeader(
                    eyebrow: 'PRAVNO · PRIVATNOST',
                    title: l10n.privacyScreenHeaderTitle,
                    lastUpdated: lastUpdated,
                    isMobile: false,
                  ),
                  const SizedBox(height: 28),
                  ..._sections(l10n),
                  const SizedBox(height: 16),
                  _LegalNoticeCard(
                    icon: 'shield',
                    title: l10n.privacyScreenGdprNotice,
                    body: l10n.privacyScreenGdprNoticeBody,
                    isMobile: false,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobile({
    required AppLocalizations l10n,
    required double horizontalPadding,
    required bool isMobile,
    required List<(String, String)> tocItems,
    required String lastUpdated,
  }) {
    return SingleChildScrollView(
      controller: _scrollController,
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: isMobile ? 16 : 24,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const LegalTabsRow(current: LegalTab.privacy),
          SizedBox(height: isMobile ? 20 : 24),
          _LegalDocHeader(
            eyebrow: 'PRAVNO · PRIVATNOST',
            title: l10n.privacyScreenHeaderTitle,
            lastUpdated: lastUpdated,
            isMobile: isMobile,
          ),
          SizedBox(height: isMobile ? 16 : 20),
          _LegalTocCard(
            title: l10n.privacyScreenToc,
            items: tocItems,
            onTapKey: _scrollToSection,
            isMobile: isMobile,
          ),
          SizedBox(height: isMobile ? 20 : 24),
          ..._sections(l10n),
          SizedBox(height: isMobile ? 8 : 16),
          _LegalNoticeCard(
            icon: 'shield',
            title: l10n.privacyScreenGdprNotice,
            body: l10n.privacyScreenGdprNoticeBody,
            isMobile: isMobile,
          ),
          SizedBox(height: isMobile ? 16 : 24),
        ],
      ),
    );
  }

  List<Widget> _sections(AppLocalizations l10n) => [
    _LegalFlatSection(
      sectionKey: _sectionKeys['intro']!,
      title: l10n.privacyScreenSection1Title,
      body: l10n.privacyScreenSection1Body,
    ),
    _LegalFlatSection(
      sectionKey: _sectionKeys['collect']!,
      title: l10n.privacyScreenSection2Title,
      body: l10n.privacyScreenSection2Body,
    ),
    _LegalFlatSection(
      sectionKey: _sectionKeys['legal']!,
      title: l10n.privacyScreenSection3Title,
      body: l10n.privacyScreenSection3Body,
    ),
    _LegalFlatSection(
      sectionKey: _sectionKeys['use']!,
      title: l10n.privacyScreenSection4Title,
      body: l10n.privacyScreenSection4Body,
    ),
    _LegalFlatSection(
      sectionKey: _sectionKeys['sharing']!,
      title: l10n.privacyScreenSection5Title,
      body: l10n.privacyScreenSection5Body,
    ),
    _LegalFlatSection(
      sectionKey: _sectionKeys['security']!,
      title: l10n.privacyScreenSection6Title,
      body: l10n.privacyScreenSection6Body,
    ),
    _LegalFlatSection(
      sectionKey: _sectionKeys['retention']!,
      title: l10n.privacyScreenSection7Title,
      body: l10n.privacyScreenSection7Body,
    ),
    _LegalFlatSection(
      sectionKey: _sectionKeys['rights']!,
      title: l10n.privacyScreenSection8Title,
      body: l10n.privacyScreenSection8Body,
    ),
    _LegalFlatSection(
      sectionKey: _sectionKeys['cookies']!,
      title: l10n.privacyScreenSection9Title,
      body: l10n.privacyScreenSection9Body,
    ),
    _LegalFlatSection(
      sectionKey: _sectionKeys['transfers']!,
      title: l10n.privacyScreenSection10Title,
      body: l10n.privacyScreenSection10Body,
    ),
    _LegalFlatSection(
      sectionKey: _sectionKeys['children']!,
      title: l10n.privacyScreenSection11Title,
      body: l10n.privacyScreenSection11Body,
    ),
    _LegalFlatSection(
      sectionKey: _sectionKeys['changes']!,
      title: l10n.privacyScreenSection12Title,
      body: l10n.privacyScreenSection12Body,
    ),
    _LegalFlatSection(
      sectionKey: _sectionKeys['dpo']!,
      title: l10n.privacyScreenSection13Title,
      body: l10n.privacyScreenSection13Body,
    ),
    _LegalFlatSection(
      sectionKey: _sectionKeys['authority']!,
      title: l10n.privacyScreenSection14Title,
      body: l10n.privacyScreenSection14Body,
    ),
  ];
}

class _LegalDocHeader extends StatelessWidget {
  const _LegalDocHeader({
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
    return Column(
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
    );
  }
}

class _LegalFlatSection extends StatelessWidget {
  const _LegalFlatSection({
    required this.sectionKey,
    required this.title,
    required this.body,
  });

  final GlobalKey sectionKey;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final c = BBColor.of(context);
    return Padding(
      key: sectionKey,
      padding: const EdgeInsets.only(bottom: 22),
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

class _LegalTocSidebar extends StatelessWidget {
  const _LegalTocSidebar({
    required this.title,
    required this.items,
    required this.onTapKey,
    required this.lastUpdatedLabel,
    required this.lastUpdatedValue,
  });

  final String title;
  final List<(String, String)> items;
  final void Function(String) onTapKey;
  final String lastUpdatedLabel;
  final String lastUpdatedValue;

  @override
  Widget build(BuildContext context) {
    final c = BBColor.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title.toUpperCase(),
          style: BBType.eyebrow(
            context,
          ).copyWith(color: c.textTertiary, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        for (final item in items)
          InkWell(
            onTap: () => onTapKey(item.$2),
            borderRadius: BBRadius.smAll,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 12),
              child: Text(
                item.$1,
                style: BBType.body(context).copyWith(
                  color: c.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: c.surfaceVariant,
            borderRadius: BBRadius.smAll,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                lastUpdatedLabel.toUpperCase(),
                style: BBType.eyebrow(context).copyWith(color: c.textTertiary),
              ),
              const SizedBox(height: 4),
              Text(
                lastUpdatedValue,
                style: BBType.bodyNum(context).copyWith(
                  color: c.textPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ],
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
