import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/utils/error_display_utils.dart';
import '../../../../../core/services/logging_service.dart';
import '../../../../../core/theme/gradient_extensions.dart';
import '../../../../../core/constants/enums.dart';
import '../../../../../core/constants/booking_status_extensions.dart';
import '../../../../../shared/models/booking_model.dart';
import '../../../../../shared/models/unit_model.dart';
import '../../../../../shared/providers/repository_providers.dart';
import '../../providers/owner_calendar_provider.dart';

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

              // Gradient header with booking info
              Container(
                margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: context.gradients.brandPrimary,
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
                            color: Colors.white.withAlpha((0.2 * 255).toInt()),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.person,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                booking.guestName ??
                                    l10n.bookingActionUnknownGuest,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${_formatDate(booking.checkIn)} - ${_formatDate(booking.checkOut)}',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.white.withAlpha(
                                    (0.9 * 255).toInt(),
                                  ),
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
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: booking.status.color,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                booking.status.displayNameLocalized(context),
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: booking.status.color,
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
                          Icons.nights_stay,
                          l10n.tooltipNightsCount(nights),
                        ),
                        _buildInfoChip(
                          Icons.people_outline,
                          l10n.tooltipGuestsCount(booking.guestCount),
                        ),
                        _buildInfoChip(
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

  Widget _buildInfoChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha((0.2 * 255).toInt()),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.white,
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
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade300, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning_rounded, color: Colors.red.shade700, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'OVERBOOKING!',
                  style: TextStyle(
                    color: Colors.red.shade800,
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
                color: Colors.red.shade700,
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
                          color: Colors.red.shade600,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            '${conflict.guestName ?? l10n.bookingActionUnknownGuest} (${_formatDate(conflict.checkIn)} - ${_formatDate(conflict.checkOut)})',
                            style: TextStyle(
                              color: Colors.red.shade700,
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
                              color: Colors.red.shade100,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              conflict.sourceDisplayName,
                              style: TextStyle(
                                fontSize: 10,
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
                const SizedBox(height: 2),
                Text(
                  l10n.tooltipManageOn(booking.sourceDisplayName),
                  style: TextStyle(fontSize: 12, color: Colors.orange.shade700),
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

              // Gradient header
              Container(
                margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: context.gradients.brandPrimary,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha((0.2 * 255).toInt()),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.swap_horiz,
                        color: Colors.white,
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
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.booking.guestName ??
                                l10n.bookingActionUnknownGuest,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white.withAlpha(
                                (0.9 * 255).toInt(),
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
                                      // Close dialog first, then move booking
                                      // Use widget.parentContext for snackbars (dialog context won't be valid)
                                      Navigator.pop(context);
                                      await _moveBookingToUnit(
                                        widget.parentContext,
                                        unit,
                                        l10n,
                                      );
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

  Future<void> _moveBookingToUnit(
    BuildContext context,
    UnitModel targetUnit,
    AppLocalizations l10n,
  ) async {
    if (_isProcessing) return; // Prevent double-tap

    setState(() => _isProcessing = true);

    try {
      // Show loading
      if (!context.mounted) return;
      ErrorDisplayUtils.showLoadingSnackBar(context, l10n.bookingActionMoving);

      // Check for conflicts in target unit
      final bookingRepo = ref.read(bookingRepositoryProvider);
      final hasConflict = await bookingRepo.areDatesAvailable(
        unitId: targetUnit.id,
        checkIn: widget.booking.checkIn,
        checkOut: widget.booking.checkOut,
        excludeBookingId: widget.booking.id,
      );

      if (!hasConflict) {
        // Conflict detected - show error
        if (!context.mounted) return;
        ErrorDisplayUtils.showErrorSnackBar(
          context,
          'Cannot move booking: ${targetUnit.name} already has a booking during these dates',
          userMessage: 'Cannot move: unit is already booked for these dates',
        );
        return;
      }

      // Update booking with new unit, property AND owner
      // CRITICAL: Must update unitId, propertyId, AND ownerId because:
      // 1. Firestore path is: properties/{propertyId}/units/{unitId}/bookings/{id}
      // 2. When moving between units, the booking is DELETE from old path + CREATE at new path
      // 3. Security rule requires: request.resource.data.owner_id == request.auth.uid
      // 4. Without correct propertyId/ownerId, the batch operation fails with permission-denied
      // 5. Fallback to current user ID if unit has no ownerId (legacy units)
      final currentUserId = FirebaseAuth.instance.currentUser?.uid;
      final updatedBooking = widget.booking.copyWith(
        unitId: targetUnit.id,
        propertyId: targetUnit.propertyId,
        ownerId: targetUnit.ownerId ?? currentUserId ?? widget.booking.ownerId,
      );
      // Pass original booking to avoid collectionGroup permission error
      await bookingRepo.updateBooking(
        updatedBooking,
        originalBooking: widget.booking,
      );

      // Refresh calendar
      ref.invalidate(calendarBookingsProvider);

      // Show success
      if (!context.mounted) return;
      ErrorDisplayUtils.showSuccessSnackBar(
        context,
        l10n.bookingActionMovedTo(targetUnit.name),
      );
    } catch (e) {
      if (!context.mounted) return;
      ErrorDisplayUtils.showErrorSnackBar(
        context,
        e,
        userMessage: l10n.bookingActionError(
          LoggingService.safeErrorToString(e),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }
}
