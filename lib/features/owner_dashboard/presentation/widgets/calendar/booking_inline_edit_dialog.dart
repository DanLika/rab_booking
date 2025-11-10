import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:auto_size_text/auto_size_text.dart';
import '../../../../../shared/models/booking_model.dart';
import '../../../../../shared/providers/repository_providers.dart';
import '../../../../../core/constants/enums.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../providers/owner_calendar_provider.dart';
import '../../../utils/calendar_grid_calculator.dart';
import '../../../utils/booking_overlap_detector.dart';

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
    final isMobile =
        MediaQuery.of(context).size.width <
        CalendarGridCalculator.mobileBreakpoint;

    return Dialog(
      child: Container(
        width: isMobile ? double.infinity : 500,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.primaryColor,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(4),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.edit, color: theme.colorScheme.onPrimary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AutoSizeText(
                      'Quick Edit Booking',
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: theme.colorScheme.onPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      minFontSize: 14,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: theme.colorScheme.onPrimary),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Guest name (read-only)
                    _buildInfoRow(
                      'Guest',
                      widget.booking.guestName ?? 'N/A',
                      Icons.person,
                    ),
                    const SizedBox(height: 16),

                    // Check-in date
                    _buildDateField(
                      label: 'Check-in',
                      date: _checkIn,
                      onTap: () => _selectDate(context, isCheckIn: true),
                    ),
                    const SizedBox(height: 16),

                    // Check-out date
                    _buildDateField(
                      label: 'Check-out',
                      date: _checkOut,
                      onTap: () => _selectDate(context, isCheckIn: false),
                    ),
                    const SizedBox(height: 16),

                    // Nights (calculated)
                    _buildInfoRow(
                      'Nights',
                      '${_checkOut.difference(_checkIn).inDays}',
                      Icons.nightlight_round,
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
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: theme.dividerColor)),
              ),
              child: isMobile
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Save button (full width on mobile)
                        ElevatedButton.icon(
                          onPressed: _isSaving ? null : _saveChanges,
                          icon: _isSaving
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.save),
                          label: AutoSizeText(
                            _isSaving ? 'Saving...' : 'Save Changes',
                            maxLines: 1,
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Cancel button (full width on mobile)
                        TextButton(
                          onPressed: _isSaving
                              ? null
                              : () => Navigator.of(context).pop(),
                          child: const AutoSizeText(
                            'Cancel',
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
                            child: const AutoSizeText(
                              'Cancel',
                              maxLines: 1,
                              minFontSize: 11,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: ElevatedButton.icon(
                            onPressed: _isSaving ? null : _saveChanges,
                            icon: _isSaving
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.save),
                            label: AutoSizeText(
                              _isSaving ? 'Saving...' : 'Save Changes',
                              maxLines: 1,
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
          ],
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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          suffixIcon: const Icon(Icons.calendar_today),
        ),
        child: Text(
          '${date.day}/${date.month}/${date.year}',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      ),
    );
  }

  Widget _buildGuestCountField() {
    return Row(
      children: [
        Expanded(
          child: InputDecorator(
            decoration: const InputDecoration(
              labelText: 'Number of Guests',
              border: OutlineInputBorder(),
            ),
            child: Text(
              '$_guestCount',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
        ),
        const SizedBox(width: 8),
        IconButton.filledTonal(
          onPressed: _guestCount > 1
              ? () => setState(() => _guestCount--)
              : null,
          icon: const Icon(Icons.remove),
        ),
        const SizedBox(width: 4),
        IconButton.filledTonal(
          onPressed: () => setState(() => _guestCount++),
          icon: const Icon(Icons.add),
        ),
      ],
    );
  }

  Widget _buildStatusField() {
    return DropdownButtonFormField<BookingStatus>(
      initialValue: _status,
      decoration: const InputDecoration(
        labelText: 'Status',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.info_outline),
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
              Text(status.displayName),
            ],
          ),
        );
      }).toList(),
      onChanged: (value) {
        if (value != null) {
          setState(() => _status = value);
        }
      },
    );
  }

  Widget _buildNotesField() {
    return TextField(
      controller: _notesController,
      decoration: const InputDecoration(
        labelText: 'Internal Notes',
        border: OutlineInputBorder(),
        hintText: 'Add notes for this booking...',
        prefixIcon: Icon(Icons.notes),
      ),
      maxLines: 3,
      textCapitalization: TextCapitalization.sentences,
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
    setState(() => _isSaving = true);

    try {
      // FIXED: Validate for overlaps before saving
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

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                conflicts.length == 1
                    ? 'Overlap detected with booking for $conflictGuestName ($conflictCheckIn - $conflictCheckOut)'
                    : 'Overlap detected with ${conflicts.length} existing bookings',
              ),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 5),
            ),
          );
        }
        return;
      }

      final repository = ref.read(bookingRepositoryProvider);

      // Create updated booking
      final updatedBooking = widget.booking.copyWith(
        checkIn: _checkIn,
        checkOut: _checkOut,
        guestCount: _guestCount,
        status: _status,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        updatedAt: DateTime.now(),
      );

      // Save to Firestore
      await repository.updateBooking(updatedBooking);

      // Refresh calendar
      ref.invalidate(calendarBookingsProvider);

      if (mounted) {
        Navigator.of(context).pop(true); // Return true to indicate success

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Booking updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() => _isSaving = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update booking: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Color _getStatusColor(BookingStatus status) {
    switch (status) {
      case BookingStatus.pending:
        return Colors.orange.shade400;
      case BookingStatus.confirmed:
        return Colors.green.shade400;
      case BookingStatus.checkedIn:
        return Colors.purple.shade400;
      case BookingStatus.checkedOut:
        return AppColors.authSecondary.withAlpha((0.5 * 255).toInt());
      case BookingStatus.inProgress:
        return AppColors.authSecondary.withAlpha((0.7 * 255).toInt());
      case BookingStatus.completed:
        return Colors.grey.shade400;
      case BookingStatus.cancelled:
        return Colors.red.shade400;
      case BookingStatus.blocked:
        return Colors.grey.shade600;
    }
  }
}
