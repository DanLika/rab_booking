import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/common_app_bar.dart';
import '../../../../core/design/bb_redesign_tokens.dart';
import '../../../../core/design/tokens.dart';
import '../../../../shared/widgets/redesign.dart';

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
                        eyebrow: 'PRAVNO · UVJETI',
                        title: l10n.termsScreenHeaderTitle,
                        lastUpdated: l10n.termsScreenLastUpdated(
                          DateTime.now().year.toString(),
                        ),
                        isMobile: isMobile,
                      ),
                      SizedBox(height: isMobile ? 16 : 24),
                      _LegalTocCard(
                        title: l10n.termsScreenToc,
                        items: [
                          ('1. ${l10n.termsScreenSection1Title}', 'acceptance'),
                          ('2. ${l10n.termsScreenSection2Title}', 'license'),
                          ('3. ${l10n.termsScreenSection3Title}', 'booking'),
                          ('4. ${l10n.termsScreenSection4Title}', 'payment'),
                          (
                            '5. ${l10n.termsScreenSection5Title}',
                            'cancellation',
                          ),
                          (
                            '6. ${l10n.termsScreenSection6Title}',
                            'responsibilities',
                          ),
                          ('7. ${l10n.termsScreenSection7Title}', 'liability'),
                          (
                            '8. ${l10n.termsScreenSection8Title}',
                            'modifications',
                          ),
                          ('9. ${l10n.termsScreenSection9Title}', 'governing'),
                          ('10. ${l10n.termsScreenSection10Title}', 'contact'),
                        ],
                        onTapKey: _scrollToSection,
                        isMobile: isMobile,
                      ),
                      SizedBox(height: isMobile ? 16 : 24),
                      _LegalSectionCard(
                        sectionKey: _sectionKeys['acceptance']!,
                        title: l10n.termsScreenSection1Title,
                        body: l10n.termsScreenSection1Body,
                        isMobile: isMobile,
                      ),
                      _LegalSectionCard(
                        sectionKey: _sectionKeys['license']!,
                        title: l10n.termsScreenSection2Title,
                        body: l10n.termsScreenSection2Body,
                        isMobile: isMobile,
                      ),
                      _LegalSectionCard(
                        sectionKey: _sectionKeys['booking']!,
                        title: l10n.termsScreenSection3Title,
                        body: l10n.termsScreenSection3Body,
                        isMobile: isMobile,
                      ),
                      _LegalSectionCard(
                        sectionKey: _sectionKeys['payment']!,
                        title: l10n.termsScreenSection4Title,
                        body: l10n.termsScreenSection4Body,
                        isMobile: isMobile,
                      ),
                      _LegalSectionCard(
                        sectionKey: _sectionKeys['cancellation']!,
                        title: l10n.termsScreenSection5Title,
                        body: l10n.termsScreenSection5Body,
                        isMobile: isMobile,
                      ),
                      _LegalSectionCard(
                        sectionKey: _sectionKeys['responsibilities']!,
                        title: l10n.termsScreenSection6Title,
                        body: l10n.termsScreenSection6Body,
                        isMobile: isMobile,
                      ),
                      _LegalSectionCard(
                        sectionKey: _sectionKeys['liability']!,
                        title: l10n.termsScreenSection7Title,
                        body: l10n.termsScreenSection7Body,
                        isMobile: isMobile,
                      ),
                      _LegalSectionCard(
                        sectionKey: _sectionKeys['modifications']!,
                        title: l10n.termsScreenSection8Title,
                        body: l10n.termsScreenSection8Body,
                        isMobile: isMobile,
                      ),
                      _LegalSectionCard(
                        sectionKey: _sectionKeys['governing']!,
                        title: l10n.termsScreenSection9Title,
                        body: l10n.termsScreenSection9Body,
                        isMobile: isMobile,
                      ),
                      _LegalSectionCard(
                        sectionKey: _sectionKeys['contact']!,
                        title: l10n.termsScreenSection10Title,
                        body: l10n.termsScreenSection10Body,
                        isMobile: isMobile,
                      ),
                      SizedBox(height: isMobile ? 16 : 24),
                      _LegalNoticeCard(
                        icon: 'info',
                        title: l10n.termsScreenLegalNotice,
                        body: l10n.termsScreenLegalNoticeBody,
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
