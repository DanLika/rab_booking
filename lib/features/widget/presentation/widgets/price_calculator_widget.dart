import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../domain/models/booking_price_breakdown.dart';
import '../providers/price_calculator_provider.dart';

class PriceCalculatorWidget extends ConsumerWidget {
  final String unitId;
  final DateTime? checkIn;
  final DateTime? checkOut;

  const PriceCalculatorWidget({
    super.key,
    required this.unitId,
    this.checkIn,
    this.checkOut,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final priceBreakdown = ref.watch(bookingPriceProvider((unitId, checkIn, checkOut)));

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.2),
            spreadRadius: 2,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(Icons.calculate, color: Colors.blue[700]),
              const SizedBox(width: 8),
              const Text(
                'Price Breakdown',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          priceBreakdown.when(
            data: (breakdown) {
              if (breakdown == null) {
                return _buildEmptyState();
              }
              return _buildPriceDetails(breakdown);
            },
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: CircularProgressIndicator(),
              ),
            ),
            error: (error, stack) => Center(
              child: Text(
                'Error calculating price: $error',
                style: const TextStyle(color: Colors.red),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 24.0),
      child: Center(
        child: Text(
          'Select check-in and check-out dates to see price',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildPriceDetails(BookingPriceBreakdown breakdown) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Date range summary
        _buildDateRangeSummary(breakdown),
        const SizedBox(height: 16),
        const Divider(),
        const SizedBox(height: 8),

        // Nightly breakdown
        const Text(
          'Nightly Breakdown',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        ...breakdown.nightlyPrices.map<Widget>((nightlyPrice) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  DateFormat('MMM dd, yyyy').format(nightlyPrice.date),
                  style: const TextStyle(fontSize: 13),
                ),
                Text(
                  nightlyPrice.formattedPrice,
                  style: const TextStyle(fontSize: 13),
                ),
              ],
            ),
          );
        }),

        const SizedBox(height: 16),
        const Divider(),
        const SizedBox(height: 8),

        // Total
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Total',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              breakdown.formattedTotal,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.green[700],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDateRangeSummary(BookingPriceBreakdown breakdown) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.login, size: 16, color: Colors.blue[700]),
              const SizedBox(width: 4),
              Text(
                'Check-in: ${DateFormat('MMM dd, yyyy').format(breakdown.checkIn!)}',
                style: const TextStyle(fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.logout, size: 16, color: Colors.blue[700]),
              const SizedBox(width: 4),
              Text(
                'Check-out: ${DateFormat('MMM dd, yyyy').format(breakdown.checkOut!)}',
                style: const TextStyle(fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${breakdown.numberOfNights} night${breakdown.numberOfNights != 1 ? 's' : ''}',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.blue[900],
            ),
          ),
        ],
      ),
    );
  }
}
