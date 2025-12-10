import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../../core/design_tokens/design_tokens.dart';
import '../../l10n/widget_translations.dart';
import '../../theme/minimalist_colors.dart';
import 'price_breakdown_widget.dart';

/// Compact summary displayed in the pill bar showing dates, price, and reserve button.
///
/// Extracted from booking_widget_screen.dart _buildCompactPillSummary method.
/// Shows date range, nights badge, price breakdown, and optional reserve button.
///
/// Usage:
/// ```dart
/// CompactPillSummary(
///   checkIn: _checkIn,
///   checkOut: _checkOut,
///   nights: 3,
///   formattedRoomPrice: '€300.00',
///   additionalServicesTotal: 50.0,
///   formattedAdditionalServices: '€50.00',
///   formattedTotal: '€350.00',
///   formattedDeposit: '€70.00',
///   depositPercentage: 20,
///   isDarkMode: isDarkMode,
///   showReserveButton: !_showGuestForm,
///   onClose: () => setState(() => _pillBarDismissed = true),
///   onReserve: () => setState(() => _showGuestForm = true),
/// )
/// ```
class CompactPillSummary extends StatelessWidget {
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

  /// Whether to show the Reserve button
  final bool showReserveButton;

  /// Callback when close button is tapped
  final VoidCallback onClose;

  /// Callback when Reserve button is tapped
  final VoidCallback onReserve;

  /// Translations for localization
  final WidgetTranslations translations;

  const CompactPillSummary({
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
    required this.showReserveButton,
    required this.onClose,
    required this.onReserve,
    required this.translations,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM dd, yyyy');
    final colors = MinimalistColorSchemeAdapter(dark: isDarkMode);

    return Column(
      children: [
        // Close button at top
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            InkWell(
              onTap: onClose,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: isDarkMode ? ColorTokens.pureWhite : colors.backgroundSecondary,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: colors.borderLight),
                ),
                child: Icon(Icons.close, size: 16, color: isDarkMode ? ColorTokens.pureBlack : colors.textSecondary),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Range info with nights badge (responsive layout)
        LayoutBuilder(
          builder: (context, constraints) {
            // Use column layout on very narrow screens (< 280px content width)
            final useColumnLayout = constraints.maxWidth < 280;

            final nightsBadge = Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: colors.statusAvailableBackground,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                translations.nightCount(nights),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.white : Colors.black87,
                ),
              ),
            );

            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: colors.buttonPrimary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: colors.buttonPrimary.withValues(alpha: 0.3)),
              ),
              child: useColumnLayout
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.calendar_month, size: 16, color: colors.buttonPrimary),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                '${dateFormat.format(checkIn)} - ${dateFormat.format(checkOut)}',
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: colors.textPrimary),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        nightsBadge,
                      ],
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.calendar_month, size: 16, color: colors.buttonPrimary),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            '${dateFormat.format(checkIn)} - ${dateFormat.format(checkOut)}',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: colors.textPrimary),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        nightsBadge,
                      ],
                    ),
            );
          },
        ),
        const SizedBox(height: 12),

        // Price breakdown section
        PriceBreakdownWidget(
          isDarkMode: isDarkMode,
          nights: nights,
          formattedRoomPrice: formattedRoomPrice,
          additionalServicesTotal: additionalServicesTotal,
          formattedAdditionalServices: formattedAdditionalServices,
          formattedTotal: formattedTotal,
          formattedDeposit: formattedDeposit,
          depositPercentage: depositPercentage,
          translations: translations,
        ),

        const SizedBox(height: 12),

        // Reserve button (only show when guest form is NOT visible)
        if (showReserveButton)
          InkWell(
            onTap: onReserve,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              decoration: BoxDecoration(color: colors.buttonPrimary, borderRadius: BorderRadius.circular(20)),
              child: Text(
                translations.reserve,
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: colors.buttonPrimaryText),
              ),
            ),
          ),
      ],
    );
  }
}
