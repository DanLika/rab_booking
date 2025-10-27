import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/calendar_view_switcher.dart';
import '../providers/booking_price_provider.dart';
import 'bank_transfer_screen.dart';

/// Main booking widget screen that shows responsive calendar
/// Automatically switches between year/month/week views based on screen size
class BookingWidgetScreen extends ConsumerStatefulWidget {
  const BookingWidgetScreen({super.key});

  @override
  ConsumerState<BookingWidgetScreen> createState() => _BookingWidgetScreenState();
}

class _BookingWidgetScreenState extends ConsumerState<BookingWidgetScreen> {
  DateTime? _checkIn;
  DateTime? _checkOut;
  late String _unitId;

  @override
  void initState() {
    super.initState();
    // Parse unit ID from URL
    final uri = Uri.base;
    _unitId = uri.queryParameters['unit'] ?? '';
  }

  @override
  Widget build(BuildContext context) {
    final unitId = _unitId;

    if (unitId.isEmpty) {
      return const Scaffold(
        body: Center(
          child: Text('Missing unit parameter in URL'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final screenWidth = constraints.maxWidth;
          final forceMonthView = screenWidth < 1024; // Year view only on desktop

          return Column(
            children: [
              // Calendar with view switcher
              Expanded(
                child: CalendarViewSwitcher(
                  unitId: unitId,
                  forceMonthView: forceMonthView,
                  onRangeSelected: (start, end) {
                    setState(() {
                      _checkIn = start;
                      _checkOut = end;
                    });
                  },
                ),
              ),

              // Booking summary bar (shown when dates selected)
              if (_checkIn != null && _checkOut != null)
                _buildBookingSummaryBar(unitId),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBookingSummaryBar(String unitId) {
    // Watch price calculation
    final priceCalc = ref.watch(bookingPriceProvider(
      unitId: unitId,
      checkIn: _checkIn,
      checkOut: _checkOut,
    ));

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
        child: priceCalc.when(
          data: (calculation) {
            if (calculation == null) {
              return const Center(child: Text('Select dates'));
            }

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Price breakdown
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${calculation.nights} ${calculation.nights == 1 ? 'night' : 'nights'}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          '${_checkIn!.day}/${_checkIn!.month} - ${_checkOut!.day}/${_checkOut!.month}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          calculation.formattedTotal,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF6B8E23),
                          ),
                        ),
                        Text(
                          'Total',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Deposit info
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '20% Deposit (Avans)',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Pay now',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        calculation.formattedDeposit,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 8),

                // Remaining amount info
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Remaining (Pay on arrival)',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    Text(
                      calculation.formattedRemaining,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Reserve button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => _handleReserve(context, calculation),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6B8E23),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Reserve',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: CircularProgressIndicator(),
            ),
          ),
          error: (error, stack) => Center(
            child: Text(
              'Error calculating price',
              style: TextStyle(color: Colors.red.shade700),
            ),
          ),
        ),
      ),
    );
  }

  void _handleReserve(BuildContext context, BookingPriceCalculation calculation) {
    // Generate booking reference
    final reference = _generateBookingReference();

    // TODO: Call Cloud Function to create pending booking
    // For now, just navigate to bank transfer screen

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => BankTransferScreen(
          unitId: _unitId,
          checkIn: _checkIn!,
          checkOut: _checkOut!,
          bookingReference: reference,
        ),
      ),
    );
  }

  String _generateBookingReference() {
    // Generate simple booking reference (e.g., "BK-20251118-XXXX")
    final date = DateTime.now();
    final dateStr = '${date.year}${date.month.toString().padLeft(2, '0')}${date.day.toString().padLeft(2, '0')}';
    final random = (date.millisecond * 1000 + date.second).toString().padLeft(4, '0');
    return 'BK-$dateStr-$random';
  }
}
