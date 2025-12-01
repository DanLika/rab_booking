import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../../core/design_tokens/design_tokens.dart';

/// Card displaying booking dates and guest information.
///
/// Shows check-in, check-out, nights, and guest count.
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

  const BookingDatesCard({
    super.key,
    required this.checkIn,
    required this.checkOut,
    required this.nights,
    required this.adults,
    required this.children,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    final checkInDate = DateTime.parse(checkIn);
    final checkOutDate = DateTime.parse(checkOut);
    final formatter = DateFormat('MMM d, yyyy');

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderTokens.circularLarge,
      ),
      child: Padding(
        padding: const EdgeInsets.all(SpacingTokens.l),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow(
              'Check-in',
              formatter.format(checkInDate),
              Icons.login,
            ),
            const SizedBox(height: SpacingTokens.s),
            _buildInfoRow(
              'Check-out',
              formatter.format(checkOutDate),
              Icons.logout,
            ),
            const SizedBox(height: SpacingTokens.s),
            _buildInfoRow(
              'Nights',
              '$nights night${nights > 1 ? 's' : ''}',
              Icons.nights_stay,
            ),
            const SizedBox(height: SpacingTokens.s),
            _buildInfoRow(
              'Guests',
              _formatGuestCount(),
              Icons.people,
            ),
          ],
        ),
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

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: colors.textSecondary),
        const SizedBox(width: SpacingTokens.s),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: TypographyTokens.fontSizeXS,
                  color: colors.textSecondary,
                ),
              ),
              Text(
                value,
                style: GoogleFonts.inter(
                  fontSize: TypographyTokens.fontSizeM,
                  fontWeight: TypographyTokens.medium,
                  color: colors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
