import 'package:flutter/material.dart';
import '../../../../../../core/constants/enums.dart';
import '../../../../../../core/constants/booking_status_extensions.dart';
import '../../../../../../shared/models/booking_model.dart';
import '../../../../../../shared/widgets/platform_icon.dart';
import '../../../../../../l10n/app_localizations.dart';

/// Header section for booking card showing status badge and booking ID
/// Supports both regular bookings and imported reservations
class BookingCardHeader extends StatelessWidget {
  final BookingModel? booking;
  final bool isMobile;

  /// For imported reservations - platform source (e.g., 'booking_com', 'airbnb')
  final String? importedSource;

  /// Whether this booking has a conflict (overbooking) - adds right padding for warning icon
  final bool hasConflict;

  const BookingCardHeader({
    super.key,
    this.booking,
    required this.isMobile,
    this.importedSource,
    this.hasConflict = false,
  }) : assert(
         booking != null || importedSource != null,
         'Either booking or importedSource must be provided',
       );

  bool get isImported => importedSource != null;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context);

    // Extra right padding when conflict icon is present (icon is ~32px + 8px from edge)
    final rightPadding = hasConflict
        ? (isMobile ? 12 : 16) + 36.0
        : (isMobile ? 12.0 : 16.0);

    return Container(
      padding: EdgeInsets.fromLTRB(
        isMobile ? 12 : 16,
        isMobile ? 10 : 12,
        rightPadding,
        isMobile ? 10 : 12,
      ),
      decoration: BoxDecoration(
        // Modern subtle gradient-like background
        color: isDark
            ? Colors.white.withValues(alpha: 0.04)
            : Colors.grey.shade100.withValues(alpha: 0.7),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: Row(
        children: [
          if (importedSource case final source?) ...[
            // Platform icon for imported
            PlatformIcon(source: source, size: 24),
            const SizedBox(width: 10),
            // Platform name
            Expanded(
              child: Text(
                _getPlatformName(source),
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            // Imported badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.grey.shade500,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.cloud_download_outlined,
                    size: 12,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    l10n.tooltipImportedBooking,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            // Status badge - shrinks text slightly if needed, never truncates
            Flexible(
              flex: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: booking!.status.color,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: booking!.status.color.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _getStatusIcon(booking!.status),
                      color: Colors.white,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      booking!.status.displayNameLocalized(context),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Booking Reference - takes remaining space, truncates if truly needed
            Expanded(
              child: Align(
                alignment: Alignment.centerRight,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : Colors.black.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.tag,
                        size: 14,
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.5,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: SelectableText(
                          booking!.bookingReference ??
                              booking!.id.substring(0, 8),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.65,
                            ),
                            fontWeight: FontWeight.w500,
                            fontFamily: 'monospace',
                            fontSize: 11,
                          ),
                          maxLines: 1,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Get icon for booking status
  static IconData _getStatusIcon(BookingStatus status) => switch (status) {
    BookingStatus.pending => Icons.schedule,
    BookingStatus.confirmed => Icons.check_circle,
    BookingStatus.cancelled => Icons.cancel,
    BookingStatus.completed => Icons.task_alt,
  };

  String _getPlatformName(String source) {
    switch (source.toLowerCase()) {
      case 'booking_com':
      case 'booking.com':
        return 'Booking.com';
      case 'airbnb':
        return 'Airbnb';
      case 'vrbo':
        return 'VRBO';
      case 'expedia':
        return 'Expedia';
      default:
        return source.isNotEmpty
            ? source[0].toUpperCase() + source.substring(1)
            : 'iCal';
    }
  }
}
