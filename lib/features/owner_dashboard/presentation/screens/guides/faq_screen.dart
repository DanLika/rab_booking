import 'package:flutter/material.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../../core/design/tokens.dart';
import '../../../../../core/utils/platform_scroll_physics.dart';
import '../../../../../core/theme/gradient_extensions.dart';
import '../../../../../shared/widgets/common_app_bar.dart';
import '../../../../../shared/widgets/redesign.dart';
import '../../widgets/owner_app_drawer.dart';

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
    final theme = Theme.of(context);
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
              final double maxColumn = constraints.maxWidth >= 1024
                  ? 800
                  : constraints.maxWidth >= 600
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
                      // Section header — page title repeated inside body per
                      // handoff (CommonAppBar still owns the bar-level title).
                      BbSectionHeader(
                        title: l10n.ownerFaqTitle,
                        level: BbSectionHeaderLevel.h1,
                      ),

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
                            child: _buildFAQCard(faq, l10n, c, theme),
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

  Widget _buildFAQCard(
    FAQItem faq,
    AppLocalizations l10n,
    BBColorSet c,
    ThemeData theme,
  ) {
    final categoryLabel = _getCategoryLabel(faq.categoryKey, l10n);
    final iconName = _categoryIconName(faq.categoryKey);

    return BbCard(
      // Per mandate: wrap EACH Q+A pair in its own card. (Handoff JSX wraps
      // the whole list in one outer card with row dividers; mandate is
      // explicit on per-item cards — recorded as INT drift in PR body.)
      padding: EdgeInsets.zero,
      child: Theme(
        // Strip Material's default divider above ExpansionTile children.
        data: theme.copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
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
          leading: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: c.primary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(BBRadius.xs),
            ),
            child: Center(
              child: BbIcon(name: iconName, size: 18, color: c.primary),
            ),
          ),
          title: Text(faq.question, style: BBType.h3(context)),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              categoryLabel,
              style: BBType.caption(context).copyWith(color: c.textTertiary),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          children: [
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: Text(
                faq.answer,
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
              ],
            ),
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
