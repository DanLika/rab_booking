import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../../core/design/tokens.dart';
import '../../../../../core/utils/platform_scroll_physics.dart';
import '../../../../../core/theme/gradient_extensions.dart';
import '../../../../../shared/widgets/common_app_bar.dart';
import '../../../../../shared/widgets/redesign.dart';
import '../../widgets/owner_app_drawer.dart';

/// FAQ body-column width gates — content-fit reflow (audit/145): read the layout
/// BOX (`constraints.maxWidth`), not device width, so they stay at 1024/600 and
/// are intentionally NOT migrated to the 1200 desktop breakpoint.
const double _kFaqDesktopColMin = 1024;
const double _kFaqTabletColMin = 600;

class FAQItem {
  final String question;
  final String answer;
  final String categoryKey; // Internal key for filtering

  const FAQItem({
    required this.question,
    required this.answer,
    required this.categoryKey,
  });
}

/// FAQ Screen with search and categories
class FAQScreen extends StatefulWidget {
  const FAQScreen({super.key});

  @override
  State<FAQScreen> createState() => _FAQScreenState();
}

class _FAQScreenState extends State<FAQScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedCategoryKey = 'all';

  // Category keys for internal use (not translated)
  // NOTE: "General" category moved to bookbed.io website (business FAQs)
  // This app focuses on operational/how-to FAQs only
  static const List<String> _categoryKeys = [
    'all',
    'bookings',
    'payments',
    'widget',
    'icalSync',
    'support',
  ];

  String _getCategoryLabel(String key, AppLocalizations l10n) => switch (key) {
    'all' => l10n.ownerFaqCategoryAll,
    'bookings' => l10n.ownerFaqCategoryBookings,
    'payments' => l10n.ownerFaqCategoryPayments,
    'widget' => l10n.ownerFaqCategoryWidget,
    'icalSync' => l10n.ownerFaqCategoryIcalSync,
    'support' => l10n.ownerFaqCategorySupport,
    _ => key,
  };

  List<FAQItem> _getAllFAQs(AppLocalizations l10n) {
    // NOTE: General FAQs (What is BookBed?, Pricing, Mobile app?) moved to bookbed.io website
    return [
      // Bookings
      FAQItem(
        categoryKey: 'bookings',
        question: l10n.ownerFaqBookings1Q,
        answer: l10n.ownerFaqBookings1A,
      ),
      FAQItem(
        categoryKey: 'bookings',
        question: l10n.ownerFaqBookings2Q,
        answer: l10n.ownerFaqBookings2A,
      ),
      FAQItem(
        categoryKey: 'bookings',
        question: l10n.ownerFaqBookings3Q,
        answer: l10n.ownerFaqBookings3A,
      ),
      FAQItem(
        categoryKey: 'bookings',
        question: l10n.ownerFaqBookings4Q,
        answer: l10n.ownerFaqBookings4A,
      ),
      FAQItem(
        categoryKey: 'bookings',
        question: l10n.ownerFaqBookings5Q,
        answer: l10n.ownerFaqBookings5A,
      ),
      // Payments
      FAQItem(
        categoryKey: 'payments',
        question: l10n.ownerFaqPayments1Q,
        answer: l10n.ownerFaqPayments1A,
      ),
      FAQItem(
        categoryKey: 'payments',
        question: l10n.ownerFaqPayments2Q,
        answer: l10n.ownerFaqPayments2A,
      ),
      FAQItem(
        categoryKey: 'payments',
        question: l10n.ownerFaqPayments3Q,
        answer: l10n.ownerFaqPayments3A,
      ),
      FAQItem(
        categoryKey: 'payments',
        question: l10n.ownerFaqPayments4Q,
        answer: l10n.ownerFaqPayments4A,
      ),
      // Widget
      FAQItem(
        categoryKey: 'widget',
        question: l10n.ownerFaqWidget1Q,
        answer: l10n.ownerFaqWidget1A,
      ),
      FAQItem(
        categoryKey: 'widget',
        question: l10n.ownerFaqWidget2Q,
        answer: l10n.ownerFaqWidget2A,
      ),
      FAQItem(
        categoryKey: 'widget',
        question: l10n.ownerFaqWidget3Q,
        answer: l10n.ownerFaqWidget3A,
      ),
      FAQItem(
        categoryKey: 'widget',
        question: l10n.ownerFaqWidget4Q,
        answer: l10n.ownerFaqWidget4A,
      ),
      FAQItem(
        categoryKey: 'widget',
        question: l10n.ownerFaqWidget5Q,
        answer: l10n.ownerFaqWidget5A,
      ),
      // iCal Sync (Import)
      FAQItem(
        categoryKey: 'icalSync',
        question: l10n.ownerFaqIcal1Q,
        answer: l10n.ownerFaqIcal1A,
      ),
      FAQItem(
        categoryKey: 'icalSync',
        question: l10n.ownerFaqIcal2Q,
        answer: l10n.ownerFaqIcal2A,
      ),
      FAQItem(
        categoryKey: 'icalSync',
        question: l10n.ownerFaqIcal3Q,
        answer: l10n.ownerFaqIcal3A,
      ),
      FAQItem(
        categoryKey: 'icalSync',
        question: l10n.ownerFaqIcal4Q,
        answer: l10n.ownerFaqIcal4A,
      ),
      FAQItem(
        categoryKey: 'icalSync',
        question: l10n.ownerFaqIcal5Q,
        answer: l10n.ownerFaqIcal5A,
      ),
      FAQItem(
        categoryKey: 'icalSync',
        question: l10n.icalGuideFaq5Q,
        answer: l10n.icalGuideFaq5A,
      ),
      // iCal Sync (Export)
      FAQItem(
        categoryKey: 'icalSync',
        question: l10n.icalExportFaq1Q,
        answer: l10n.icalExportFaq1A,
      ),
      FAQItem(
        categoryKey: 'icalSync',
        question: l10n.icalExportFaq2Q,
        answer: l10n.icalExportFaq2A,
      ),
      FAQItem(
        categoryKey: 'icalSync',
        question: l10n.icalExportFaq3Q,
        answer: l10n.icalExportFaq3A,
      ),
      FAQItem(
        categoryKey: 'icalSync',
        question: l10n.icalExportFaq4Q,
        answer: l10n.icalExportFaq4A,
      ),
      // Technical Support
      FAQItem(
        categoryKey: 'support',
        question: l10n.ownerFaqSupport1Q,
        answer: l10n.ownerFaqSupport1A,
      ),
      FAQItem(
        categoryKey: 'support',
        question: l10n.ownerFaqSupport2Q,
        answer: l10n.ownerFaqSupport2A,
      ),
      FAQItem(
        categoryKey: 'support',
        question: l10n.ownerFaqSupport3Q,
        answer: l10n.ownerFaqSupport3A,
      ),
      FAQItem(
        categoryKey: 'support',
        question: l10n.ownerFaqSupport4Q,
        answer: l10n.ownerFaqSupport4A,
      ),
    ];
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Opens the device mail composer to the support address — audit/145 F3.
  /// Mirrors the mailto precedent in about_screen / profile_screen.
  Future<void> _launchSupportEmail() async {
    final Uri uri = Uri.parse('mailto:info@bookbed.io');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  List<FAQItem> _getFilteredFAQs(AppLocalizations l10n) {
    var faqs = _getAllFAQs(l10n);

    // Filter by category
    if (_selectedCategoryKey != 'all') {
      faqs = faqs
          .where((faq) => faq.categoryKey == _selectedCategoryKey)
          .toList();
    }

    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      faqs = faqs.where((faq) {
        final query = _searchQuery.toLowerCase();
        return faq.question.toLowerCase().contains(query) ||
            faq.answer.toLowerCase().contains(query);
      }).toList();
    }

    return faqs;
  }

  /// Material Symbols icon name for a category — mirrors handoff JSX
  /// `FAQ_CAT_ICON` map. Used in both filter chips and accordion-row leading
  /// tile so visual identity stays consistent.
  String _categoryIconName(String categoryKey) => switch (categoryKey) {
    'bookings' => 'receipt_long',
    'payments' => 'payments',
    'widget' => 'code',
    'icalSync' => 'sync',
    'support' => 'support_agent',
    _ => 'apps',
  };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = BBColor.of(context);
    final filteredFAQs = _getFilteredFAQs(l10n);
    final showResultsHeader =
        _searchQuery.isNotEmpty || _selectedCategoryKey != 'all';

    return Scaffold(
      resizeToAvoidBottomInset: false,
      drawer: const OwnerAppDrawer(currentRoute: 'guides/faq'),
      appBar: CommonAppBar(
        title: l10n.ownerFaqTitle,
        leadingIcon: Icons.menu,
        onLeadingIconTap: (context) => Scaffold.of(context).openDrawer(),
      ),
      body: Container(
        decoration: BoxDecoration(gradient: context.gradients.pageBackground),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (BuildContext _, BoxConstraints constraints) {
              // Center body column on wider viewports (handoff: 800px column
              // on desktop, 620px on tablet, edge-to-edge on mobile).
              final double maxColumn =
                  constraints.maxWidth >= _kFaqDesktopColMin
                  ? 800
                  : constraints.maxWidth >= _kFaqTabletColMin
                  ? 620
                  : double.infinity;

              return Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxColumn),
                  child: ListView(
                    physics: PlatformScrollPhysics.adaptive,
                    padding: const EdgeInsets.fromLTRB(
                      BBSpace.sm,
                      BBSpace.sm,
                      BBSpace.sm,
                      BBSpace.lg,
                    ),
                    children: [
                      const _FaqPremiumHeader(
                        eyebrow: 'POMOĆ · FAQ',
                        title: 'Često postavljana pitanja',
                        subtitle:
                            'Brzi odgovori o rezervacijama, plaćanjima i postavljanju.',
                      ),
                      const SizedBox(height: BBSpace.sm),

                      // Search box (NON-form, free-text filter).
                      BbInput(
                        controller: _searchController,
                        iconLeft: 'search',
                        placeholder: l10n.ownerFaqSearchHint,
                        size: BbInputSize.lg,
                        trailingAction: _searchQuery.isNotEmpty
                            ? _ClearSearchButton(
                                color: c.textTertiary,
                                onTap: () {
                                  setState(() {
                                    _searchController.clear();
                                    _searchQuery = '';
                                  });
                                },
                              )
                            : null,
                        onChanged: (value) {
                          setState(() {
                            _searchQuery = value;
                          });
                        },
                      ),

                      const SizedBox(height: BBSpace.sm),

                      // Category filter chips.
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _categoryKeys.map((categoryKey) {
                          final isSelected =
                              categoryKey == _selectedCategoryKey;
                          return BbChip(
                            label: _getCategoryLabel(categoryKey, l10n),
                            iconLeft: _categoryIconName(categoryKey),
                            selected: isSelected,
                            onTap: () {
                              setState(() {
                                _selectedCategoryKey = categoryKey;
                              });
                            },
                          );
                        }).toList(),
                      ),

                      // Results count line (when filter or search active).
                      if (showResultsHeader) ...[
                        const SizedBox(height: BBSpace.xs),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 4,
                          ),
                          child: Text(
                            l10n.ownerFaqResultsFound(filteredFAQs.length),
                            style: BBType.caption(
                              context,
                            ).copyWith(color: c.textTertiary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],

                      const SizedBox(height: BBSpace.sm),

                      // FAQ list or empty state.
                      if (filteredFAQs.isEmpty)
                        _buildEmptyState(l10n)
                      else
                        ...filteredFAQs.map(
                          (faq) => Padding(
                            padding: const EdgeInsets.only(bottom: BBSpace.xs),
                            child: _FaqExpansionCard(
                              faq: faq,
                              categoryLabel: _getCategoryLabel(
                                faq.categoryKey,
                                l10n,
                              ),
                              iconName: _categoryIconName(faq.categoryKey),
                            ),
                          ),
                        ),

                      // Contact-support card (handoff: bottom of body).
                      const SizedBox(height: BBSpace.sm),
                      _buildContactCard(l10n, c),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(AppLocalizations l10n) {
    return BbEmptyState(
      icon: 'search_off',
      title: l10n.ownerFaqNoResults,
      body: l10n.ownerFaqNoResultsDesc,
      compact: true,
    );
  }

  Widget _buildContactCard(AppLocalizations l10n, BBColorSet c) {
    return BbCard(
      variant: BbCardVariant.accentLeft,
      accentTone: BbCardAccentTone.info,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: c.primary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(BBRadius.sm),
            ),
            child: Center(
              child: BbIcon(name: 'support_agent', size: 26, color: c.primary),
            ),
          ),
          const SizedBox(width: BBSpace.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(l10n.contactSupport, style: BBType.h3(context)),
                const SizedBox(height: 4),
                Text(
                  l10n.contactSupportTeam,
                  style: BBType.caption(
                    context,
                  ).copyWith(color: c.textSecondary),
                ),
                const SizedBox(height: BBSpace.sm),
                // "E-pošta" mailto CTA — audit/145 F3. Live-chat (D2) omitted:
                // no chat backend exists → data-honest omission, not faked.
                BbButton(
                  label: l10n.email,
                  iconLeft: 'mail',
                  variant: BbButtonVariant.secondary,
                  size: BbButtonSize.sm,
                  onPressed: _launchSupportEmail,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// One FAQ accordion card. Stateful so the leading category disc flips to
/// filled-primary (icon white) while expanded — audit/145 F2 (handoff
/// active-state). Expansion tracked via [ExpansionTile.onExpansionChanged].
class _FaqExpansionCard extends StatefulWidget {
  const _FaqExpansionCard({
    required this.faq,
    required this.categoryLabel,
    required this.iconName,
  });

  final FAQItem faq;
  final String categoryLabel;
  final String iconName;

  @override
  State<_FaqExpansionCard> createState() => _FaqExpansionCardState();
}

class _FaqExpansionCardState extends State<_FaqExpansionCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final c = BBColor.of(context);
    final theme = Theme.of(context);
    return BbCard(
      // Per mandate: wrap EACH Q+A pair in its own card (handoff uses one outer
      // card with dividers; per-item mandate recorded as INT drift, audit/145 F1).
      padding: EdgeInsets.zero,
      child: Theme(
        // Strip Material's default divider above ExpansionTile children.
        data: theme.copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          onExpansionChanged: (bool value) => setState(() => _expanded = value),
          tilePadding: const EdgeInsets.symmetric(
            horizontal: BBSpace.sm,
            vertical: 4,
          ),
          childrenPadding: const EdgeInsets.fromLTRB(
            BBSpace.sm,
            0,
            BBSpace.sm,
            BBSpace.sm,
          ),
          iconColor: c.primary,
          collapsedIconColor: c.primary,
          leading: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: _expanded ? c.primary : c.primary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(BBRadius.xs),
            ),
            child: Center(
              child: BbIcon(
                name: widget.iconName,
                size: 18,
                color: _expanded ? Colors.white : c.primary,
              ),
            ),
          ),
          title: Text(widget.faq.question, style: BBType.h3(context)),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              widget.categoryLabel,
              style: BBType.caption(context).copyWith(color: c.textTertiary),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          children: [
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: Text(
                widget.faq.answer,
                style: BBType.body(
                  context,
                ).copyWith(color: c.textSecondary, height: 1.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Premium header (eyebrow + display H1 + subtitle) — audit/117 §B4 pattern.
/// Replaces the legacy `BbSectionHeader` H1 with the Pregled-shaped premium
/// hero. Hardcoded Hr copy keeps parity with other premium headers in
/// `widgets/bookings/bookings_premium_header.dart`.
class _FaqPremiumHeader extends StatelessWidget {
  const _FaqPremiumHeader({
    required this.eyebrow,
    required this.title,
    required this.subtitle,
  });
  final String eyebrow;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final c = BBColor.of(context);
    final bool isMobile = MediaQuery.sizeOf(context).width < 600;
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            eyebrow,
            style: BBType.eyebrow(context).copyWith(color: c.primary),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: BBType.h1(context).copyWith(
              fontSize: isMobile ? 24 : 30,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.6,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: BBType.body(context).copyWith(color: c.textTertiary),
          ),
        ],
      ),
    );
  }
}

/// Inline trailing icon button used to clear the search input.
///
/// Kept as a small private widget so the surrounding `BbInput` stays declarative
/// — `BbInput.trailingAction` accepts any [Widget], and a stateful button needs
/// its own hover/tap surface separate from the input chrome.
class _ClearSearchButton extends StatelessWidget {
  const _ClearSearchButton({required this.color, required this.onTap});
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkResponse(
      onTap: onTap,
      radius: 18,
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: BbIcon(name: 'close', size: 18, color: color),
      ),
    );
  }
}
