import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../domain/models/property_unit.dart';
import '../providers/property_details_provider.dart';
import '../../../booking/presentation/widgets/booking_calendar_widget.dart';

/// Booking widget with calendar and price calculation
class BookingWidget extends ConsumerStatefulWidget {
  const BookingWidget({
    required this.unit,
    super.key,
  });

  final PropertyUnit unit;

  @override
  ConsumerState<BookingWidget> createState() => _BookingWidgetState();
}

class _BookingWidgetState extends ConsumerState<BookingWidget> {
  bool _isCalendarExpanded = false;
  DateTime _focusedDay = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final selectedDates = ref.watch(selectedDatesNotifierProvider);
    final selectedGuests = ref.watch(selectedGuestsNotifierProvider);
    final bookingCalcAsync = selectedDates.hasCompleteDates
        ? ref.watch(bookingCalculationProvider(widget.unit.id))
        : null;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey[300]!,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Price header
          _buildPriceHeader(),

          const SizedBox(height: 24),

          // Date selection
          _buildDateSelector(selectedDates),

          if (_isCalendarExpanded)
            Container(
              margin: const EdgeInsets.only(top: 16),
              child: BookingCalendarWidget(
                unitId: widget.unit.id,
                minStayNights: widget.unit.minStayNights,
                onDatesSelected: (checkIn, checkOut) {
                  if (checkIn != null && checkOut != null) {
                    ref
                        .read(selectedDatesNotifierProvider.notifier)
                        .setDates(checkIn, checkOut);
                  } else if (checkIn != null) {
                    ref
                        .read(selectedDatesNotifierProvider.notifier)
                        .setCheckIn(checkIn);
                  }
                },
              ),
            ),

          const SizedBox(height: 16),

          // Guests selector
          _buildGuestsSelector(selectedGuests),

          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 16),

          // Price breakdown
          if (bookingCalcAsync != null)
            bookingCalcAsync.when(
              data: (calc) => calc != null
                  ? _buildPriceBreakdown(calc)
                  : const SizedBox.shrink(),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Text('Greška: $error'),
            ),

          const SizedBox(height: 24),

          // Book button
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: selectedDates.hasCompleteDates
                  ? () => _handleBooking(context)
                  : null,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('Rezerviraj'),
            ),
          ),

          const SizedBox(height: 12),

          // Info text
          Text(
            'Neće te biti naplaćeni sada',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPriceHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '€${widget.unit.pricePerNight.toStringAsFixed(0)}',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(width: 4),
        Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(
            '/ noć',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
        ),
      ],
    );
  }

  Widget _buildDateSelector(SelectedDates selectedDates) {
    final dateFormat = DateFormat('dd.MM.yyyy');

    return InkWell(
      onTap: () {
        setState(() {
          _isCalendarExpanded = !_isCalendarExpanded;
        });
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Check-in',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    selectedDates.checkIn != null
                        ? dateFormat.format(selectedDates.checkIn!)
                        : 'Dodaj datum',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            Container(
              width: 1,
              height: 40,
              color: Colors.grey[300],
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(left: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Check-out',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      selectedDates.checkOut != null
                          ? dateFormat.format(selectedDates.checkOut!)
                          : 'Dodaj datum',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ),
            Icon(
              _isCalendarExpanded
                  ? Icons.keyboard_arrow_up
                  : Icons.keyboard_arrow_down,
              color: Colors.grey[600],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGuestsSelector(int selectedGuests) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Gosti',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$selectedGuests ${selectedGuests == 1 ? 'gost' : 'gostiju'}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          Row(
            children: [
              IconButton(
                onPressed: selectedGuests > 1
                    ? () => ref.read(selectedGuestsNotifierProvider.notifier).decrement()
                    : null,
                icon: const Icon(Icons.remove_circle_outline),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: selectedGuests < widget.unit.maxGuests
                    ? () => ref.read(selectedGuestsNotifierProvider.notifier).increment()
                    : null,
                icon: const Icon(Icons.add_circle_outline),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPriceBreakdown(Map<String, dynamic> calc) {
    return Column(
      children: [
        _PriceRow(
          label: '€${calc['price_per_night']} × ${calc['nights']} noći',
          amount: calc['subtotal'],
        ),
        const SizedBox(height: 8),
        _PriceRow(
          label: 'Naknada za uslugu',
          amount: calc['service_fee'],
        ),
        const SizedBox(height: 8),
        _PriceRow(
          label: 'Naknada za čišćenje',
          amount: calc['cleaning_fee'],
        ),
        const SizedBox(height: 16),
        const Divider(),
        const SizedBox(height: 16),
        _PriceRow(
          label: 'Ukupno',
          amount: calc['total'],
          isBold: true,
        ),
      ],
    );
  }

  void _handleBooking(BuildContext context) {
    // TODO: Navigate to booking confirmation screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Nastavak na potvrdu rezervacije...'),
      ),
    );
  }
}

class _PriceRow extends StatelessWidget {
  const _PriceRow({
    required this.label,
    required this.amount,
    this.isBold = false,
  });

  final String label;
  final dynamic amount;
  final bool isBold;

  @override
  Widget build(BuildContext context) {
    final amountText = amount is double
        ? '€${amount.toStringAsFixed(2)}'
        : '€$amount';

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              ),
        ),
        Text(
          amountText,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              ),
        ),
      ],
    );
  }
}
