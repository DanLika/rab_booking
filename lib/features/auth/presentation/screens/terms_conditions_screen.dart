import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/common_app_bar.dart';
import '../../../../core/design/bb_redesign_tokens.dart';
import '../../../../core/design/tokens.dart';
import '../../../../shared/widgets/redesign.dart';
import '../../../../core/theme/gradient_extensions.dart';
import '../widgets/legal_tabs_row.dart';

/// Two-column legal reader breakpoint — CONTENT-FIT reflow (audit/146 option B):
/// sidebar(240) + gap(48) + doc column fit inside the 980 clamp from 900px up,
/// so this reads the layout BOX (LayoutBuilder), not device width, and is
/// intentionally kept at 900 (NOT migrated to the 1200 device-class breakpoint).
const double _kLegalTwoColMin = 900;

class TermsConditionsScreen extends StatefulWidget {
  const TermsConditionsScreen({super.key});

  @override
  State<TermsConditionsScreen> createState() => _TermsConditionsScreenState();
}

class _TermsConditionsScreenState extends State<TermsConditionsScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _showScrollToTop = false;

  final Map<String, GlobalKey> _sectionKeys = {
    'acceptance': GlobalKey(),
    'license': GlobalKey(),
    'booking': GlobalKey(),
    'payment': GlobalKey(),
    'cancellation': GlobalKey(),
    'responsibilities': GlobalKey(),
    'liability': GlobalKey(),
    'modifications': GlobalKey(),
    'governing': GlobalKey(),
    'contact': GlobalKey(),
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
    final l10n = AppLocalizations.of(context);

    final tocItems = <(String, String)>[
      ('1. ${l10n.termsScreenSection1Title}', 'acceptance'),
      ('2. ${l10n.termsScreenSection2Title}', 'license'),
      ('3. ${l10n.termsScreenSection3Title}', 'booking'),
      ('4. ${l10n.termsScreenSection4Title}', 'payment'),
      ('5. ${l10n.termsScreenSection5Title}', 'cancellation'),
      ('6. ${l10n.termsScreenSection6Title}', 'responsibilities'),
      ('7. ${l10n.termsScreenSection7Title}', 'liability'),
      ('8. ${l10n.termsScreenSection8Title}', 'modifications'),
      ('9. ${l10n.termsScreenSection9Title}', 'governing'),
      ('10. ${l10n.termsScreenSection10Title}', 'contact'),
    ];

    final lastUpdated = l10n.termsScreenLastUpdated(
      DateTime.now().year.toString(),
    );

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: rd.shellBg,
      appBar: CommonAppBar(
        title: l10n.termsScreenTitle,
        leadingIcon: Icons.arrow_back,
        onLeadingIconTap: (context) {
          if (context.canPop()) {
            context.pop();
          } else {
            context.go('/owner/profile');
          }
        },
      ),
      body: Container(
        decoration: BoxDecoration(gradient: context.gradients.pageBackground),
        child: SafeArea(
          // Box-driven reflow (audit/146 option B): read available CONTENT width
          // (LayoutBuilder), not device width (MediaQuery). The 2-col reader fits
          // from _kLegalTwoColMin up inside the 980 clamp → content-fit; kept at
          // 900, NOT migrated to the 1200 device-class breakpoint.
          child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              final double width = constraints.maxWidth;
              final bool isMobile = width < 600;
              final bool isDesktop = width >= _kLegalTwoColMin;
              final double horizontalPadding = isMobile
                  ? 16.0
                  : width < _kLegalTwoColMin
                  ? 24.0
                  : 32.0;
              return Stack(
                alignment: Alignment.topLeft,
                children: [
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 980),
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
                        child: const Icon(
                          Icons.arrow_upward,
                          color: Colors.white,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  /// Desktop ≥900: 240px sticky TOC sidebar + doc column.
  /// Sidebar is OUTSIDE the scrollable so it stays in viewport while the doc
  /// column scrolls via [_scrollController].
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
                  title: l10n.termsScreenToc,
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
                  const LegalTabsRow(current: LegalTab.terms),
                  const SizedBox(height: 28),
                  _LegalDocHeader(
                    eyebrow: 'PRAVNO · UVJETI',
                    title: l10n.termsScreenHeaderTitle,
                    lastUpdated: lastUpdated,
                    isMobile: false,
                  ),
                  const SizedBox(height: 28),
                  ..._sections(l10n),
                  const SizedBox(height: 16),
                  _LegalNoticeCard(
                    icon: 'info',
                    title: l10n.termsScreenLegalNotice,
                    body: l10n.termsScreenLegalNoticeBody,
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

  /// Tablet/mobile <900: single column, TOC kept as card at top.
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
          const LegalTabsRow(current: LegalTab.terms),
          SizedBox(height: isMobile ? 20 : 24),
          _LegalDocHeader(
            eyebrow: 'PRAVNO · UVJETI',
            title: l10n.termsScreenHeaderTitle,
            lastUpdated: lastUpdated,
            isMobile: isMobile,
          ),
          SizedBox(height: isMobile ? 16 : 20),
          _LegalTocCard(
            title: l10n.termsScreenToc,
            items: tocItems,
            onTapKey: _scrollToSection,
            isMobile: isMobile,
          ),
          SizedBox(height: isMobile ? 20 : 24),
          ..._sections(l10n),
          SizedBox(height: isMobile ? 8 : 16),
          _LegalNoticeCard(
            icon: 'info',
            title: l10n.termsScreenLegalNotice,
            body: l10n.termsScreenLegalNoticeBody,
            isMobile: isMobile,
          ),
          SizedBox(height: isMobile ? 16 : 24),
        ],
      ),
    );
  }

  List<Widget> _sections(AppLocalizations l10n) => [
    _LegalFlatSection(
      sectionKey: _sectionKeys['acceptance']!,
      title: l10n.termsScreenSection1Title,
      body: l10n.termsScreenSection1Body,
    ),
    _LegalFlatSection(
      sectionKey: _sectionKeys['license']!,
      title: l10n.termsScreenSection2Title,
      body: l10n.termsScreenSection2Body,
    ),
    _LegalFlatSection(
      sectionKey: _sectionKeys['booking']!,
      title: l10n.termsScreenSection3Title,
      body: l10n.termsScreenSection3Body,
    ),
    _LegalFlatSection(
      sectionKey: _sectionKeys['payment']!,
      title: l10n.termsScreenSection4Title,
      body: l10n.termsScreenSection4Body,
    ),
    _LegalFlatSection(
      sectionKey: _sectionKeys['cancellation']!,
      title: l10n.termsScreenSection5Title,
      body: l10n.termsScreenSection5Body,
    ),
    _LegalFlatSection(
      sectionKey: _sectionKeys['responsibilities']!,
      title: l10n.termsScreenSection6Title,
      body: l10n.termsScreenSection6Body,
    ),
    _LegalFlatSection(
      sectionKey: _sectionKeys['liability']!,
      title: l10n.termsScreenSection7Title,
      body: l10n.termsScreenSection7Body,
    ),
    _LegalFlatSection(
      sectionKey: _sectionKeys['modifications']!,
      title: l10n.termsScreenSection8Title,
      body: l10n.termsScreenSection8Body,
    ),
    _LegalFlatSection(
      sectionKey: _sectionKeys['governing']!,
      title: l10n.termsScreenSection9Title,
      body: l10n.termsScreenSection9Body,
    ),
    _LegalFlatSection(
      sectionKey: _sectionKeys['contact']!,
      title: l10n.termsScreenSection10Title,
      body: l10n.termsScreenSection10Body,
    ),
  ];
}

/// Flat document header — eyebrow + display title + last-updated caption.
/// Mirrors `legal.jsx` LegalDocHeader (no card wrap, design intentionally).
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

/// Flat section — BbSectionHeader (h3) + body Text. No card.
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

/// Mobile/tablet TOC — card containing tappable jump-links.
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

/// Desktop sticky-sidebar TOC. Flat list with eyebrow label, jump-links,
/// last-modified mini surface. Mirrors `legal.jsx` LegalToc.
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

/// Inline notice card — primary accent-left card with icon disc + title + body.
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
