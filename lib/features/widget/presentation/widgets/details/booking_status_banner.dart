import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../core/design_tokens/design_tokens.dart';

/// Banner displaying booking status with appropriate color and icon.
///
/// Shows status (Confirmed, Pending, Cancelled) with visual styling.
/// Used at the top of booking details screen.
///
/// Usage:
/// ```dart
/// BookingStatusBanner(
///   status: 'confirmed',
///   colors: ColorTokens.light,
/// )
/// ```
class BookingStatusBanner extends StatelessWidget {
  /// Booking status string (confirmed, pending, cancelled, approved)
  final String status;

  /// Color tokens for theming
  final WidgetColorScheme colors;

  const BookingStatusBanner({
    super.key,
    required this.status,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    final statusInfo = _getStatusInfo();

    return Container(
      padding: const EdgeInsets.all(SpacingTokens.m),
      decoration: BoxDecoration(
        color: statusInfo.color.withValues(alpha: 0.1),
        borderRadius: BorderTokens.circularMedium,
        border: Border.all(color: statusInfo.color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(statusInfo.icon, color: statusInfo.color, size: 24),
          const SizedBox(width: SpacingTokens.s),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Booking Status',
                  style: GoogleFonts.inter(
                    fontSize: TypographyTokens.fontSizeXS,
                    color: colors.textSecondary,
                  ),
                ),
                Text(
                  statusInfo.text,
                  style: GoogleFonts.inter(
                    fontSize: TypographyTokens.fontSizeL,
                    fontWeight: TypographyTokens.bold,
                    color: statusInfo.color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  _StatusInfo _getStatusInfo() {
    switch (status.toLowerCase()) {
      case 'confirmed':
      case 'approved':
        return _StatusInfo(
          color: colors.success,
          text: 'Confirmed',
          icon: Icons.check_circle,
        );
      case 'pending':
        return _StatusInfo(
          color: colors.warning,
          text: 'Pending',
          icon: Icons.schedule,
        );
      case 'cancelled':
        return _StatusInfo(
          color: colors.error,
          text: 'Cancelled',
          icon: Icons.cancel,
        );
      default:
        return _StatusInfo(
          color: colors.textSecondary,
          text: status,
          icon: Icons.info,
        );
    }
  }
}

class _StatusInfo {
  final Color color;
  final String text;
  final IconData icon;

  _StatusInfo({
    required this.color,
    required this.text,
    required this.icon,
  });
}
