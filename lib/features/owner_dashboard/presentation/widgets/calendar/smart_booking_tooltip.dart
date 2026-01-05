import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../../l10n/app_localizations.dart';
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
  ///
  /// [hasConflict] - Whether this booking overlaps with another booking
  /// [conflictingBookings] - List of bookings that conflict with this one
  static void show({
    required BuildContext context,
    required BookingModel booking,
    Offset? position, // For desktop hover positioning
    bool hasConflict = false,
    List<BookingModel>? conflictingBookings,
  }) {
    if (PlatformUtils.supportsHover && position != null) {
      // Desktop/Web: Show hover tooltip overlay
      _showHoverTooltip(
        context,
        booking,
        position,
        hasConflict,
        conflictingBookings,
      );
    } else {
      // Mobile: Show bottom sheet
      _showBottomSheet(context, booking, hasConflict, conflictingBookings);
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
    bool hasConflict,
    List<BookingModel>? conflictingBookings,
  ) {
    // Remove previous tooltip before showing new one
    hide();

    final overlay = Overlay.of(context);
    late OverlayEntry entry;

    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Get screen dimensions for smart positioning
    final screenSize = MediaQuery.of(context).size;
    // Responsive tooltip width: smaller on small screens
    final tooltipWidth = screenSize.width < 600 ? 260.0 : 300.0;
    final padding = 12.0;

    entry = OverlayEntry(
      builder: (context) => _SmartPositionedTooltip(
        position: position,
        screenSize: screenSize,
        tooltipWidth: tooltipWidth,
        padding: padding,
        child: Material(
          elevation: 12,
          shadowColor: Colors.black.withAlpha((0.3 * 255).toInt()),
          borderRadius: BorderRadius.circular(12),
          color: isDark ? const Color(0xFF252330) : Colors.white,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark
                    ? Colors.white.withAlpha((0.15 * 255).toInt())
                    : Colors.black.withAlpha((0.1 * 255).toInt()),
              ),
            ),
            child: _TooltipContent(
              booking: booking,
              isCompact: true,
              hasConflict: hasConflict,
              conflictingBookings: conflictingBookings,
            ),
          ),
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
  static void _showBottomSheet(
    BuildContext context,
    BookingModel booking,
    bool hasConflict,
    List<BookingModel>? conflictingBookings,
  ) {
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
            _TooltipContent(
              booking: booking,
              isCompact: false,
              hasConflict: hasConflict,
              conflictingBookings: conflictingBookings,
            ),
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
  final bool hasConflict;
  final List<BookingModel>? conflictingBookings;

  const _TooltipContent({
    required this.booking,
    required this.isCompact,
    this.hasConflict = false,
    this.conflictingBookings,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toString();
    final dateFormat = DateFormat('d MMM yyyy', locale);
    final nights = booking.checkOut.difference(booking.checkIn).inDays;
    final screenWidth = MediaQuery.of(context).size.width;

    return Container(
      width: isCompact ? (screenWidth < 600 ? 240.0 : 280.0) : double.infinity,
      padding: EdgeInsets.all(isCompact ? 10 : 20),
      constraints: isCompact
          ? BoxConstraints(maxWidth: screenWidth < 600 ? 260 : 300)
          : const BoxConstraints(maxWidth: 500),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // CONFLICT WARNING BANNER - shown at top if there's an overbooking
          if (hasConflict) ...[
            _ConflictWarningBanner(
              conflictingBookings: conflictingBookings,
              isCompact: isCompact,
              l10n: l10n,
            ),
            const SizedBox(height: 10),
          ],

          // Header: Guest name + Status badge
          Row(
            children: [
              Expanded(
                child: Text(
                  booking.guestName ?? l10n.tooltipGuest,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: isCompact ? 14 : 18,
                  ),
                ),
              ),
              _StatusBadge(status: booking.status, l10n: l10n),
            ],
          ),

          // External booking badge (Booking.com, Airbnb, etc.)
          if (booking.isExternalBooking) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.orange.withAlpha((0.15 * 255).toInt()),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.orange.withAlpha((0.4 * 255).toInt()),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.link, size: 12, color: Colors.orange),
                  const SizedBox(width: 4),
                  Text(
                    booking.sourceDisplayName,
                    style: TextStyle(
                      fontSize: isCompact ? 10 : 11,
                      color: Colors.orange[800],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 12),

          // Dates
          _InfoRow(
            icon: Icons.calendar_today,
            label: l10n.tooltipCheckIn,
            value: dateFormat.format(booking.checkIn),
            isCompact: isCompact,
          ),
          _InfoRow(
            icon: Icons.event_available,
            label: l10n.tooltipCheckOut,
            value: dateFormat.format(booking.checkOut),
            isCompact: isCompact,
          ),

          Divider(
            height: 16,
            color: theme.dividerColor.withAlpha((0.3 * 255).toInt()),
          ),

          // Stats
          Row(
            children: [
              Expanded(
                child: _InfoRow(
                  icon: Icons.nightlight_round,
                  label: l10n.tooltipNights,
                  value: '$nights',
                  isCompact: isCompact,
                ),
              ),
              Expanded(
                child: _InfoRow(
                  icon: Icons.person,
                  label: l10n.tooltipGuests,
                  value: '${booking.guestCount}',
                  isCompact: isCompact,
                ),
              ),
            ],
          ),

          // Price (if available)
          if (booking.totalPrice > 0) ...[
            Divider(
              height: 16,
              color: theme.dividerColor.withAlpha((0.3 * 255).toInt()),
            ),
            _InfoRow(
              icon: Icons.payments,
              label: l10n.tooltipPrice,
              value: '€${booking.totalPrice.toStringAsFixed(2)}',
              isCompact: isCompact,
              isHighlight: true,
            ),
          ],

          // Source - only for non-external bookings (external bookings show badge at top)
          if (!booking.isExternalBooking &&
              booking.source != null &&
              booking.source != 'manual') ...[
            Divider(
              height: 16,
              color: theme.dividerColor.withAlpha((0.3 * 255).toInt()),
            ),
            _InfoRow(
              icon: Icons.source,
              label: l10n.tooltipSource,
              value: booking.sourceDisplayName,
              isCompact: isCompact,
            ),
          ],

          // Notes (if available and not compact)
          if (!isCompact &&
              booking.notes != null &&
              booking.notes!.isNotEmpty) ...[
            Divider(
              height: 16,
              color: theme.dividerColor.withAlpha((0.3 * 255).toInt()),
            ),
            Text(
              l10n.tooltipNote,
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
}

/// Conflict warning banner showing overbooking alert
class _ConflictWarningBanner extends StatelessWidget {
  final List<BookingModel>? conflictingBookings;
  final bool isCompact;
  final AppLocalizations l10n;

  const _ConflictWarningBanner({
    this.conflictingBookings,
    required this.isCompact,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toString();
    final dateFormat = DateFormat('d.MM', locale);

    return Container(
      padding: EdgeInsets.all(isCompact ? 8 : 12),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.shade300, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.warning_rounded,
                color: Colors.red.shade700,
                size: isCompact ? 16 : 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'OVERBOOKING!',
                  style: TextStyle(
                    color: Colors.red.shade800,
                    fontWeight: FontWeight.bold,
                    fontSize: isCompact ? 12 : 14,
                  ),
                ),
              ),
            ],
          ),
          if (conflictingBookings != null &&
              conflictingBookings!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              l10n.tooltipConflictWith,
              style: TextStyle(
                color: Colors.red.shade700,
                fontSize: isCompact ? 10 : 11,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            ...conflictingBookings!
                .take(3)
                .map(
                  (conflict) => Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: Row(
                      children: [
                        Icon(
                          Icons.person,
                          size: isCompact ? 10 : 12,
                          color: Colors.red.shade600,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            '${conflict.guestName ?? l10n.tooltipGuest} (${dateFormat.format(conflict.checkIn)} - ${dateFormat.format(conflict.checkOut)})',
                            style: TextStyle(
                              color: Colors.red.shade700,
                              fontSize: isCompact ? 9 : 10,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (conflict.sourceDisplayName.isNotEmpty)
                          Container(
                            margin: const EdgeInsets.only(left: 4),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.red.shade100,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              conflict.sourceDisplayName,
                              style: TextStyle(
                                fontSize: isCompact ? 8 : 9,
                                color: Colors.red.shade800,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
            if (conflictingBookings!.length > 3)
              Text(
                l10n.tooltipMoreConflicts(conflictingBookings!.length - 3),
                style: TextStyle(
                  color: Colors.red.shade600,
                  fontSize: isCompact ? 9 : 10,
                  fontStyle: FontStyle.italic,
                ),
              ),
          ],
        ],
      ),
    );
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
  final AppLocalizations l10n;

  const _StatusBadge({required this.status, required this.l10n});

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
        return l10n.statusPending;
      case BookingStatus.confirmed:
        return l10n.statusConfirmed;
      case BookingStatus.completed:
        return l10n.statusCompleted;
      case BookingStatus.cancelled:
        return l10n.statusCancelled;
    }
  }
}

/// Smart positioned tooltip that measures its own size and positions itself
/// to avoid going off-screen
class _SmartPositionedTooltip extends StatefulWidget {
  final Offset position;
  final Size screenSize;
  final double tooltipWidth;
  final double padding;
  final Widget child;

  const _SmartPositionedTooltip({
    required this.position,
    required this.screenSize,
    required this.tooltipWidth,
    required this.padding,
    required this.child,
  });

  @override
  State<_SmartPositionedTooltip> createState() =>
      _SmartPositionedTooltipState();
}

class _SmartPositionedTooltipState extends State<_SmartPositionedTooltip> {
  final GlobalKey _key = GlobalKey();

  @override
  Widget build(BuildContext context) {
    // Estimate tooltip height based on screen size (avoid setState treperenje)
    final tooltipHeight = widget.screenSize.width < 600 ? 180.0 : 200.0;

    // Calculate smart positioning
    // Horizontal: Show left if too close to right edge, otherwise right
    final showLeft =
        (widget.position.dx + widget.tooltipWidth + widget.padding) >
        widget.screenSize.width;
    final left = showLeft
        ? widget.position.dx - widget.tooltipWidth - widget.padding
        : widget.position.dx + widget.padding;

    // Vertical: Show above if too close to bottom edge, otherwise below
    final showAbove =
        (widget.position.dy + tooltipHeight + widget.padding) >
        widget.screenSize.height;
    final top = showAbove
        ? widget.position.dy - tooltipHeight - widget.padding
        : widget.position.dy + widget.padding;

    return Positioned(
      left: left.clamp(
        widget.padding,
        widget.screenSize.width - widget.tooltipWidth - widget.padding,
      ),
      top: top.clamp(
        widget.padding,
        widget.screenSize.height - tooltipHeight - widget.padding,
      ),
      child: Container(key: _key, child: widget.child),
    );
  }
}
