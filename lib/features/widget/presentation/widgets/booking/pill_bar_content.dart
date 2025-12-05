import 'package:flutter/material.dart';
import '../../l10n/widget_translations.dart';
import '../../theme/minimalist_colors.dart';
import 'compact_pill_summary.dart';

/// Content widget for the booking pill bar.
///
/// Handles layout switching between compact (mobile) and wide-screen (desktop) layouts.
/// Uses [CompactPillSummary] for the compact view and a 2-column layout for wide screens.
///
/// Extracted from booking_widget_screen.dart _buildPillBarContent method.
///
/// Usage:
/// ```dart
/// PillBarContent(
///   checkIn: _checkIn!,
///   checkOut: _checkOut!,
///   nights: 3,
///   formattedRoomPrice: '€300.00',
///   additionalServicesTotal: 0.0,
///   formattedAdditionalServices: '€0.00',
///   formattedTotal: '€300.00',
///   formattedDeposit: '€60.00',
///   depositPercentage: 20,
///   isDarkMode: isDarkMode,
///   showGuestForm: _showGuestForm,
///   isWideScreen: screenWidth >= 768,
///   onClose: () => setState(() => _pillBarDismissed = true),
///   onReserve: () => setState(() => _showGuestForm = true),
///   guestFormBuilder: () => _buildGuestInfoForm(calculation),
///   paymentSectionBuilder: () => _buildPaymentSection(calculation),
///   additionalServicesBuilder: () => AdditionalServicesWidget(...),
///   taxLegalBuilder: () => TaxLegalDisclaimerWidget(...),
/// )
/// ```
class PillBarContent extends StatelessWidget {
  /// Check-in date
  final DateTime checkIn;

  /// Check-out date
  final DateTime checkOut;

  /// Number of nights
  final int nights;

  /// Formatted room price string
  final String formattedRoomPrice;

  /// Additional services total amount
  final double additionalServicesTotal;

  /// Formatted additional services string
  final String formattedAdditionalServices;

  /// Formatted total price string
  final String formattedTotal;

  /// Formatted deposit amount string
  final String formattedDeposit;

  /// Deposit percentage
  final int depositPercentage;

  /// Whether dark mode is active
  final bool isDarkMode;

  /// Whether the guest form is currently shown
  final bool showGuestForm;

  /// Whether the screen is wide (>= 768px)
  final bool isWideScreen;

  /// Callback when close button is tapped
  final VoidCallback onClose;

  /// Callback when Reserve button is tapped
  final VoidCallback onReserve;

  /// Builder for the guest info form widget
  final Widget Function() guestFormBuilder;

  /// Builder for the payment section widget
  final Widget Function() paymentSectionBuilder;

  /// Builder for the additional services widget
  final Widget Function() additionalServicesBuilder;

  /// Builder for the tax/legal disclaimer widget
  final Widget Function() taxLegalBuilder;

  /// Translations for localization
  final WidgetTranslations translations;

  const PillBarContent({
    super.key,
    required this.checkIn,
    required this.checkOut,
    required this.nights,
    required this.formattedRoomPrice,
    required this.additionalServicesTotal,
    required this.formattedAdditionalServices,
    required this.formattedTotal,
    required this.formattedDeposit,
    required this.depositPercentage,
    required this.isDarkMode,
    required this.showGuestForm,
    required this.isWideScreen,
    required this.onClose,
    required this.onReserve,
    required this.guestFormBuilder,
    required this.paymentSectionBuilder,
    required this.additionalServicesBuilder,
    required this.taxLegalBuilder,
    required this.translations,
  });

  @override
  Widget build(BuildContext context) {
    // If guest form is shown and screen is wide, show 2-column layout
    if (showGuestForm && isWideScreen) {
      return _buildWideScreenLayout(context);
    }

    // Default: show compact summary with optional mobile guest form
    return _buildCompactLayout();
  }

  /// Build wide-screen 2-column layout (guest info left, payment right)
  Widget _buildWideScreenLayout(BuildContext context) {
    final colors = MinimalistColorSchemeAdapter(dark: isDarkMode);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Top bar with drag handle and close button
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Spacer(),
            // Drag handle indicator (centered)
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(color: colors.borderLight, borderRadius: BorderRadius.circular(2)),
            ),
            const Spacer(),
            // Close button (right)
            InkWell(
              onTap: onClose,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: colors.backgroundSecondary,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: colors.borderLight),
                ),
                child: Icon(Icons.close, size: 16, color: colors.textSecondary),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // 2-column layout: Guest info (left) | Payment options (right)
        ConstrainedBox(
          constraints: BoxConstraints(
            // Bug #46: Account for keyboard when calculating max height
            maxHeight: (MediaQuery.of(context).size.height - MediaQuery.of(context).viewInsets.bottom) * 0.6,
          ),
          child: SingleChildScrollView(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left column: Guest info + Additional Services (55%)
                Expanded(
                  flex: 55,
                  child: Column(
                    children: [
                      guestFormBuilder(),
                      // Additional Services section
                      additionalServicesBuilder(),
                      // Tax/Legal Disclaimer section
                      taxLegalBuilder(),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                // Right column: Payment options + button (45%)
                Expanded(flex: 45, child: paymentSectionBuilder()),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Build compact layout (mobile) with optional guest form
  Widget _buildCompactLayout() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CompactPillSummary(
          checkIn: checkIn,
          checkOut: checkOut,
          nights: nights,
          formattedRoomPrice: formattedRoomPrice,
          additionalServicesTotal: additionalServicesTotal,
          formattedAdditionalServices: formattedAdditionalServices,
          formattedTotal: formattedTotal,
          formattedDeposit: formattedDeposit,
          depositPercentage: depositPercentage,
          isDarkMode: isDarkMode,
          showReserveButton: !showGuestForm,
          onClose: onClose,
          onReserve: onReserve,
          translations: translations,
        ),
        // Show guest form if needed (mobile)
        if (showGuestForm && !isWideScreen) ...[
          const SizedBox(height: 12),
          guestFormBuilder(),
          // Additional Services section
          additionalServicesBuilder(),
          // Tax/Legal Disclaimer section
          taxLegalBuilder(),
          const SizedBox(height: 16),
          paymentSectionBuilder(),
        ],
      ],
    );
  }
}
