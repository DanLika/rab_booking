import 'package:flutter/material.dart';
import '../theme/bedbooking_theme.dart';

/// "Powered by BedBooking" badge widget
/// Shows at the bottom of the widget for branding
/// Can be hidden for premium users via configuration
class PoweredByBedBookingBadge extends StatelessWidget {
  /// Whether to show the badge
  /// Set to false for premium/white-label customers
  final bool show;

  /// Alignment of the badge
  final MainAxisAlignment alignment;

  /// Additional padding around the badge
  final EdgeInsets padding;

  const PoweredByBedBookingBadge({
    super.key,
    this.show = true,
    this.alignment = MainAxisAlignment.center,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    if (!show) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: padding,
      child: Row(
        mainAxisAlignment: alignment,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Powered by ',
            style: BedBookingTextStyles.small.copyWith(
              color: BedBookingColors.textGrey,
            ),
          ),
          Text(
            'BedBooking',
            style: BedBookingTextStyles.small.copyWith(
              color: BedBookingColors.primaryGreen,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

/// Compact version of the badge for tight spaces
class PoweredByBedBookingBadgeCompact extends StatelessWidget {
  final bool show;

  const PoweredByBedBookingBadgeCompact({
    super.key,
    this.show = true,
  });

  @override
  Widget build(BuildContext context) {
    if (!show) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: BedBookingColors.backgroundGrey,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: BedBookingColors.borderGrey,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.bolt,
            size: 12,
            color: BedBookingColors.primaryGreen,
          ),
          const SizedBox(width: 4),
          Text(
            'BedBooking',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: BedBookingColors.primaryGreen,
            ),
          ),
        ],
      ),
    );
  }
}
