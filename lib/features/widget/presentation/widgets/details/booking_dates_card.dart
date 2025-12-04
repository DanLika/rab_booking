import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../../core/design_tokens/design_tokens.dart';
import '../../../../../core/utils/date_time_parser.dart';
import '../common/detail_row_widget.dart';

/// Card displaying booking dates and guest information.
///
/// Shows check-in, check-out, nights, and guest count in a consistent detail row format.
///
/// Usage:
/// ```dart
/// BookingDatesCard(
///   checkIn: '2024-01-15',
///   checkOut: '2024-01-20',
///   nights: 5,
///   adults: 2,
///   children: 1,
///   colors: ColorTokens.light,
///   isDarkMode: false,
/// )
/// ```
class BookingDatesCard extends StatelessWidget {
  /// Check-in date string (ISO format)
  final String checkIn;

  /// Check-out date string (ISO format)
  final String checkOut;

  /// Number of nights
  final int nights;

  /// Number of adults
  final int adults;

  /// Number of children
  final int children;

  /// Color tokens for theming
  final WidgetColorScheme colors;

  /// Whether dark mode is active
  final bool isDarkMode;

  const BookingDatesCard({
    super.key,
    required this.checkIn,
    required this.checkOut,
    required this.nights,
    required this.adults,
    required this.children,
    required this.colors,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    final checkInDate = DateTimeParser.parseOrThrow(
      checkIn,
      context: 'BookingDatesCard.checkIn',
    );
    final checkOutDate = DateTimeParser.parseOrThrow(
      checkOut,
      context: 'BookingDatesCard.checkOut',
    );
    // Match BookingSummaryCard date format
    final formatter = DateFormat('EEEE, MMM dd, yyyy');

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
          // Header matching BookingSummaryCard style
          Text(
            'Booking Dates',
            style: TextStyle(
              fontSize: TypographyTokens.fontSizeL,
              fontWeight: TypographyTokens.bold,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: SpacingTokens.m),
          // Use DetailRowWidget for consistent styling
          DetailRowWidget(
            label: 'Check-in',
            value: formatter.format(checkInDate),
            isDarkMode: isDarkMode,
            hasPadding: true,
            valueFontWeight: FontWeight.w400,
          ),
          DetailRowWidget(
            label: 'Check-out',
            value: formatter.format(checkOutDate),
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
            value: _formatGuestCount(),
            isDarkMode: isDarkMode,
            hasPadding: true,
            valueFontWeight: FontWeight.w400,
          ),
        ],
      ),
    );
  }

  String _formatGuestCount() {
    final adultsText = '$adults adult${adults > 1 ? 's' : ''}';
    if (children > 0) {
      return '$adultsText, $children child${children > 1 ? 'ren' : ''}';
    }
    return adultsText;
  }
}
