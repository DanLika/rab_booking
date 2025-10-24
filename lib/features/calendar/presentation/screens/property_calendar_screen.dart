import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/booking_calendar.dart';
import '../providers/calendar_provider.dart';
import 'package:go_router/go_router.dart';

/// Screen showing calendar for a specific property unit
/// Guest can view availability and select check-in/check-out dates
class PropertyCalendarScreen extends ConsumerWidget {
  final String unitId;
  final String? propertyName;
  final String? unitName;

  const PropertyCalendarScreen({
    super.key,
    required this.unitId,
    this.propertyName,
    this.unitName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedRange = ref.watch(selectedDateRangeProvider);
    final calendarSettings = ref.watch(calendarSettingsNotifierProvider(unitId));

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(propertyName ?? 'Property Calendar'),
            if (unitName != null)
              Text(
                unitName!,
                style: Theme.of(context).textTheme.bodySmall,
              ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Calendar settings info
          calendarSettings.when(
            data: (settings) {
              if (settings == null) return const SizedBox.shrink();

              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                color: Colors.blue[50],
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Check-in: ${settings.checkInTime}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    Text(
                      'Check-out: ${settings.checkOutTime}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    if (settings.minNights > 1)
                      Text(
                        'Minimum stay: ${settings.minNights} nights',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                  ],
                ),
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),

          // Calendar
          Expanded(
            child: SingleChildScrollView(
              child: BookingCalendar(
                unitId: unitId,
                allowSelection: true,
                showLegend: true,
                onDateRangeSelected: (checkIn, checkOut) {
                  // Optional: Show snackbar or trigger validation
                  if (checkIn != null && checkOut != null) {
                    _checkAvailability(context, ref, checkIn, checkOut);
                  }
                },
              ),
            ),
          ),

          // Bottom action button
          if (selectedRange.checkIn != null && selectedRange.checkOut != null)
            _buildBottomBar(context, ref, selectedRange),
        ],
      ),
    );
  }

  Widget _buildBottomBar(
    BuildContext context,
    WidgetRef ref,
    ({DateTime? checkIn, DateTime? checkOut}) selectedRange,
  ) {
    final nights = selectedRange.checkOut!.difference(selectedRange.checkIn!).inDays;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$nights night${nights != 1 ? 's' : ''}',
                    style: Theme.of(context).textTheme.titleMedium!.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  Text(
                    'Selected dates',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            ElevatedButton(
              onPressed: () => _proceedToBooking(context, ref, selectedRange),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
              ),
              child: const Text('Continue to Booking'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _checkAvailability(
    BuildContext context,
    WidgetRef ref,
    DateTime checkIn,
    DateTime checkOut,
  ) async {
    final hasConflict = await ref
        .read(selectedDateRangeProvider.notifier)
        .hasConflict(unitId);

    if (hasConflict && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selected dates are not available'),
          backgroundColor: Colors.red,
        ),
      );

      // Clear selection
      ref.read(selectedDateRangeProvider.notifier).clear();
    }
  }

  void _proceedToBooking(
    BuildContext context,
    WidgetRef ref,
    ({DateTime? checkIn, DateTime? checkOut}) selectedRange,
  ) {
    // Navigate to booking screen with selected dates
    context.push(
      '/booking/$unitId',
      extra: {
        'checkIn': selectedRange.checkIn,
        'checkOut': selectedRange.checkOut,
      },
    );
  }
}
