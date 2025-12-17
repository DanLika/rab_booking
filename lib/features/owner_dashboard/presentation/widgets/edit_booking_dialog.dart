import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/models/booking_model.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/gradient_extensions.dart';
import '../../../../core/utils/input_decoration_helper.dart';
import '../../../../core/utils/responsive_dialog_utils.dart';
import '../../../../core/utils/responsive_spacing_helper.dart';
import '../../../../shared/providers/repository_providers.dart';
import '../../../../core/utils/error_display_utils.dart';
import '../../../../core/services/logging_service.dart';
import '../providers/owner_bookings_provider.dart';
import '../providers/owner_calendar_provider.dart';
import '../providers/platform_connections_provider.dart';
import '../../utils/booking_overlap_detector.dart';
import 'dialogs/update_booking_warning_dialog.dart';

/// Edit Booking Dialog - Phase 2 Feature
///
/// Allows property owners to edit booking details including:
/// - Check-in/Check-out dates
/// - Guest count
/// - Notes
/// - Status (if needed)
Future<void> showEditBookingDialog(BuildContext context, WidgetRef ref, BookingModel booking) async {
  return showDialog(
    context: context,
    builder: (context) => _EditBookingDialog(booking: booking),
  );
}

class _EditBookingDialog extends ConsumerStatefulWidget {
  final BookingModel booking;

  const _EditBookingDialog({required this.booking});

  @override
  _EditBookingDialogState createState() => _EditBookingDialogState();
}

class _EditBookingDialogState extends ConsumerState<_EditBookingDialog> {
  late DateTime _checkIn;
  late DateTime _checkOut;
  late int _guestCount;
  final _notesController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkIn = widget.booking.checkIn;
    _checkOut = widget.booking.checkOut;
    _guestCount = widget.booking.guestCount;
    _notesController.text = widget.booking.notes ?? '';
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final nights = _checkOut.difference(_checkIn).inDays;
    final screenHeight = MediaQuery.of(context).size.height;
    final dialogWidth = ResponsiveDialogUtils.getDialogWidth(context, maxWidth: 500);
    final contentPadding = ResponsiveDialogUtils.getContentPadding(context);
    final headerPadding = ResponsiveDialogUtils.getHeaderPadding(context);
    final isDark = theme.brightness == Brightness.dark;

    // FIXED BUG #14: Prevent accidental dismiss during loading operations
    return PopScope(
      canPop: !_isLoading,
      onPopInvokedWithResult: (didPop, result) {
        if (_isLoading) {
          // Show a brief message if user tries to dismiss during loading
          ErrorDisplayUtils.showErrorSnackBar(
            context,
            'Please wait for the operation to complete',
            duration: const Duration(seconds: 2),
          );
        }
      },
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        clipBehavior: Clip.antiAlias,
        insetPadding: ResponsiveDialogUtils.getDialogInsetPadding(context),
      child: Container(
        width: dialogWidth,
        constraints: BoxConstraints(
          maxHeight: screenHeight * ResponsiveSpacingHelper.getDialogMaxHeightPercent(context),
        ),
        decoration: BoxDecoration(
          gradient: context.gradients.sectionBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: context.gradients.sectionBorder.withValues(alpha: 0.5)),
          boxShadow: isDark ? AppShadows.elevation4Dark : AppShadows.elevation4,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Gradient Header
            Container(
              padding: EdgeInsets.all(headerPadding),
              decoration: BoxDecoration(
                gradient: context.gradients.brandPrimary,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(11)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.edit, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      l10n.editBookingTitle,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // Content
            Flexible(
              child: SingleChildScrollView(
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                padding: EdgeInsets.only(
                  left: contentPadding,
                  right: contentPadding,
                  top: contentPadding,
                  // Add keyboard height as bottom padding so content can scroll above keyboard
                  bottom: contentPadding + MediaQuery.of(context).viewInsets.bottom,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Booking Info
                    Text(
                      l10n.editBookingBookingId(widget.booking.id),
                      style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 12),
                    ),
                    Text(
                      l10n.editBookingGuest(widget.booking.guestName ?? ''),
                      style: TextStyle(color: theme.colorScheme.onSurface, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 16),

                    // Check-in Date
                    ListTile(
                      leading: const Icon(Icons.login),
                      title: Text(l10n.editBookingCheckIn),
                      subtitle: Text(DateFormat('MMM dd, yyyy').format(_checkIn)),
                      trailing: IconButton(
                        icon: const Icon(Icons.edit_calendar),
                        onPressed: () => _selectDate(isCheckIn: true),
                      ),
                      contentPadding: EdgeInsets.zero,
                    ),

                    // Check-out Date
                    ListTile(
                      leading: const Icon(Icons.logout),
                      title: Text(l10n.editBookingCheckOut),
                      subtitle: Text(DateFormat('MMM dd, yyyy').format(_checkOut)),
                      trailing: IconButton(
                        icon: const Icon(Icons.edit_calendar),
                        onPressed: () => _selectDate(isCheckIn: false),
                      ),
                      contentPadding: EdgeInsets.zero,
                    ),

                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.nights_stay, size: 18, color: theme.colorScheme.primary),
                          const SizedBox(width: 8),
                          Text(
                            l10n.editBookingNights(nights),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Guest Count
                    Row(
                      children: [
                        Icon(Icons.people, color: theme.colorScheme.primary),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            l10n.editBookingGuests,
                            style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
                          ),
                        ),
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: _guestCount > 1
                                ? theme.colorScheme.primary
                                : theme.colorScheme.onSurface.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            padding: EdgeInsets.zero,
                            icon: Icon(
                              Icons.remove,
                              size: 16,
                              color: _guestCount > 1
                                  ? theme.colorScheme.onPrimary
                                  : theme.colorScheme.onSurface.withValues(alpha: 0.38),
                            ),
                            onPressed: _guestCount > 1 ? () => setState(() => _guestCount--) : null,
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 32,
                          child: Text(
                            _guestCount.toString(),
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(color: theme.colorScheme.primary, shape: BoxShape.circle),
                          child: IconButton(
                            padding: EdgeInsets.zero,
                            icon: Icon(Icons.add, size: 16, color: theme.colorScheme.onPrimary),
                            onPressed: () => setState(() => _guestCount++),
                          ),
                        ),
                      ],
                    ),

                    // Notes
                    const SizedBox(height: 12),
                    TextField(
                      controller: _notesController,
                      maxLines: 3,
                      decoration: InputDecorationHelper.buildDecoration(
                        labelText: l10n.editBookingInternalNotes,
                        hintText: l10n.editBookingNotesHint,
                        context: context,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Footer
            Container(
              padding: EdgeInsets.symmetric(horizontal: contentPadding, vertical: 12),
              decoration: BoxDecoration(
                color: isDark ? AppColors.dialogFooterDark : AppColors.dialogFooterLight,
                border: Border(
                  top: BorderSide(color: isDark ? AppColors.sectionDividerDark : AppColors.sectionDividerLight),
                ),
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(11)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Flexible(
                    child: TextButton(
                      onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        minimumSize: Size.zero,
                      ),
                      child: Text(l10n.cancel, overflow: TextOverflow.ellipsis),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: context.gradients.brandPrimary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _saveChanges,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          foregroundColor: Colors.white,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : Text(l10n.editBookingSaveChanges, overflow: TextOverflow.ellipsis),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      ), // Close Dialog
    ); // Close PopScope
  }

  Future<void> _selectDate({required bool isCheckIn}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isCheckIn ? _checkIn : _checkOut,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 730)),
    );

    if (picked != null) {
      setState(() {
        if (isCheckIn) {
          _checkIn = picked;
          if (_checkOut.isBefore(_checkIn) || _checkOut.isAtSameMomentAs(_checkIn)) {
            _checkOut = _checkIn.add(const Duration(days: 1));
          }
        } else {
          if (picked.isAfter(_checkIn)) {
            _checkOut = picked;
          }
        }
      });
    }
  }

  Future<void> _saveChanges() async {
    setState(() => _isLoading = true);

    try {
      // FIXED BUG #12: Validate for overlaps before saving
      final allBookingsMap = await ref.read(calendarBookingsProvider.future);

      // Check if new dates would overlap with existing bookings
      final conflicts = BookingOverlapDetector.getConflictingBookings(
        unitId: widget.booking.unitId,
        newCheckIn: _checkIn,
        newCheckOut: _checkOut,
        bookingIdToExclude: widget.booking.id,
        allBookings: allBookingsMap,
      );

      if (conflicts.isNotEmpty) {
        setState(() => _isLoading = false);

        if (mounted) {
          // Show detailed error with conflicting booking info
          final conflict = conflicts.first;
          final conflictGuestName = conflict.guestName ?? 'Unknown';
          final conflictCheckIn = DateFormat('dd.MM.yyyy').format(conflict.checkIn);
          final conflictCheckOut = DateFormat('dd.MM.yyyy').format(conflict.checkOut);

          ErrorDisplayUtils.showErrorSnackBar(
            context,
            conflicts.length == 1
                ? 'Overlap detected with booking for $conflictGuestName ($conflictCheckIn - $conflictCheckOut)'
                : 'Overlap detected with ${conflicts.length} existing bookings',
            duration: const Duration(seconds: 5),
          );
        }
        return;
      }

      // Check if dates changed
      final datesChanged = _checkIn != widget.booking.checkIn || _checkOut != widget.booking.checkOut;

      // If dates changed, check for platform integrations and show warning
      if (datesChanged) {
        final platformConnectionsAsync = await ref.read(
          platformConnectionsForUnitProvider(widget.booking.unitId).future,
        );

        // If unit has active platform connections, show warning dialog
        if (platformConnectionsAsync.isNotEmpty && mounted) {
          final platformNames = platformConnectionsAsync
              .map((c) => c.platform.displayName)
              .toSet()
              .toList();

          final confirmed = await UpdateBookingWarningDialog.show(
            context: context,
            oldCheckIn: widget.booking.checkIn,
            oldCheckOut: widget.booking.checkOut,
            newCheckIn: _checkIn,
            newCheckOut: _checkOut,
            platformNames: platformNames,
          );

          if (!confirmed) {
            setState(() => _isLoading = false);
            return;
          }
        }
      }

      // Check if check-out date changed (for token expiration update)
      final checkOutChanged = _checkOut != widget.booking.checkOut;

      // FIXED BUG #2: Use transaction with existence check to prevent creating new document
      // FIXED: FieldPath.documentId() does NOT work with collectionGroup() queries!
      // Firestore expects full document path, not just ID when using collectionGroup.
      // Solution: Use direct document path since we have propertyId and unitId
      final firestore = ref.read(firestoreProvider);

      // Build direct document reference using known path
      // Structure: properties/{propertyId}/units/{unitId}/bookings/{bookingId}
      final docRef = firestore
          .collection('properties')
          .doc(widget.booking.propertyId)
          .collection('units')
          .doc(widget.booking.unitId)
          .collection('bookings')
          .doc(widget.booking.id);

      await firestore.runTransaction((transaction) async {
        final docSnapshot = await transaction.get(docRef);

        if (!docSnapshot.exists) {
          throw Exception('Booking no longer exists. It may have been deleted.');
        }

        transaction.update(docRef, {
          'check_in': _checkIn.toUtc().toIso8601String(),
          'check_out': _checkOut.toUtc().toIso8601String(),
          'guest_count': _guestCount,
          'notes': _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        });
      });

      // If check-out date changed, update token expiration
      if (checkOutChanged) {
        try {
          final functions = ref.read(firebaseFunctionsProvider);
          final callable = functions.httpsCallable('updateBookingTokenExpiration');
          await callable.call({
            'bookingId': widget.booking.id,
          });
        } catch (e) {
          // Log error but don't block booking update
          LoggingService.logWarning('Failed to update token expiration: $e');
        }
      }

      if (mounted) {
        // FIXED BUG #5: Invalidate provider to refresh booking list in parent screen
        ref.invalidate(windowedBookingsNotifierProvider);

        Navigator.of(context).pop();
        ErrorDisplayUtils.showSuccessSnackBar(context, AppLocalizations.of(context).editBookingSuccess);
      }
    } catch (e) {
      // FIXED: Use ErrorDisplayUtils for user-friendly error messages
      if (mounted) {
        ErrorDisplayUtils.showErrorSnackBar(context, e, userMessage: AppLocalizations.of(context).editBookingError);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
