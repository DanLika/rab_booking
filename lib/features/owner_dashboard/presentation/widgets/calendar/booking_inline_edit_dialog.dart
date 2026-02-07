import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:auto_size_text/auto_size_text.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_shadows.dart';
import '../../../../../core/theme/gradient_extensions.dart';
import '../../../../../core/utils/error_display_utils.dart';
import '../../../../../core/utils/input_decoration_helper.dart';
import '../../../../../core/utils/responsive_dialog_utils.dart';
import '../../../../../core/utils/responsive_spacing_helper.dart';
import '../../../../../core/utils/async_utils.dart';
import '../../../../../core/services/logging_service.dart';
import '../../../../../shared/models/booking_model.dart';
import '../../../../../shared/providers/repository_providers.dart';
import '../../../../../core/constants/enums.dart';
import '../../../../../core/constants/booking_status_extensions.dart';
import '../../providers/owner_calendar_provider.dart';
import '../../providers/platform_connections_provider.dart';
import '../../../utils/booking_overlap_detector.dart';
import '../dialogs/update_booking_warning_dialog.dart';

/// Inline booking edit dialog
/// Quick edit for booking dates, guest count, status, and notes
class BookingInlineEditDialog extends ConsumerStatefulWidget {
  final BookingModel booking;

  const BookingInlineEditDialog({super.key, required this.booking});

  @override
  ConsumerState<BookingInlineEditDialog> createState() =>
      _BookingInlineEditDialogState();
}

class _BookingInlineEditDialogState
    extends ConsumerState<BookingInlineEditDialog> {
  late DateTime _checkIn;
  late DateTime _checkOut;
  late int _guestCount;
  late BookingStatus _status;
  late TextEditingController _notesController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _checkIn = widget.booking.checkIn;
    _checkOut = widget.booking.checkOut;
    _guestCount = widget.booking.guestCount;
    _status = widget.booking.status;
    _notesController = TextEditingController(text: widget.booking.notes ?? '');
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = ResponsiveDialogUtils.isMobile(context);

    // Use ResponsiveDialogUtils for consistent sizing
    final dialogWidth = ResponsiveDialogUtils.getDialogWidth(
      context,
      maxWidth: 500,
    );
    final headerPadding = ResponsiveDialogUtils.getHeaderPadding(context);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      insetPadding: ResponsiveDialogUtils.getDialogInsetPadding(context),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Container(
          width: dialogWidth,
          constraints: BoxConstraints(
            maxHeight:
                MediaQuery.of(context).size.height *
                ResponsiveSpacingHelper.getDialogMaxHeightPercent(context),
          ),
          decoration: BoxDecoration(
            gradient: context.gradients.sectionBackground,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: context.gradients.sectionBorder.withAlpha(
                (0.5 * 255).toInt(),
              ),
            ),
            boxShadow: isDark
                ? AppShadows.elevation4Dark
                : AppShadows.elevation4,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header with gradient - matches CommonAppBar height (52px)
              Container(
                height: ResponsiveDialogUtils.kHeaderHeight,
                padding: EdgeInsets.symmetric(horizontal: headerPadding),
                decoration: BoxDecoration(
                  gradient: context.gradients.brandPrimary,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(11),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha((0.2 * 255).toInt()),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.edit,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: AutoSizeText(
                        l10n.bookingInlineEditTitle,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        maxLines: 1,
                        minFontSize: 14,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),

              // Content
              Flexible(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(screenWidth < 400 ? 12 : 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Guest name (read-only)
                      _buildInfoRow(
                        l10n.bookingInlineEditGuest,
                        widget.booking.guestName ?? 'N/A',
                        Icons.person,
                      ),
                      const SizedBox(height: 16),

                      // Dates section title
                      _SectionHeader(
                        icon: Icons.calendar_today_outlined,
                        title: l10n.bookingInlineEditDates,
                      ),
                      const SizedBox(height: 12),

                      // Date fields - responsive layout
                      if (isMobile)
                        Column(
                          children: [
                            _buildDateField(
                              label: l10n.bookingInlineEditCheckIn,
                              date: _checkIn,
                              onTap: () =>
                                  _selectDate(context, isCheckIn: true),
                            ),
                            const SizedBox(height: 12),
                            _buildDateField(
                              label: l10n.bookingInlineEditCheckOut,
                              date: _checkOut,
                              onTap: () =>
                                  _selectDate(context, isCheckIn: false),
                            ),
                          ],
                        )
                      else
                        Row(
                          children: [
                            Expanded(
                              child: _buildDateField(
                                label: l10n.bookingInlineEditCheckIn,
                                date: _checkIn,
                                onTap: () =>
                                    _selectDate(context, isCheckIn: true),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildDateField(
                                label: l10n.bookingInlineEditCheckOut,
                                date: _checkOut,
                                onTap: () =>
                                    _selectDate(context, isCheckIn: false),
                              ),
                            ),
                          ],
                        ),

                      const SizedBox(height: 12),

                      // Nights badge - styled like booking_create_dialog
                      Builder(
                        builder: (context) {
                          final nights = _checkOut
                              .difference(_checkIn)
                              .inDays
                              .clamp(0, 9999);
                          return Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary.withAlpha(
                                (0.1 * 255).toInt(),
                              ),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: theme.colorScheme.primary.withAlpha(
                                  (0.3 * 255).toInt(),
                                ),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.nights_stay,
                                  size: 18,
                                  color: theme.colorScheme.primary,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '$nights ${nights == 1 ? l10n.bookingInlineEditNightSingular : l10n.bookingInlineEditNightPlural}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 16),

                      // Guest count
                      _buildGuestCountField(),
                      const SizedBox(height: 16),

                      // Status
                      _buildStatusField(),
                      const SizedBox(height: 16),

                      // Internal notes
                      _buildNotesField(),
                    ],
                  ),
                ),
              ),

              // Footer buttons
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: screenWidth < 400 ? 8 : 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.dialogFooterDark
                      : AppColors.dialogFooterLight,
                  border: Border(
                    top: BorderSide(
                      color: isDark
                          ? AppColors.sectionDividerDark
                          : AppColors.sectionDividerLight,
                    ),
                  ),
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(11),
                  ),
                ),
                child: isMobile
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Save button (full width on mobile) with gradient
                          Container(
                            decoration: BoxDecoration(
                              gradient: context.gradients.brandPrimary,
                              borderRadius: const BorderRadius.all(
                                Radius.circular(8),
                              ),
                            ),
                            child: ElevatedButton.icon(
                              onPressed: _isSaving ? null : _saveChanges,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                foregroundColor: Colors.white,
                                // Keep same colors when disabled (loading state)
                                disabledBackgroundColor: Colors.transparent,
                                disabledForegroundColor: Colors.white,
                                shadowColor: Colors.transparent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              icon: _isSaving
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Icon(Icons.save, color: Colors.white),
                              label: AutoSizeText(
                                _isSaving
                                    ? l10n.bookingInlineEditSaving
                                    : l10n.bookingInlineEditSave,
                                style: const TextStyle(color: Colors.white),
                                maxLines: 1,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          // Cancel button (full width on mobile)
                          TextButton(
                            onPressed: _isSaving
                                ? null
                                : () => Navigator.of(context).pop(),
                            child: AutoSizeText(
                              l10n.bookingInlineEditCancel,
                              maxLines: 1,
                              minFontSize: 11,
                            ),
                          ),
                        ],
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Flexible(
                            child: TextButton(
                              onPressed: _isSaving
                                  ? null
                                  : () => Navigator.of(context).pop(),
                              child: AutoSizeText(
                                l10n.bookingInlineEditCancel,
                                maxLines: 1,
                                minFontSize: 11,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: context.gradients.brandPrimary,
                                borderRadius: const BorderRadius.all(
                                  Radius.circular(8),
                                ),
                              ),
                              child: ElevatedButton.icon(
                                onPressed: _isSaving ? null : _saveChanges,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  foregroundColor: Colors.white,
                                  shadowColor: Colors.transparent,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                icon: _isSaving
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Icon(
                                        Icons.save,
                                        color: Colors.white,
                                      ),
                                label: AutoSizeText(
                                  _isSaving
                                      ? l10n.bookingInlineEditSaving
                                      : l10n.bookingInlineEditSave,
                                  style: const TextStyle(color: Colors.white),
                                  maxLines: 1,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 20, color: theme.colorScheme.primary),
        const SizedBox(width: 8),
        Text(
          '$label:',
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: AutoSizeText(
            value,
            style: theme.textTheme.bodyMedium,
            maxLines: 1,
            minFontSize: 11,
          ),
        ),
      ],
    );
  }

  Widget _buildDateField({
    required String label,
    required DateTime date,
    required VoidCallback onTap,
  }) {
    return Builder(
      builder: (ctx) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: InputDecorator(
          decoration: InputDecorationHelper.buildDecoration(
            labelText: label,
            context: ctx,
          ).copyWith(suffixIcon: const Icon(Icons.calendar_today)),
          child: Text(
            '${date.day}/${date.month}/${date.year}',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ),
      ),
    );
  }

  Widget _buildGuestCountField() {
    final l10n = AppLocalizations.of(context);
    return Row(
      children: [
        Expanded(
          child: Builder(
            builder: (ctx) => InputDecorator(
              decoration: InputDecorationHelper.buildDecoration(
                labelText: l10n.bookingInlineEditGuestCount,
                context: ctx,
              ),
              child: Text(
                '$_guestCount',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        IconButton.filledTonal(
          onPressed: _guestCount > 1
              ? () => setState(() => _guestCount--)
              : null,
          icon: Icon(
            Icons.remove,
            color: Theme.of(context).colorScheme.onPrimary,
          ),
          style: IconButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(width: 4),
        IconButton.filledTonal(
          onPressed: () => setState(() => _guestCount++),
          icon: Icon(Icons.add, color: Theme.of(context).colorScheme.onPrimary),
          style: IconButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusField() {
    return Builder(
      builder: (ctx) => DropdownButtonFormField<BookingStatus>(
        initialValue: _status,
        dropdownColor: InputDecorationHelper.getDropdownColor(ctx),
        borderRadius: InputDecorationHelper.dropdownBorderRadius,
        decoration: InputDecorationHelper.buildDecoration(
          labelText: 'Status',
          prefixIcon: const Icon(Icons.info_outline),
          context: ctx,
        ),
        items: BookingStatus.values.map((status) {
          return DropdownMenuItem(
            value: status,
            child: Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: _getStatusColor(status),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(status.displayNameLocalized(context)),
              ],
            ),
          );
        }).toList(),
        onChanged: (value) {
          if (value != null) {
            setState(() => _status = value);
          }
        },
      ),
    );
  }

  Widget _buildNotesField() {
    final l10n = AppLocalizations.of(context);
    return Builder(
      builder: (ctx) => TextField(
        controller: _notesController,
        decoration: InputDecorationHelper.buildDecoration(
          labelText: l10n.bookingEditInternalNotes,
          hintText: l10n.bookingEditNotesHint,
          prefixIcon: const Icon(Icons.notes),
          context: ctx,
        ),
        maxLines: 3,
        textCapitalization: TextCapitalization.sentences,
      ),
    );
  }

  Future<void> _selectDate(
    BuildContext context, {
    required bool isCheckIn,
  }) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isCheckIn ? _checkIn : _checkOut,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );

    if (picked != null) {
      setState(() {
        if (isCheckIn) {
          _checkIn = picked;
          // Ensure check-out is after check-in
          if (_checkOut.isBefore(_checkIn)) {
            _checkOut = _checkIn.add(const Duration(days: 1));
          }
        } else {
          _checkOut = picked;
          // Ensure check-in is before check-out
          if (_checkIn.isAfter(_checkOut)) {
            _checkIn = _checkOut.subtract(const Duration(days: 1));
          }
        }
      });
    }
  }

  Future<void> _saveChanges() async {
    final l10n = AppLocalizations.of(context);
    setState(() => _isSaving = true);

    try {
      // Validate for overlaps before saving
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
        setState(() => _isSaving = false);

        if (mounted) {
          // Show detailed error with conflicting booking info
          final conflict = conflicts.first;
          final conflictGuestName = conflict.guestName ?? 'Unknown';
          final conflictCheckIn =
              '${conflict.checkIn.day}.${conflict.checkIn.month}.${conflict.checkIn.year}';
          final conflictCheckOut =
              '${conflict.checkOut.day}.${conflict.checkOut.month}.${conflict.checkOut.year}';

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
      final datesChanged =
          _checkIn != widget.booking.checkIn ||
          _checkOut != widget.booking.checkOut;

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
            setState(() => _isSaving = false);
            return;
          }
        }
      }

      // Check if check-out date changed (for token expiration update)
      final checkOutChanged = _checkOut != widget.booking.checkOut;

      // FIX: Use direct Firestore transaction instead of repository
      // This avoids the slow fetchBookingById which searches ALL bookings
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
          throw Exception(
            'Booking no longer exists. It may have been deleted.',
          );
        }

        transaction.update(docRef, {
          'check_in': Timestamp.fromDate(_checkIn),
          'check_out': Timestamp.fromDate(_checkOut),
          'guest_count': _guestCount,
          'status': _status.name,
          'notes': _notesController.text.trim().isEmpty
              ? null
              : _notesController.text.trim(),
          'updated_at': Timestamp.fromDate(DateTime.now()),
        });
      });

      // If check-out date changed, update token expiration
      if (checkOutChanged) {
        try {
          final functions = ref.read(firebaseFunctionsProvider);
          final callable = functions.httpsCallable(
            'updateBookingTokenExpiration',
          );
          await callable
              .call({'bookingId': widget.booking.id})
              .withCloudFunctionTimeout('updateBookingTokenExpiration');
        } catch (e) {
          // Log error but don't block booking update
          LoggingService.logWarning('Failed to update token expiration: $e');
        }
      }

      // Refresh calendar
      ref.invalidate(calendarBookingsProvider);

      if (mounted) {
        Navigator.of(context).pop(true); // Return true to indicate success
        ErrorDisplayUtils.showSuccessSnackBar(context, l10n.editBookingSuccess);
      }
    } catch (e) {
      if (mounted) {
        ErrorDisplayUtils.showErrorSnackBar(
          context,
          e,
          userMessage: l10n.editBookingError,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Color _getStatusColor(BookingStatus status) {
    // Use the color defined in the status enum
    return status.color;
  }
}

/// Section header widget with icon and gradient accent
class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            gradient: context.gradients.brandPrimary,
            borderRadius: const BorderRadius.all(Radius.circular(8)),
          ),
          child: Icon(icon, color: Colors.white, size: 16),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
