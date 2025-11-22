import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../../shared/models/booking_model.dart';
import '../../../../../core/utils/platform_utils.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/constants/enums.dart';

/// Smart booking tooltip that adapts to platform:
/// - Desktop/Web: Hover overlay tooltip
/// - Mobile: Bottom sheet on tap
class SmartBookingTooltip {
  // Singleton pattern - only one tooltip visible at a time
  static OverlayEntry? _activeTooltip;

  /// Show booking details in platform-appropriate way
  static void show({
    required BuildContext context,
    required BookingModel booking,
    Offset? position, // For desktop hover positioning
  }) {
    if (PlatformUtils.supportsHover && position != null) {
      // Desktop/Web: Show hover tooltip overlay
      _showHoverTooltip(context, booking, position);
    } else {
      // Mobile: Show bottom sheet
      _showBottomSheet(context, booking);
    }
  }

  /// Hide active tooltip (called on mouse exit)
  static void hide() {
    _activeTooltip?.remove();
    _activeTooltip = null;
  }

  /// Desktop/Web: Hover overlay tooltip
  static void _showHoverTooltip(
    BuildContext context,
    BookingModel booking,
    Offset position,
  ) {
    // Remove previous tooltip before showing new one
    hide();

    final overlay = Overlay.of(context);
    late OverlayEntry entry;

    entry = OverlayEntry(
      builder: (context) => Positioned(
        left: position.dx + 10,
        top: position.dy + 10,
        child: Material(
          elevation: 8,
          borderRadius: BorderRadius.circular(8),
          child: _TooltipContent(booking: booking, isCompact: true),
        ),
      ),
    );

    overlay.insert(entry);
    _activeTooltip = entry;

    // Auto-remove after 3 seconds as safety measure
    Future.delayed(const Duration(seconds: 3), () {
      if (entry.mounted && _activeTooltip == entry) {
        hide();
      }
    });
  }

  /// Mobile: Bottom sheet
  static void _showBottomSheet(BuildContext context, BookingModel booking) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            _TooltipContent(booking: booking, isCompact: false),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

/// Shared content widget for both tooltip and bottom sheet
class _TooltipContent extends StatelessWidget {
  final BookingModel booking;
  final bool isCompact;

  const _TooltipContent({required this.booking, required this.isCompact});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('d MMM yyyy', 'hr_HR');
    final nights = booking.checkOut.difference(booking.checkIn).inDays;

    return Container(
      width: isCompact ? 280 : double.infinity,
      padding: EdgeInsets.all(isCompact ? 12 : 20),
      constraints: isCompact
          ? const BoxConstraints(maxWidth: 320)
          : const BoxConstraints(maxWidth: 500),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Guest name + Status badge
          Row(
            children: [
              Expanded(
                child: Text(
                  booking.guestName ?? 'Gost',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: isCompact ? 14 : 18,
                  ),
                ),
              ),
              _StatusBadge(status: booking.status),
            ],
          ),

          const SizedBox(height: 12),

          // Dates
          _InfoRow(
            icon: Icons.calendar_today,
            label: 'Check-in',
            value: dateFormat.format(booking.checkIn),
            isCompact: isCompact,
          ),
          _InfoRow(
            icon: Icons.event_available,
            label: 'Check-out',
            value: dateFormat.format(booking.checkOut),
            isCompact: isCompact,
          ),

          const Divider(height: 16),

          // Stats
          Row(
            children: [
              Expanded(
                child: _InfoRow(
                  icon: Icons.nightlight_round,
                  label: 'Noći',
                  value: '$nights',
                  isCompact: isCompact,
                ),
              ),
              Expanded(
                child: _InfoRow(
                  icon: Icons.person,
                  label: 'Gosti',
                  value: '${booking.guestCount}',
                  isCompact: isCompact,
                ),
              ),
            ],
          ),

          // Price (if available)
          if (booking.totalPrice > 0) ...[
            const Divider(height: 16),
            _InfoRow(
              icon: Icons.payments,
              label: 'Cijena',
              value: '€${booking.totalPrice.toStringAsFixed(2)}',
              isCompact: isCompact,
              isHighlight: true,
            ),
          ],

          // Source
          if (booking.source != null && booking.source != 'manual') ...[
            const Divider(height: 16),
            _InfoRow(
              icon: Icons.source,
              label: 'Izvor',
              value: _formatSource(booking.source!),
              isCompact: isCompact,
            ),
          ],

          // Notes (if available and not compact)
          if (!isCompact &&
              booking.notes != null &&
              booking.notes!.isNotEmpty) ...[
            const Divider(height: 16),
            Text(
              'Napomena:',
              style: theme.textTheme.labelSmall?.copyWith(
                color: Colors.grey[600],
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              booking.notes!,
              style: theme.textTheme.bodySmall,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }

  String _formatSource(String source) {
    switch (source.toLowerCase()) {
      case 'airbnb':
        return 'Airbnb';
      case 'booking_com':
      case 'booking.com':
        return 'Booking.com';
      case 'ical':
        return 'iCal Sync';
      case 'widget':
        return 'Widget';
      case 'direct':
        return 'Direktno';
      case 'api':
        return 'API';
      case 'admin':
        return 'Admin';
      default:
        return source;
    }
  }
}

/// Info row with icon, label, and value
class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isCompact;
  final bool isHighlight;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.isCompact,
    this.isHighlight = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.symmetric(vertical: isCompact ? 3 : 4),
      child: Row(
        children: [
          Icon(
            icon,
            size: isCompact ? 14 : 16,
            color: isHighlight ? AppColors.success : Colors.grey[600],
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                    fontSize: isCompact ? 11 : 13,
                  ),
                ),
                Text(
                  value,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: isHighlight ? FontWeight.bold : FontWeight.w600,
                    color: isHighlight ? AppColors.success : null,
                    fontSize: isCompact ? 12 : 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Status badge widget
class _StatusBadge extends StatelessWidget {
  final BookingStatus status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: status.color.withAlpha((0.2 * 255).toInt()),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: status.color.withAlpha((0.5 * 255).toInt())),
      ),
      child: Text(
        _getStatusText(status),
        style: TextStyle(
          color: status.color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  String _getStatusText(BookingStatus status) {
    switch (status) {
      case BookingStatus.pending:
        return 'Pending';
      case BookingStatus.confirmed:
        return 'Potvrđeno';
      case BookingStatus.completed:
        return 'Završeno';
      case BookingStatus.cancelled:
        return 'Otkazano';
    }
  }
}
