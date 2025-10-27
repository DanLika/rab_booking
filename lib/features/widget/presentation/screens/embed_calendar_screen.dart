import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/year_grid_calendar_widget.dart';
import '../providers/embed_booking_provider.dart';

/// Embedded calendar screen - public view for guests
/// URL: /embed/units/:unitId
class EmbedCalendarScreen extends ConsumerStatefulWidget {
  final String unitId;

  const EmbedCalendarScreen({
    super.key,
    required this.unitId,
  });

  @override
  ConsumerState<EmbedCalendarScreen> createState() =>
      _EmbedCalendarScreenState();
}

class _EmbedCalendarScreenState extends ConsumerState<EmbedCalendarScreen> {
  DateTime? _selectedCheckIn;
  DateTime? _selectedCheckOut;

  @override
  Widget build(BuildContext context) {
    final bookingState = ref.watch(embedBookingProvider(widget.unitId));

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Book Your Stay'),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black87,
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Year Grid Calendar (31 days × 12 months)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: YearGridCalendarWidget(
                  unitId: widget.unitId,
                  onRangeSelected: (start, end) {
                    setState(() {
                      _selectedCheckIn = start;
                      _selectedCheckOut = end;
                    });
                  },
                ),
              ),
            ),

            // Selection Summary
            if (_selectedCheckIn != null && _selectedCheckOut != null)
              _buildSelectionSummary(),

            // Reserve Button
            if (_selectedCheckIn != null && _selectedCheckOut != null)
              _buildReserveButton(),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectionSummary() {
    final bookingState = ref.watch(embedBookingProvider(widget.unitId));
    final nights = _selectedCheckOut!.difference(_selectedCheckIn!).inDays;

    // Calculate total price from provider
    double totalPrice = 0.0;
    DateTime current = _selectedCheckIn!;
    while (current.isBefore(_selectedCheckOut!)) {
      final price = ref
          .read(embedBookingProvider(widget.unitId).notifier)
          .getPriceForDate(current);
      if (price != null) {
        totalPrice += price;
      }
      current = current.add(const Duration(days: 1));
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your Selection',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'CHECK-IN',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_selectedCheckIn!.day}/${_selectedCheckIn!.month}/${_selectedCheckIn!.year}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ],
              ),
              Icon(Icons.arrow_forward, color: Colors.grey[600]),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'CHECK-OUT',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_selectedCheckOut!.day}/${_selectedCheckOut!.month}/${_selectedCheckOut!.year}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ],
              ),
            ],
          ),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$nights ${nights == 1 ? 'night' : 'nights'}',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              Text(
                '€${totalPrice.toStringAsFixed(2)}',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[700],
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReserveButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ElevatedButton(
        onPressed: () {
          // TODO: Navigate to guest info form
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Guest information form will be implemented next'),
              duration: Duration(seconds: 2),
            ),
          );
        },
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          backgroundColor: Colors.blue[700],
          foregroundColor: Colors.white,
        ),
        child: const Text(
          'Continue to Guest Information',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
