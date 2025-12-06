import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/design_tokens/gradient_tokens.dart';
import '../../../../shared/models/booking_model.dart';
import '../../../../core/constants/breakpoints.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/input_decoration_helper.dart';
import '../../../../shared/providers/repository_providers.dart';
import '../../../../core/utils/error_display_utils.dart';

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
    final nights = _checkOut.difference(_checkIn).inDays;
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isMobile = Breakpoints.isMobile(context);

    return AlertDialog(
      title: Text(l10n.editBookingTitle, style: const TextStyle(color: Colors.white)),
      content: Container(
        width: isMobile ? screenWidth * 0.9 : 500,
        constraints: BoxConstraints(maxHeight: screenHeight * 0.8),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Booking Info
              Text(
                l10n.editBookingBookingId(widget.booking.id),
                style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 12),
              ),
              Text(
                l10n.editBookingGuest(widget.booking.guestName ?? ''),
                style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 24),

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
                  color: AppColors.authSecondary.withAlpha((0.1 * 255).toInt()),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  l10n.editBookingNights(nights),
                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.authSecondary),
                ),
              ),
              const SizedBox(height: 16),

              // Guest Count
              ListTile(
                leading: const Icon(Icons.people),
                title: Text(l10n.editBookingGuests),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Minus button
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: _guestCount > 1
                            ? (Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black)
                            : Colors.grey[400],
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        icon: Icon(
                          Icons.remove,
                          size: 16,
                          color: _guestCount > 1
                              ? (Theme.of(context).brightness == Brightness.dark ? Colors.black : Colors.white)
                              : Colors.grey[600],
                        ),
                        onPressed: _guestCount > 1 ? () => setState(() => _guestCount--) : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(_guestCount.toString(), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(width: 12),
                    // Plus button
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        icon: Icon(
                          Icons.add,
                          size: 16,
                          color: Theme.of(context).brightness == Brightness.dark ? Colors.black : Colors.white,
                        ),
                        onPressed: () => setState(() => _guestCount++),
                      ),
                    ),
                  ],
                ),
                contentPadding: EdgeInsets.zero,
              ),

              // Notes
              const SizedBox(height: 16),
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
      actions: [
        TextButton(onPressed: _isLoading ? null : () => Navigator.of(context).pop(), child: Text(l10n.cancel)),
        Container(
          decoration: const BoxDecoration(
            gradient: GradientTokens.brandPrimary,
            borderRadius: BorderRadius.all(Radius.circular(4)),
          ),
          child: ElevatedButton(
            onPressed: _isLoading ? null : _saveChanges,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              foregroundColor: Colors.white,
              shadowColor: Colors.transparent,
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Text(l10n.editBookingSaveChanges),
          ),
        ),
      ],
    );
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
      // Update booking in Firestore
      final firestore = ref.read(firestoreProvider);
      await firestore.collection('bookings').doc(widget.booking.id).update({
        'check_in': _checkIn.toUtc().toIso8601String(),
        'check_out': _checkOut.toUtc().toIso8601String(),
        'guest_count': _guestCount,
        'notes': _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      });

      if (mounted) {
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
