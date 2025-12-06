import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../../core/design_tokens/design_tokens.dart';
import '../common/detail_row_widget.dart';
import '../../l10n/widget_translations.dart';

/// Card displaying booking summary details.
///
/// Shows property, guest info, dates, duration, guests, and total price.
/// Uses DetailRowWidget for consistent styling.
///
/// Usage:
/// ```dart
/// BookingSummaryCard(
///   propertyName: 'Beach Villa',
///   unitName: 'Suite 1',
///   guestName: 'John Doe',
///   guestEmail: 'john@example.com',
///   checkIn: DateTime(2024, 1, 15),
///   checkOut: DateTime(2024, 1, 20),
///   nights: 5,
///   guests: 2,
///   totalPrice: 500.00,
///   isDarkMode: false,
///   colors: ColorTokens.light,
/// )
/// ```
class BookingSummaryCard extends StatelessWidget {
  /// Property name
  final String propertyName;

  /// Optional unit name (displays unit name if available, otherwise property name)
  final String? unitName;

  /// Guest full name
  final String guestName;

  /// Guest email address
  final String guestEmail;

  /// Check-in date
  final DateTime checkIn;

  /// Check-out date
  final DateTime checkOut;

  /// Number of nights
  final int nights;

  /// Number of guests
  final int guests;

  /// Total price
  final double totalPrice;

  /// Whether dark mode is active (for DetailRowWidget)
  final bool isDarkMode;

  /// Color tokens for theming
  final WidgetColorScheme colors;

  const BookingSummaryCard({
    super.key,
    required this.propertyName,
    this.unitName,
    required this.guestName,
    required this.guestEmail,
    required this.checkIn,
    required this.checkOut,
    required this.nights,
    required this.guests,
    required this.totalPrice,
    required this.isDarkMode,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    final tr = WidgetTranslations.of(context);
    // Use backgroundTertiary in dark mode for better contrast
    final cardBackground = isDarkMode ? colors.backgroundTertiary : colors.backgroundSecondary;
    final cardBorder = isDarkMode ? colors.borderMedium : colors.borderDefault;

    return Container(
      padding: const EdgeInsets.all(SpacingTokens.m),
      decoration: BoxDecoration(
        color: cardBackground,
        borderRadius: BorderTokens.circularMedium,
        border: Border.all(color: cardBorder, width: isDarkMode ? 1.5 : 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            tr.bookingDetails,
            style: TextStyle(
              fontSize: TypographyTokens.fontSizeL,
              fontWeight: TypographyTokens.bold,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: SpacingTokens.m),
          DetailRowWidget(
            label: tr.property,
            value: unitName ?? propertyName,
            isDarkMode: isDarkMode,
            hasPadding: true,
            valueFontWeight: FontWeight.w400,
          ),
          DetailRowWidget(
            label: tr.guest,
            value: guestName,
            isDarkMode: isDarkMode,
            hasPadding: true,
            valueFontWeight: FontWeight.w400,
          ),
          DetailRowWidget(
            label: tr.email,
            value: guestEmail,
            isDarkMode: isDarkMode,
            hasPadding: true,
            valueFontWeight: FontWeight.w400,
          ),
          const SizedBox(height: SpacingTokens.s),
          DetailRowWidget(
            label: tr.checkIn,
            value: DateFormat('EEEE, MMM dd, yyyy').format(checkIn),
            isDarkMode: isDarkMode,
            hasPadding: true,
            valueFontWeight: FontWeight.w400,
          ),
          DetailRowWidget(
            label: tr.checkOut,
            value: DateFormat('EEEE, MMM dd, yyyy').format(checkOut),
            isDarkMode: isDarkMode,
            hasPadding: true,
            valueFontWeight: FontWeight.w400,
          ),
          DetailRowWidget(
            label: tr.duration,
            value: tr.nightCount(nights),
            isDarkMode: isDarkMode,
            hasPadding: true,
            valueFontWeight: FontWeight.w400,
          ),
          DetailRowWidget(
            label: tr.guests,
            value: tr.guestCount(guests),
            isDarkMode: isDarkMode,
            hasPadding: true,
            valueFontWeight: FontWeight.w400,
          ),
          const SizedBox(height: SpacingTokens.s),
          DetailRowWidget(
            label: tr.totalPrice,
            value: '€${totalPrice.toStringAsFixed(2)}',
            isDarkMode: isDarkMode,
            hasPadding: true,
            isHighlighted: true,
          ),
        ],
      ),
    );
  }
}
