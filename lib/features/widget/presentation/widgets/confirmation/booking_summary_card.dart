import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../../core/design_tokens/design_tokens.dart';
import '../common/detail_row_widget.dart';

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
    return Container(
      padding: const EdgeInsets.all(SpacingTokens.m),
      decoration: BoxDecoration(
        color: colors.backgroundSecondary,
        borderRadius: BorderTokens.circularMedium,
        border: Border.all(
          color: colors.borderDefault,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Booking Details',
            style: TextStyle(
              fontSize: TypographyTokens.fontSizeL,
              fontWeight: TypographyTokens.bold,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: SpacingTokens.m),
          DetailRowWidget(
            label: 'Property',
            value: unitName ?? propertyName,
            isDarkMode: isDarkMode,
            hasPadding: true,
            valueFontWeight: FontWeight.w400,
          ),
          DetailRowWidget(
            label: 'Guest',
            value: guestName,
            isDarkMode: isDarkMode,
            hasPadding: true,
            valueFontWeight: FontWeight.w400,
          ),
          DetailRowWidget(
            label: 'Email',
            value: guestEmail,
            isDarkMode: isDarkMode,
            hasPadding: true,
            valueFontWeight: FontWeight.w400,
          ),
          const SizedBox(height: SpacingTokens.s),
          DetailRowWidget(
            label: 'Check-in',
            value: DateFormat('EEEE, MMM dd, yyyy').format(checkIn),
            isDarkMode: isDarkMode,
            hasPadding: true,
            valueFontWeight: FontWeight.w400,
          ),
          DetailRowWidget(
            label: 'Check-out',
            value: DateFormat('EEEE, MMM dd, yyyy').format(checkOut),
            isDarkMode: isDarkMode,
            hasPadding: true,
            valueFontWeight: FontWeight.w400,
          ),
          DetailRowWidget(
            label: 'Duration',
            value: '$nights ${nights == 1 ? 'night' : 'nights'}',
            isDarkMode: isDarkMode,
            hasPadding: true,
            valueFontWeight: FontWeight.w400,
          ),
          DetailRowWidget(
            label: 'Guests',
            value: '$guests ${guests == 1 ? 'guest' : 'guests'}',
            isDarkMode: isDarkMode,
            hasPadding: true,
            valueFontWeight: FontWeight.w400,
          ),
          const SizedBox(height: SpacingTokens.s),
          DetailRowWidget(
            label: 'Total Price',
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
