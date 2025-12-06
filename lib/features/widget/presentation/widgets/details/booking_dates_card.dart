import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../../core/design_tokens/design_tokens.dart';
import '../../../../../core/utils/date_time_parser.dart';
import '../common/detail_row_widget.dart';
import '../../l10n/widget_translations.dart';

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
    final tr = WidgetTranslations.of(context);
    final checkInDate = DateTimeParser.parseOrThrow(checkIn, context: 'BookingDatesCard.checkIn');
    final checkOutDate = DateTimeParser.parseOrThrow(checkOut, context: 'BookingDatesCard.checkOut');
    // Match BookingSummaryCard date format
    final formatter = DateFormat('EEEE, MMM dd, yyyy');

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
          // Header matching BookingSummaryCard style
          Text(
            tr.bookingDates,
            style: TextStyle(
              fontSize: TypographyTokens.fontSizeL,
              fontWeight: TypographyTokens.bold,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: SpacingTokens.m),
          // Use DetailRowWidget for consistent styling
          DetailRowWidget(
            label: tr.checkIn,
            value: formatter.format(checkInDate),
            isDarkMode: isDarkMode,
            hasPadding: true,
            valueFontWeight: FontWeight.w400,
          ),
          DetailRowWidget(
            label: tr.checkOut,
            value: formatter.format(checkOutDate),
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
            value: _formatGuestCount(tr),
            isDarkMode: isDarkMode,
            hasPadding: true,
            valueFontWeight: FontWeight.w400,
          ),
        ],
      ),
    );
  }

  String _formatGuestCount(WidgetTranslations tr) {
    final adultsText = tr.adultsCount(adults);
    if (children > 0) {
      return '$adultsText, ${tr.childrenCount(children)}';
    }
    return adultsText;
  }
}
