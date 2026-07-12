import 'package:flutter/material.dart';
import '../../../../../core/design/tokens.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/utils/error_display_utils.dart';
import '../../../../../core/services/logging_service.dart';
import '../../../../../core/constants/enums.dart';
import '../../../../../core/constants/booking_status_extensions.dart';
import '../../../../../shared/models/booking_model.dart';
import '../../../../../shared/models/unit_model.dart';
import '../../../data/services/owner_booking_callable_service.dart';
import '../../providers/owner_calendar_provider.dart';
import '../../providers/calendar_filters_provider.dart';

/// Bottom sheet with quick actions for a booking
/// Shown on short tap of a booking block
class BookingActionBottomSheet extends ConsumerWidget {
  final BookingModel booking;
  final bool hasConflict;
  final List<BookingModel>? conflictingBookings;

  const BookingActionBottomSheet({
    super.key,
    required this.booking,
    this.hasConflict = false,
    this.conflictingBookings,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context);
    final nights = booking.checkOut.difference(booking.checkIn).inDays;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A24) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 4),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.black12,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // OVERBOOKING WARNING - shown at top if there's a conflict
              if (hasConflict) ...[
                _buildConflictWarningBanner(context, l10n),
                const SizedBox(height: 8),
              ],

              // Theme-aware shell header with booking info
              Container(
                margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  border: Border.all(
                    color: Theme.of(
                      context,
                    ).dividerColor.withValues(alpha: 0.4),
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    // Guest name and status
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Theme.of(
                              context,
                            ).colorScheme.primary.withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.person,
                            color: Theme.of(context).colorScheme.primary,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // For external bookings: show platform name prominently above guest name
                              if (booking.isExternalBooking) ...[
                                Text(
                                  booking.sourceDisplayName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withValues(alpha: 0.85),
                                  ),
                                ),
                                const SizedBox(height: 2),
                              ],
                              Text(
                                booking.guestName ??
                                    l10n.bookingActionUnknownGuest,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${_formatDate(booking.checkIn)} - ${_formatDate(booking.checkOut)}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Theme.of(context).colorScheme.onSurface
                                      .withValues(alpha: 0.7),
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Status badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: booking.status
                                .colorOf(context)
                                .withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: booking.status.colorOf(context),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                booking.status.displayNameLocalized(context),
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: booking.status.colorOf(context),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Info row: nights, guests, price
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildInfoChip(
                          context,
                          Icons.nights_stay,
                          l10n.tooltipNightsCount(nights),
                        ),
                        _buildInfoChip(
                          context,
                          Icons.people_outline,
                          l10n.tooltipGuestsCount(booking.guestCount),
                        ),
                        _buildInfoChip(
                          context,
                          Icons.euro,
                          '${booking.totalPrice.toStringAsFixed(0)} €',
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // EXTERNAL BOOKING INFO - iCal imports are read-only
              if (booking.isExternalBooking) ...[
                _buildExternalBookingBanner(context, isDark, l10n),
                const SizedBox(height: 16),
              ],

              // Actions - HIDDEN for external bookings (read-only)
              if (!booking.isExternalBooking)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      // Approve action - only for pending bookings
                      if (booking.status == BookingStatus.pending) ...[
                        _buildActionTile(
                          context,
                          icon: Icons.check_circle_outline,
                          iconColor: AppColors.success,
                          title: l10n.ownerBookingCardApprove,
                          subtitle: l10n.bookingApproveMessage,
                          onTap: () => Navigator.pop(context, 'approve'),
                          isDark: isDark,
                        ),
                        const SizedBox(height: 8),
                        // Reject action - only for pending bookings
                        _buildActionTile(
                          context,
                          icon: Icons.cancel_outlined,
                          iconColor: AppColors.error,
                          title: l10n.ownerBookingCardReject,
                          subtitle: l10n.bookingRejectMessage,
                          onTap: () => Navigator.pop(context, 'reject'),
                          isDark: isDark,
                          isDestructive: true,
                        ),
                        const SizedBox(height: 8),
                      ],
                      // Edit action
                      _buildActionTile(
                        context,
                        icon: Icons.edit_outlined,
                        iconColor: AppColors.primary,
                        title: l10n.bookingActionEditTitle,
                        subtitle: l10n.bookingActionEditSubtitle,
                        onTap: () => Navigator.pop(context, 'edit'),
                        isDark: isDark,
                      ),
                      const SizedBox(height: 8),
                      // Cancel action - only for confirmed bookings
                      if (booking.status == BookingStatus.confirmed) ...[
                        _buildActionTile(
                          context,
                          icon: Icons.event_busy,
                          iconColor: Colors.orange,
                          title: l10n.ownerBookingCardCancel,
                          subtitle: l10n.bookingCancelMessage,
                          onTap: () => Navigator.pop(context, 'cancel'),
                          isDark: isDark,
                        ),
                        const SizedBox(height: 8),
                      ],
                      // Delete action
                      _buildActionTile(
                        context,
                        icon: Icons.delete_outline,
                        iconColor: AppColors.error,
                        title: l10n.bookingActionDeleteTitle,
                        subtitle: l10n.bookingActionDeleteSubtitle,
                        onTap: () => Navigator.pop(context, 'delete'),
                        isDark: isDark,
                        isDestructive: true,
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(BuildContext context, IconData icon, String text) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: theme.colorScheme.primary),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionTile(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required bool isDark,
    bool isDestructive = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF252530) : const Color(0xFFF8F8FA),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDestructive
                  ? AppColors.error.withAlpha((0.3 * 255).toInt())
                  : (isDark
                        ? AppColors.sectionDividerDark
                        : AppColors.sectionDividerLight),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: iconColor.withAlpha((0.15 * 255).toInt()),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: isDestructive ? AppColors.error : null,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}.${date.month}.${date.year}';
  }

  /// Build conflict warning banner showing overbooking alert
  Widget _buildConflictWarningBanner(
    BuildContext context,
    AppLocalizations l10n,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: BBColor.errorSurface(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: BBColor.errorBorder(context), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.warning_rounded,
                color: BBColor.of(context).error,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'OVERBOOKING!',
                  style: TextStyle(
                    color: BBColor.of(context).error,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          if (conflictingBookings != null &&
              conflictingBookings!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              l10n.tooltipConflictWith,
              style: TextStyle(
                color: BBColor.of(context).error,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            ...conflictingBookings!
                .take(3)
                .map(
                  (conflict) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        Icon(
                          Icons.person,
                          size: 14,
                          color: BBColor.of(context).error,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            '${conflict.guestName ?? l10n.bookingActionUnknownGuest} (${_formatDate(conflict.checkIn)} - ${_formatDate(conflict.checkOut)})',
                            style: TextStyle(
                              color: BBColor.of(context).error,
                              fontSize: 12,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (conflict.isExternalBooking)
                          Container(
                            margin: const EdgeInsets.only(left: 4),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: BBColor.errorSurface(
                                context,
                                strength: 1.6,
                              ),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              conflict.sourceDisplayName,
                              style: TextStyle(
                                fontSize: 10,
                                color: BBColor.of(context).error,
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
                  color: BBColor.of(context).error,
                  fontSize: 11,
                  fontStyle: FontStyle.italic,
                ),
              ),
          ],
        ],
      ),
    );
  }

  /// Build external booking info banner (iCal imports are read-only)
  Widget _buildExternalBookingBanner(
    BuildContext context,
    bool isDark,
    AppLocalizations l10n,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.withAlpha((0.1 * 255).toInt()),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.orange.withAlpha((0.4 * 255).toInt()),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.orange.withAlpha((0.2 * 255).toInt()),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.link, color: Colors.orange.shade700, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.tooltipImportedBooking,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange.shade800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.tooltipManageOn(booking.sourceDisplayName),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.orange.shade800,
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

/// Bottom sheet for moving booking to another unit
/// Shown on long press of a booking block
class BookingMoveToUnitMenu extends ConsumerStatefulWidget {
  final BookingModel booking;
  final BuildContext parentContext;

  const BookingMoveToUnitMenu({
    super.key,
    required this.booking,
    required this.parentContext,
  });

  @override
  ConsumerState<BookingMoveToUnitMenu> createState() =>
      _BookingMoveToUnitMenuState();
}

class _BookingMoveToUnitMenuState extends ConsumerState<BookingMoveToUnitMenu> {
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context);
    final unitsAsync = ref.watch(allOwnerUnitsProvider);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A24) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.7,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 4),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.black12,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Theme-aware shell header
              Container(
                margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  border: Border.all(
                    color: theme.dividerColor.withValues(alpha: 0.4),
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(
                          alpha: 0.10,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.swap_horiz,
                        color: theme.colorScheme.primary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.bookingActionMoveTitle,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.booking.guestName ??
                                l10n.bookingActionUnknownGuest,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 14,
                              color: theme.colorScheme.onSurface.withValues(
                                alpha: 0.7,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Units list - use Flexible to allow list to shrink
              Flexible(
                child: unitsAsync.when(
                  data: (units) {
                    // Filter out current unit
                    final otherUnits = units
                        .where((u) => u.id != widget.booking.unitId)
                        .toList();

                    if (otherUnits.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.info_outline,
                              size: 48,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              l10n.bookingActionNoOtherUnits,
                              style: TextStyle(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      shrinkWrap: true,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: otherUnits.length,
                      itemBuilder: (context, index) {
                        final unit = otherUnits[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: _isProcessing
                                  ? null
                                  : () async {
                                      // Move booking FIRST (while dialog is still open)
                                      // Then close dialog after operation completes
                                      // This ensures ref.invalidate() works before disposal
                                      final targetDate =
                                          await _moveBookingToUnit(
                                            widget.parentContext,
                                            unit,
                                            l10n,
                                          );
                                      // Only close dialog if widget is still mounted
                                      // Return the booking's check-in date so calendar can scroll to it
                                      if (mounted && context.mounted) {
                                        Navigator.pop(context, targetDate);
                                      }
                                    },
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? const Color(0xFF252530)
                                      : const Color(0xFFF8F8FA),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isDark
                                        ? AppColors.sectionDividerDark
                                        : AppColors.sectionDividerLight,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary.withAlpha(
                                          (0.15 * 255).toInt(),
                                        ),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Icon(
                                        _getUnitIcon(unit),
                                        color: AppColors.primary,
                                        size: 22,
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            unit.name,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            l10n.bookingActionGuestsRooms(
                                              unit.maxGuests,
                                              unit.bedrooms,
                                            ),
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: theme
                                                  .colorScheme
                                                  .onSurfaceVariant,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Icon(
                                      Icons.chevron_right,
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                  loading: () => const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (error, stack) => Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      l10n.bookingActionError(
                        LoggingService.safeErrorToString(error),
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getUnitIcon(UnitModel unit) {
    if (unit.bedrooms >= 3) return Icons.house;
    if (unit.bedrooms == 2) return Icons.apartment;
    return Icons.hotel;
  }

  /// Move booking to another unit
  /// Returns the booking's check-in date on success (for calendar scroll-to-date)
  /// Returns null on failure
  Future<DateTime?> _moveBookingToUnit(
    BuildContext context,
    UnitModel targetUnit,
    AppLocalizations l10n,
  ) async {
    if (_isProcessing) return null; // Prevent double-tap

    setState(() => _isProcessing = true);

    try {
      // Show loading
      if (!context.mounted) return null;
      ErrorDisplayUtils.showLoadingSnackBar(context, l10n.bookingActionMoving);

      // audit/26 PR-A: route through updateBookingAtomic so the overlap check
      // runs server-side inside a txn and target property ownership is
      // re-validated (auth.uid == target.owner_id). Dates are inherited from
      // the existing booking by the CF (no checkIn/checkOut sent here), so
      // the server normalizes existing Timestamps via the pass-through path.
      // Server writes owner_id from the target property doc — never trusts
      // client-sent values.
      final callableService = ref.read(ownerBookingCallableServiceProvider);
      await callableService.updateBooking(
        bookingId: widget.booking.id,
        propertyId: widget.booking.propertyId,
        unitId: widget.booking.unitId,
        targetPropertyId: targetUnit.propertyId,
        targetUnitId: targetUnit.id,
      );

      // Refresh calendar providers to update UI
      // MUST invalidate both: base provider AND filtered provider that UI watches
      ref.invalidate(calendarBookingsProvider);
      ref.invalidate(timelineCalendarBookingsProvider);

      // Show success
      if (!context.mounted) return widget.booking.checkIn;
      ErrorDisplayUtils.showSuccessSnackBar(
        context,
        l10n.bookingActionMovedTo(targetUnit.name),
      );
      // Return check-in date so calendar can scroll to the moved booking
      return widget.booking.checkIn;
    } catch (e) {
      if (!context.mounted) return null;
      ErrorDisplayUtils.showErrorSnackBar(
        context,
        e,
        userMessage: l10n.bookingActionError(
          LoggingService.safeErrorToString(e),
        ),
      );
      return null;
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }
}
