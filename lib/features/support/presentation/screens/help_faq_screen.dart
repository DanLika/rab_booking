import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../l10n/app_localizations.dart';

class HelpFaqScreen extends StatefulWidget {
  const HelpFaqScreen({super.key});

  @override
  State<HelpFaqScreen> createState() => _HelpFaqScreenState();
}

class _HelpFaqScreenState extends State<HelpFaqScreen> {
  String _selectedCategory = 'all';
  String _searchQuery = '';

  List<FaqItem> _getFaqItems(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return [
      // Booking FAQs
      FaqItem(
        category: 'booking',
        question: l10n.faqHowToBook,
        answer: l10n.faqHowToBookAnswer,
      ),
      FaqItem(
        category: 'booking',
        question: l10n.faqModifyBooking,
        answer: l10n.faqModifyBookingAnswer,
      ),
      FaqItem(
        category: 'booking',
        question: l10n.faqBookingConfirmed,
        answer: l10n.faqBookingConfirmedAnswer,
      ),

      // Payment FAQs
      FaqItem(
        category: 'payment',
        question: l10n.faqPaymentMethods,
        answer: l10n.faqPaymentMethodsAnswer,
      ),
      FaqItem(
        category: 'payment',
        question: l10n.faqWhenCharged,
        answer: l10n.faqWhenChargedAnswer,
      ),
      FaqItem(
        category: 'payment',
        question: l10n.faqAdditionalFees,
        answer: l10n.faqAdditionalFeesAnswer,
      ),

      // Cancellation FAQs
      FaqItem(
        category: 'cancellation',
        question: l10n.faqCancellationPolicy,
        answer: l10n.faqCancellationPolicyAnswer,
      ),
      FaqItem(
        category: 'cancellation',
        question: l10n.faqHowToCancel,
        answer: l10n.faqHowToCancelAnswer,
      ),
      FaqItem(
        category: 'cancellation',
        question: l10n.faqFullRefund,
        answer: l10n.faqFullRefundAnswer,
      ),

      // Property FAQs
      FaqItem(
        category: 'property',
        question: l10n.faqContactOwner,
        answer: l10n.faqContactOwnerAnswer,
      ),
      FaqItem(
        category: 'property',
        question: l10n.faqPropertyMismatch,
        answer: l10n.faqPropertyMismatchAnswer,
      ),
      FaqItem(
        category: 'property',
        question: l10n.faqLeaveReview,
        answer: l10n.faqLeaveReviewAnswer,
      ),

      // Account FAQs
      FaqItem(
        category: 'account',
        question: l10n.faqCreateAccount,
        answer: l10n.faqCreateAccountAnswer,
      ),
      FaqItem(
        category: 'account',
        question: l10n.faqForgotPassword,
        answer: l10n.faqForgotPasswordAnswer,
      ),
      FaqItem(
        category: 'account',
        question: l10n.faqUpdateProfile,
        answer: l10n.faqUpdateProfileAnswer,
      ),
    ];
  }

  List<FaqCategory> _getCategories(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return [
      FaqCategory(id: 'all', name: l10n.allTopics, icon: Icons.list),
      FaqCategory(id: 'booking', name: l10n.faqBooking, icon: Icons.book_online),
      FaqCategory(id: 'payment', name: l10n.faqPayment, icon: Icons.payment),
      FaqCategory(id: 'cancellation', name: l10n.faqCancellation, icon: Icons.cancel),
      FaqCategory(id: 'property', name: l10n.faqProperty, icon: Icons.home),
      FaqCategory(id: 'account', name: l10n.faqAccount, icon: Icons.person),
    ];
  }

  List<FaqItem> get _filteredFaqItems {
    final faqItems = _getFaqItems(context);

    return faqItems.where((item) {
      final matchesCategory =
          _selectedCategory == 'all' || item.category == _selectedCategory;
      final matchesSearch = _searchQuery.isEmpty ||
          item.question.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          item.answer.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesCategory && matchesSearch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final categories = _getCategories(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.helpFaq),
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: InputDecoration(
                hintText: l10n.searchForHelp,
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: AppColors.surface,
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),

          // Category chips
          SizedBox(
            height: 50,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final category = categories[index];
                final isSelected = _selectedCategory == category.id;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          category.icon,
                          size: 16,
                          color: isSelected ? Colors.white : AppColors.textPrimary,
                        ),
                        const SizedBox(width: 4),
                        Text(category.name),
                      ],
                    ),
                    selected: isSelected,
                    onSelected: (_) {
                      setState(() {
                        _selectedCategory = category.id;
                      });
                    },
                    selectedColor: AppColors.primary,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 16),

          // FAQ List
          Expanded(
            child: _filteredFaqItems.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.search_off,
                          size: 64,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          l10n.noResultsFound,
                          style: AppTypography.h3.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          l10n.tryDifferentSearch,
                          style: AppTypography.bodyMedium.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _filteredFaqItems.length,
                    itemBuilder: (context, index) {
                      final item = _filteredFaqItems[index];
                      return _FaqTile(item: item);
                    },
                  ),
          ),

          // Contact Support Section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              border: Border(
                top: BorderSide(color: AppColors.divider),
              ),
            ),
            child: Column(
              children: [
                Text(
                  l10n.stillNeedHelp,
                  style: AppTypography.h3.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.contactSupportTeam,
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pushNamed(context, '/contact');
                  },
                  icon: const Icon(Icons.contact_support),
                  label: Text(l10n.contactSupport),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FaqTile extends StatefulWidget {
  final FaqItem item;

  const _FaqTile({required this.item});

  @override
  State<_FaqTile> createState() => _FaqTileState();
}

class _FaqTileState extends State<_FaqTile> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          title: Text(
            widget.item.question,
            style: AppTypography.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          trailing: Icon(
            _isExpanded ? Icons.remove : Icons.add,
            color: AppColors.primary,
          ),
          onExpansionChanged: (expanded) {
            setState(() {
              _isExpanded = expanded;
            });
          },
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                widget.item.answer,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.6,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class FaqCategory {
  final String id;
  final String name;
  final IconData icon;

  const FaqCategory({
    required this.id,
    required this.name,
    required this.icon,
  });
}

class FaqItem {
  final String category;
  final String question;
  final String answer;

  const FaqItem({
    required this.category,
    required this.question,
    required this.answer,
  });
}
