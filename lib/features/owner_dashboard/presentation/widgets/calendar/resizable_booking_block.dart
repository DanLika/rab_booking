import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../shared/models/booking_model.dart';
import '../../providers/booking_resize_provider.dart';
import '../../providers/owner_calendar_provider.dart';
import '../../../../../shared/providers/repository_providers.dart';
import 'booking_block_widget.dart';

/// Resizable Booking Block Wrapper
/// Wraps BookingBlockWidget with resize functionality
class ResizableBookingBlock extends ConsumerWidget {
  final BookingModel booking;
  final double width;
  final double height;
  final double dayCellWidth; // Width of one day cell for calculation
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final void Function(TapDownDetails)? onSecondaryTapDown;
  final bool isDraggable;
  final bool showGuestName;
  final bool showCheckInOut;
  final bool hasConflict;
  final bool enableResize;

  const ResizableBookingBlock({
    super.key,
    required this.booking,
    required this.width,
    required this.height,
    required this.dayCellWidth,
    this.onTap,
    this.onLongPress,
    this.onSecondaryTapDown,
    this.isDraggable = true,
    this.showGuestName = true,
    this.showCheckInOut = true,
    this.hasConflict = false,
    this.enableResize = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resizeState = ref.watch(bookingResizeProvider);
    final isCurrentlyResizing =
        resizeState.isResizing && resizeState.bookingBeingResized?.id == booking.id;

    return BookingBlockWidget(
      booking: booking,
      width: width,
      height: height,
      onTap: onTap,
      onLongPress: onLongPress,
      onSecondaryTapDown: onSecondaryTapDown,
      isDraggable: isDraggable && !isCurrentlyResizing, // Disable drag during resize
      showGuestName: showGuestName,
      showCheckInOut: showCheckInOut,
      hasConflict: hasConflict,
      isResizable: enableResize,
      isResizing: isCurrentlyResizing,
      onResizeStartLeft: (details) => _handleResizeStartLeft(ref, details),
      onResizeUpdateLeft: (details) => _handleResizeUpdateLeft(ref, details),
      onResizeEndLeft: (details) => _handleResizeEnd(context, ref, details),
      onResizeStartRight: (details) => _handleResizeStartRight(ref, details),
      onResizeUpdateRight: (details) => _handleResizeUpdateRight(ref, details),
      onResizeEndRight: (details) => _handleResizeEnd(context, ref, details),
    );
  }

  /// Handle resize start (left edge - check-in date)
  void _handleResizeStartLeft(WidgetRef ref, DragStartDetails details) {
    ref.read(bookingResizeProvider.notifier).startResize(
          booking,
          ResizeMode.resizingStart,
        );
  }

  /// Handle resize start (right edge - check-out date)
  void _handleResizeStartRight(WidgetRef ref, DragStartDetails details) {
    ref.read(bookingResizeProvider.notifier).startResize(
          booking,
          ResizeMode.resizingEnd,
        );
  }

  /// Handle resize update (left edge - check-in date)
  void _handleResizeUpdateLeft(WidgetRef ref, DragUpdateDetails details) {
    final resizeState = ref.read(bookingResizeProvider);
    if (!resizeState.isResizing) return;

    // Calculate how many days to shift based on drag distance
    final dragDistance = details.globalPosition.dx - details.localPosition.dx;
    final daysDelta = (dragDistance / dayCellWidth).round();

    // Calculate new check-in date
    final originalCheckIn = resizeState.originalCheckIn!;
    final newCheckIn = originalCheckIn.add(Duration(days: daysDelta));

    // Update preview
    ref.read(bookingResizeProvider.notifier).updatePreview(
          checkIn: newCheckIn,
        );
  }

  /// Handle resize update (right edge - check-out date)
  void _handleResizeUpdateRight(WidgetRef ref, DragUpdateDetails details) {
    final resizeState = ref.read(bookingResizeProvider);
    if (!resizeState.isResizing) return;

    // Calculate how many days to shift based on drag distance
    final dragDistance = details.globalPosition.dx - details.localPosition.dx;
    final daysDelta = (dragDistance / dayCellWidth).round();

    // Calculate new check-out date
    final originalCheckOut = resizeState.originalCheckOut!;
    final newCheckOut = originalCheckOut.add(Duration(days: daysDelta));

    // Update preview
    ref.read(bookingResizeProvider.notifier).updatePreview(
          checkOut: newCheckOut,
        );
  }

  /// Handle resize end - save changes if valid
  void _handleResizeEnd(BuildContext context, WidgetRef ref, DragEndDetails details) {
    final resizeState = ref.read(bookingResizeProvider);

    if (!resizeState.isResizing) return;

    // If valid, trigger save (will be handled asynchronously)
    if (resizeState.isValid) {
      // Schedule the async operation after the current frame
      WidgetsBinding.instance.addPostFrameCallback((_) {
        unawaited(_saveResizeChanges(context, ref));
      });
    } else {
      // Invalid resize, cancel
      ref.read(bookingResizeProvider.notifier).cancelResize();
    }
  }

  /// Save resize changes to database
  Future<void> _saveResizeChanges(BuildContext context, WidgetRef ref) async {
    if (!context.mounted) return;

    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final updatedBooking = ref.read(bookingResizeProvider.notifier).getUpdatedBooking();

    if (updatedBooking == null) {
      ref.read(bookingResizeProvider.notifier).cancelResize();
      return;
    }

    try {
      // Show loading dialog
      unawaited(
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(
            child: Card(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Spremanje promjena...'),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

      // Update booking in database
      final repository = ref.read(bookingRepositoryProvider);
      await repository.updateBooking(updatedBooking);

      // Refresh calendar data
      await Future.wait([
        ref.refresh(calendarBookingsProvider.future),
        ref.refresh(allOwnerUnitsProvider.future),
      ]);

      // Close loading dialog
      if (context.mounted) {
        navigator.pop();
      }

      // Show success message
      if (context.mounted) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Rezervacija promijenjena'),
            backgroundColor: Colors.green,
          ),
        );
      }

      // Clear resize state
      ref.read(bookingResizeProvider.notifier).clearState();
    } catch (e) {
      // Close loading dialog
      if (context.mounted) {
        navigator.pop();
      }

      // Show error
      if (context.mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text('Greška: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }

      // Cancel resize
      ref.read(bookingResizeProvider.notifier).cancelResize();
    }
  }
}
