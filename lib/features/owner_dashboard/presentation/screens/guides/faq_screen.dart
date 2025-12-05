import 'package:flutter/material.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../../core/theme/app_shadows.dart';
import '../../../../../core/theme/gradient_extensions.dart';
import '../../../../../shared/widgets/common_app_bar.dart';
import '../../widgets/owner_app_drawer.dart';

class FAQItem {
  final String question;
  final String answer;
  final String categoryKey; // Internal key for filtering

  const FAQItem({required this.question, required this.answer, required this.categoryKey});
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
  static const List<String> _categoryKeys = ['all', 'general', 'bookings', 'payments', 'widget', 'icalSync', 'support'];

  String _getCategoryLabel(String key, AppLocalizations l10n) {
    switch (key) {
      case 'all':
        return l10n.ownerFaqCategoryAll;
      case 'general':
        return l10n.ownerFaqCategoryGeneral;
      case 'bookings':
        return l10n.ownerFaqCategoryBookings;
      case 'payments':
        return l10n.ownerFaqCategoryPayments;
      case 'widget':
        return l10n.ownerFaqCategoryWidget;
      case 'icalSync':
        return l10n.ownerFaqCategoryIcalSync;
      case 'support':
        return l10n.ownerFaqCategorySupport;
      default:
        return key;
    }
  }

  List<FAQItem> _getAllFAQs(AppLocalizations l10n) {
    return [
      // General
      FAQItem(categoryKey: 'general', question: l10n.ownerFaqGeneral1Q, answer: l10n.ownerFaqGeneral1A),
      FAQItem(categoryKey: 'general', question: l10n.ownerFaqGeneral2Q, answer: l10n.ownerFaqGeneral2A),
      FAQItem(categoryKey: 'general', question: l10n.ownerFaqGeneral3Q, answer: l10n.ownerFaqGeneral3A),
      // Bookings
      FAQItem(categoryKey: 'bookings', question: l10n.ownerFaqBookings1Q, answer: l10n.ownerFaqBookings1A),
      FAQItem(categoryKey: 'bookings', question: l10n.ownerFaqBookings2Q, answer: l10n.ownerFaqBookings2A),
      FAQItem(categoryKey: 'bookings', question: l10n.ownerFaqBookings3Q, answer: l10n.ownerFaqBookings3A),
      FAQItem(categoryKey: 'bookings', question: l10n.ownerFaqBookings4Q, answer: l10n.ownerFaqBookings4A),
      FAQItem(categoryKey: 'bookings', question: l10n.ownerFaqBookings5Q, answer: l10n.ownerFaqBookings5A),
      // Payments
      FAQItem(categoryKey: 'payments', question: l10n.ownerFaqPayments1Q, answer: l10n.ownerFaqPayments1A),
      FAQItem(categoryKey: 'payments', question: l10n.ownerFaqPayments2Q, answer: l10n.ownerFaqPayments2A),
      FAQItem(categoryKey: 'payments', question: l10n.ownerFaqPayments3Q, answer: l10n.ownerFaqPayments3A),
      FAQItem(categoryKey: 'payments', question: l10n.ownerFaqPayments4Q, answer: l10n.ownerFaqPayments4A),
      // Widget
      FAQItem(categoryKey: 'widget', question: l10n.ownerFaqWidget1Q, answer: l10n.ownerFaqWidget1A),
      FAQItem(categoryKey: 'widget', question: l10n.ownerFaqWidget2Q, answer: l10n.ownerFaqWidget2A),
      FAQItem(categoryKey: 'widget', question: l10n.ownerFaqWidget3Q, answer: l10n.ownerFaqWidget3A),
      FAQItem(categoryKey: 'widget', question: l10n.ownerFaqWidget4Q, answer: l10n.ownerFaqWidget4A),
      FAQItem(categoryKey: 'widget', question: l10n.ownerFaqWidget5Q, answer: l10n.ownerFaqWidget5A),
      // iCal Sync
      FAQItem(categoryKey: 'icalSync', question: l10n.ownerFaqIcal1Q, answer: l10n.ownerFaqIcal1A),
      FAQItem(categoryKey: 'icalSync', question: l10n.ownerFaqIcal2Q, answer: l10n.ownerFaqIcal2A),
      FAQItem(categoryKey: 'icalSync', question: l10n.ownerFaqIcal3Q, answer: l10n.ownerFaqIcal3A),
      FAQItem(categoryKey: 'icalSync', question: l10n.ownerFaqIcal4Q, answer: l10n.ownerFaqIcal4A),
      // Technical Support
      FAQItem(categoryKey: 'support', question: l10n.ownerFaqSupport1Q, answer: l10n.ownerFaqSupport1A),
      FAQItem(categoryKey: 'support', question: l10n.ownerFaqSupport2Q, answer: l10n.ownerFaqSupport2A),
      FAQItem(categoryKey: 'support', question: l10n.ownerFaqSupport3Q, answer: l10n.ownerFaqSupport3A),
      FAQItem(categoryKey: 'support', question: l10n.ownerFaqSupport4Q, answer: l10n.ownerFaqSupport4A),
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
      faqs = faqs.where((faq) => faq.categoryKey == _selectedCategoryKey).toList();
    }

    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      faqs = faqs.where((faq) {
        final query = _searchQuery.toLowerCase();
        return faq.question.toLowerCase().contains(query) || faq.answer.toLowerCase().contains(query);
      }).toList();
    }

    return faqs;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final filteredFAQs = _filteredFAQs;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      drawer: const OwnerAppDrawer(currentRoute: 'guides/faq'),
      appBar: CommonAppBar(
        title: l10n.ownerFaqTitle,
        leadingIcon: Icons.menu,
        onLeadingIconTap: (context) => Scaffold.of(context).openDrawer(),
      ),
      body: Container(
        decoration: BoxDecoration(gradient: context.gradients.pageBackground),
        child: SafeArea(
          child: Column(
            children: [
              // Search Bar
              Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: l10n.ownerFaqSearchHint,
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              setState(() {
                                _searchController.clear();
                                _searchQuery = '';
                              });
                            },
                          )
                        : null,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                ),
              ),

              // Category Filter
              SizedBox(
                height: 50,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: _categoryKeys.length,
                  itemBuilder: (context, index) {
                    final categoryKey = _categoryKeys[index];
                    final isSelected = categoryKey == _selectedCategoryKey;

                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: FilterChip(
                        label: Text(_getCategoryLabel(categoryKey, l10n)),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            _selectedCategoryKey = categoryKey;
                          });
                        },
                        backgroundColor: isDark ? theme.colorScheme.surfaceContainerHighest : Colors.grey.shade200,
                        selectedColor: isDark
                            ? theme.colorScheme.primary.withAlpha((0.4 * 255).toInt())
                            : theme.colorScheme.primary.withAlpha((0.2 * 255).toInt()),
                        checkmarkColor: theme.colorScheme.primary,
                        labelStyle: TextStyle(
                          color: isSelected
                              ? (isDark ? Colors.white : theme.colorScheme.primary)
                              : (isDark ? theme.colorScheme.onSurfaceVariant : Colors.grey.shade700),
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    );
                  },
                ),
              ),

              const Divider(),

              // Results Count
              if (_searchQuery.isNotEmpty || _selectedCategoryKey != 'all')
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Text(
                    l10n.ownerFaqResultsFound(filteredFAQs.length),
                    style: TextStyle(
                      color: isDark ? theme.colorScheme.onSurfaceVariant : Colors.grey.shade600,
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),

              // FAQ List
              Expanded(
                child: filteredFAQs.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: filteredFAQs.length,
                        itemBuilder: (context, index) {
                          final faq = filteredFAQs[index];
                          return _buildFAQCard(faq);
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFAQCard(FAQItem faq) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        gradient: context.gradients.sectionBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.gradients.sectionBorder.withAlpha((0.5 * 255).toInt())),
        boxShadow: isDark ? AppShadows.elevation2Dark : AppShadows.elevation2,
      ),
      child: Theme(
        data: theme.copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          leading: CircleAvatar(
            backgroundColor: theme.colorScheme.primary.withAlpha((0.1 * 255).toInt()),
            child: Icon(_getCategoryIcon(faq.category), color: theme.colorScheme.primary, size: 20),
          ),
          title: Text(faq.question, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              faq.category,
              style: TextStyle(fontSize: 11, color: isDark ? theme.colorScheme.onSurfaceVariant : Colors.grey.shade600),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                faq.answer,
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? theme.colorScheme.onSurface : Colors.grey.shade800,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: isDark ? theme.colorScheme.onSurfaceVariant : Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              l10n.ownerFaqNoResults,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? theme.colorScheme.onSurface : Colors.grey.shade600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Text(
              l10n.ownerFaqNoResultsDesc,
              style: TextStyle(color: isDark ? theme.colorScheme.onSurfaceVariant : Colors.grey.shade500),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Općenito':
        return Icons.info_outline;
      case 'Rezervacije':
        return Icons.event;
      case 'Plaćanja':
        return Icons.payment;
      case 'Widget':
        return Icons.widgets;
      case 'iCal Sync':
        return Icons.sync;
      case 'Tehnička Podrška':
        return Icons.support;
      default:
        return Icons.help_outline;
    }
  }
}
